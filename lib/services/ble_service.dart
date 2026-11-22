import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

enum BleConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  error,
}

class BleDiscoveredDevice {
  final String id;
  final String name;
  final int rssi;
  final BluetoothDevice? device;

  BleDiscoveredDevice({
    required this.id,
    required this.name,
    required this.rssi,
    this.device,
  });
}

class BleService {
  static final BleService instance = BleService._internal();
  BleService._internal();

  BleConnectionState _state = BleConnectionState.disconnected;
  final StreamController<BleConnectionState> _stateController =
      StreamController<BleConnectionState>.broadcast();
  Stream<BleConnectionState> get stateStream => _stateController.stream;
  BleConnectionState get currentState => _state;

  final List<BleDiscoveredDevice> _discoveredDevices = [];
  List<BleDiscoveredDevice> get discoveredDevices => List.unmodifiable(_discoveredDevices);

  final StreamController<List<BleDiscoveredDevice>> _deviceListController =
      StreamController<List<BleDiscoveredDevice>>.broadcast();
  Stream<List<BleDiscoveredDevice>> get deviceListStream => _deviceListController.stream;

  final StreamController<String> _dataStreamController =
      StreamController<String>.broadcast();
  Stream<String> get dataStream => _dataStreamController.stream;

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  StreamSubscription? _scanSubscription;
  StreamSubscription? _notifySubscription;

  // Mock stream timer for testing/simulation
  Timer? _mockTimer;

  void _updateState(BleConnectionState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  Future<bool> requestPermissions() async {
    try {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();

      return statuses.values.every((s) => s.isGranted || s.isLimited);
    } catch (_) {
      return true; // Fallback in environments without full android permissions handler
    }
  }

  Future<void> startScan() async {
    await requestPermissions();
    _discoveredDevices.clear();
    _deviceListController.add(_discoveredDevices);

    _updateState(BleConnectionState.scanning);

    try {
      _scanSubscription?.cancel();
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final name = r.advertisementData.advName.isNotEmpty
              ? r.advertisementData.advName
              : (r.device.platformName.isNotEmpty ? r.device.platformName : 'Unknown BLE Device');
          final id = r.device.remoteId.str;

          final existingIdx = _discoveredDevices.indexWhere((d) => d.id == id);
          final dev = BleDiscoveredDevice(
            id: id,
            name: name,
            rssi: r.rssi,
            device: r.device,
          );

          if (existingIdx >= 0) {
            _discoveredDevices[existingIdx] = dev;
          } else {
            _discoveredDevices.add(dev);
          }
        }
        _deviceListController.add(List.from(_discoveredDevices));
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
    } catch (e) {
      // Add simulated NexLink device if physical scan fails or empty (e.g. on desktop/unsupported hardware)
      _discoveredDevices.add(
        BleDiscoveredDevice(
          id: '8C:DE:52:DF:42:C3',
          name: 'NEXAS NexLink (Mock/Sim)',
          rssi: -58,
        ),
      );
      _deviceListController.add(List.from(_discoveredDevices));
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    _scanSubscription?.cancel();
    if (_state == BleConnectionState.scanning) {
      _updateState(BleConnectionState.disconnected);
    }
  }

  Future<void> connectToDevice(BleDiscoveredDevice target) async {
    await stopScan();
    _updateState(BleConnectionState.connecting);

    if (target.device == null || target.id == '8C:DE:52:DF:42:C3') {
      // Fallback/Simulated connection mode
      await Future.delayed(const Duration(milliseconds: 600));
      _connectedDevice = target.device;
      _updateState(BleConnectionState.connected);
      _startMockDataStream();
      return;
    }

    try {
      _connectedDevice = target.device;
      await _connectedDevice!.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 10),
      );

      final services = await _connectedDevice!.discoverServices();
      for (final service in services) {
        for (final char in service.characteristics) {
          if (char.properties.notify || char.properties.indicate) {
            await char.setNotifyValue(true);
            _notifySubscription = char.lastValueStream.listen((value) {
              final text = utf8.decode(value, allowMalformed: true);
              _dataStreamController.add(text);
            });
          }
          if (char.properties.write || char.properties.writeWithoutResponse) {
            _writeCharacteristic = char;
          }
        }
      }

      _updateState(BleConnectionState.connected);
    } catch (e) {
      _updateState(BleConnectionState.error);
      disconnect();
    }
  }

  Future<void> sendCommand(String cmd) async {
    if (_state != BleConnectionState.connected) return;

    if (_writeCharacteristic != null) {
      try {
        final bytes = utf8.encode('$cmd\r');
        await _writeCharacteristic!.write(bytes, withoutResponse: false);
      } catch (_) {}
    } else {
      _dataStreamController.add('>$cmd\rOK\r');
    }
  }

  void _startMockDataStream() {
    _mockTimer?.cancel();
    int count = 0;
    _mockTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_state != BleConnectionState.connected) {
        timer.cancel();
        return;
      }
      count++;
      final rpmVal = 2000 + ((count * 150) % 7000);
      final rawRpmHex = ((rpmVal * 4).toInt()).toRadixString(16).padLeft(4, '0').toUpperCase();
      final byte0 = rawRpmHex.substring(0, 2);
      final byte1 = rawRpmHex.substring(2, 4);

      final tpsPct = 15.0 + ((count % 40) * 1.5);
      final rawTpsHex = ((tpsPct * 255) / 100).toInt().toRadixString(16).padLeft(2, '0').toUpperCase();

      final can770 = '770 08 $byte0 $byte1 $rawTpsHex 00 00 00 00 00';
      _dataStreamController.add('$can770\r');

      if (count % 3 == 0) {
        final mapKpa = 40 + ((count * 3) % 60);
        final mapHex = mapKpa.toRadixString(16).padLeft(2, '0').toUpperCase();
        _dataStreamController.add('41 0B $mapHex\r');
      }

      if (count % 5 == 0) {
        const ectVal = 82;
        final ectHex = (ectVal + 40).toRadixString(16).padLeft(2, '0').toUpperCase();
        _dataStreamController.add('41 05 $ectHex\r');
      }

      if (count % 7 == 0) {
        final isVva = rpmVal >= 7400;
        _dataStreamController.add('212 04 ${isVva ? "01" : "00"} 00 00 00\r');
      }
    });
  }

  Future<void> disconnect() async {
    _mockTimer?.cancel();
    _mockTimer = null;
    _notifySubscription?.cancel();
    _notifySubscription = null;

    try {
      await _connectedDevice?.disconnect();
    } catch (_) {}
    _connectedDevice = null;
    _writeCharacteristic = null;

    _updateState(BleConnectionState.disconnected);
  }
}
