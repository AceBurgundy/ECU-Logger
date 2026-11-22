// BLE = Bluetooth Low Energy
// RSSI = Received Signal Strength Indicator
// GATT = Generic Attribute Profile
// UUID = Universally Unique Identifier
import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'elm327_protocol.dart';

/// Connection states for the Bluetooth Low Energy service.
enum BleConnectionState {
  /// Adapter is disconnected.
  disconnected,

  /// BLE scan is actively running.
  scanning,

  /// Connection attempt is in progress.
  connecting,

  /// Connected and authenticated with GATT peripheral.
  connected,

  /// Error occurred during scan, connection, or stream.
  error,
}

/// Representation of an OBD-II BLE peripheral discovered during scan.
class BleDiscoveredDevice {
  /// Remote hardware MAC address or peripheral identifier string.
  final String id;

  /// Advertised device name.
  final String name;

  /// Received signal strength in dBm.
  final int rssi;

  /// Underlying FlutterBluePlus BluetoothDevice instance (null in simulation).
  final BluetoothDevice? device;

  /// Creates a [BleDiscoveredDevice] instance.
  BleDiscoveredDevice({
    required this.id,
    required this.name,
    required this.rssi,
    this.device,
  });
}

/// Core Bluetooth Low Energy manager executing scan, connection,
/// ELM327 initialization handshakes, and continuous telemetry polling.
class BleService {
  /// Singleton instance of [BleService].
  static final BleService instance = BleService._internal();
  BleService._internal();

  BleConnectionState _state = BleConnectionState.disconnected;
  final StreamController<BleConnectionState> _stateController =
      StreamController<BleConnectionState>.broadcast();

  /// Stream broadcasting real-time connection state transitions.
  Stream<BleConnectionState> get stateStream => _stateController.stream;

  /// Current synchronous [BleConnectionState].
  BleConnectionState get currentState => _state;

  final List<BleDiscoveredDevice> _discoveredDevices = [];

  /// Immutable list of discovered BLE devices from the current or latest scan.
  List<BleDiscoveredDevice> get discoveredDevices => List.unmodifiable(_discoveredDevices);

  final StreamController<List<BleDiscoveredDevice>> _deviceListController =
      StreamController<List<BleDiscoveredDevice>>.broadcast();

  /// Stream broadcasting updated lists of discovered BLE peripherals.
  Stream<List<BleDiscoveredDevice>> get deviceListStream => _deviceListController.stream;

  final StreamController<String> _dataStreamController =
      StreamController<String>.broadcast();

  /// Stream broadcasting incoming string chunks from the serial UART pipe.
  Stream<String> get dataStream => _dataStreamController.stream;

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  final List<StreamSubscription<List<int>>> _notifySubscriptions = [];
  StreamSubscription<BluetoothConnectionState>? _deviceStateSubscription;

  Timer? _mockTimer;
  Timer? _hardwarePollingTimer;

  void _updateState(BleConnectionState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  /// Requests required runtime permissions for Bluetooth scanning and connectivity.
  Future<bool> requestPermissions() async {
    try {
      final Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
        Permission.storage,
      ].request();

      return statuses.values.every(
        (PermissionStatus status) => status.isGranted || status.isLimited,
      );
    } catch (exception) {
      return true; // Fallback in test/desktop environments without Android handler
    }
  }

  /// Initiates a BLE peripheral scan searching for NexLink / OBD-II adapters.
  Future<void> startScan() async {
    await requestPermissions();
    _discoveredDevices.clear();
    _deviceListController.add(_discoveredDevices);

    _updateState(BleConnectionState.scanning);

    try {
      _scanSubscription?.cancel();
      _scanSubscription = FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
        for (final ScanResult scanResult in results) {
          final String name = scanResult.advertisementData.advName.isNotEmpty
              ? scanResult.advertisementData.advName
              : (scanResult.device.platformName.isNotEmpty
                  ? scanResult.device.platformName
                  : 'Unknown BLE Device');
          final String deviceIdentifier = scanResult.device.remoteId.str;

          final int existingIndex =
              _discoveredDevices.indexWhere((BleDiscoveredDevice item) => item.id == deviceIdentifier);
          final BleDiscoveredDevice discoveredDevice = BleDiscoveredDevice(
            id: deviceIdentifier,
            name: name,
            rssi: scanResult.rssi,
            device: scanResult.device,
          );

          if (existingIndex >= 0) {
            _discoveredDevices[existingIndex] = discoveredDevice;
          } else {
            _discoveredDevices.add(discoveredDevice);
          }
        }
        _deviceListController.add(List<BleDiscoveredDevice>.from(_discoveredDevices));
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
    } catch (exception) {
      // Add simulated NexLink device if physical scan fails (e.g. mock/emulator)
      _discoveredDevices.add(
        BleDiscoveredDevice(
          id: '8C:DE:52:DF:42:C3',
          name: 'NEXAS NexLink (Mock/Sim)',
          rssi: -58,
        ),
      );
      _deviceListController.add(List<BleDiscoveredDevice>.from(_discoveredDevices));
    }
  }

  /// Terminates any active BLE scanning session.
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (exception) {
      // Ignore background stop scan exceptions
    }
    _scanSubscription?.cancel();
    if (_state == BleConnectionState.scanning) {
      _updateState(BleConnectionState.disconnected);
    }
  }

  /// Connects to a target [BleDiscoveredDevice] and negotiates GATT services.
  Future<void> connectToDevice(BleDiscoveredDevice target) async {
    await stopScan();
    _updateState(BleConnectionState.connecting);

    if (target.device == null) {
      // Simulated connection mode when hardware adapter is not physically discovered
      await Future<void>.delayed(const Duration(milliseconds: 600));
      _connectedDevice = null;
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

      // Listen for unexpected hardware disconnection
      _deviceStateSubscription?.cancel();
      _deviceStateSubscription =
          _connectedDevice!.connectionState.listen((BluetoothConnectionState connectionState) {
        if (connectionState == BluetoothConnectionState.disconnected &&
            _state == BleConnectionState.connected) {
          _dataStreamController.add('[SYSTEM] Hardware adapter disconnected.');
          disconnect();
        }
      });

      final List<BluetoothService> services = await _connectedDevice!.discoverServices();
      for (final BluetoothService service in services) {
        for (final BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.properties.notify || characteristic.properties.indicate) {
            await characteristic.setNotifyValue(true);
            final StreamSubscription<List<int>> subscription =
                characteristic.onValueReceived.listen((List<int> value) {
              final String text = utf8.decode(value, allowMalformed: true);
              _dataStreamController.add(text);
            });
            _notifySubscriptions.add(subscription);
          }
          if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
            _writeCharacteristic = characteristic;
          }
        }
      }

      _updateState(BleConnectionState.connected);

      // Execute ELM327 initialization handshake sequence
      await _runElm327InitSequence();

      // Start hardware polling loop for continuous live telemetry
      _startHardwarePollingLoop();
    } catch (exception) {
      _updateState(BleConnectionState.error);
      disconnect();
    }
  }

  Future<void> _runElm327InitSequence() async {
    _dataStreamController.add('[SYSTEM] Starting ELM327 protocol handshake...');
    for (final String command in Elm327Protocol.initCommands) {
      if (_state != BleConnectionState.connected) break;
      await sendCommand(command);
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    _dataStreamController.add('[SYSTEM] ELM327 handshake complete. Protocol locked.');
  }

  void _startHardwarePollingLoop() {
    _hardwarePollingTimer?.cancel();
    int cycle = 0;
    _hardwarePollingTimer =
        Timer.periodic(const Duration(milliseconds: 150), (Timer timer) async {
      if (_state != BleConnectionState.connected || _writeCharacteristic == null) {
        timer.cancel();
        return;
      }
      cycle++;
      try {
        // High frequency: RPM & TPS
        if (cycle % 2 == 1) {
          await sendCommand('010C');
        } else {
          await sendCommand('0111');
        }
        // Medium/Low frequency: MAP & ECT
        if (cycle % 6 == 0) {
          await sendCommand('010B');
        } else if (cycle % 10 == 0) {
          await sendCommand('0105');
        }
      } catch (exception) {
        // Ignore single polling frame timeouts
      }
    });
  }

  /// Sends a raw command string terminated by carriage return over GATT UART.
  Future<void> sendCommand(String command) async {
    if (_state != BleConnectionState.connected) return;

    if (_writeCharacteristic != null) {
      try {
        final List<int> bytes = utf8.encode('$command\r');
        await _writeCharacteristic!.write(bytes, withoutResponse: false);
      } catch (exception) {
        // Ignore write packet drops
      }
    } else {
      _dataStreamController.add('>$command\rOK\r');
    }
  }

  void _startMockDataStream() {
    _mockTimer?.cancel();
    int count = 0;

    // Simulate initial handshake responses
    _dataStreamController.add('>ATZ\rELM327 v1.5\r');
    _dataStreamController.add('>ATE0\rOK\r');
    _dataStreamController.add('>ATL0\rOK\r');
    _dataStreamController.add('>ATH1\rOK\r');
    _dataStreamController.add('>ATSP6\rOK\r');

    _mockTimer = Timer.periodic(const Duration(milliseconds: 100), (Timer timer) {
      if (_state != BleConnectionState.connected) {
        timer.cancel();
        return;
      }
      count++;
      final double rpmValue = 2000.0 + ((count * 150) % 7000);
      final String rawRpmHex =
          ((rpmValue * 4).toInt()).toRadixString(16).padLeft(4, '0').toUpperCase();
      final String byte0 = rawRpmHex.substring(0, 2);
      final String byte1 = rawRpmHex.substring(2, 4);

      final double tpsPercentage = 15.0 + ((count % 40) * 1.5);
      final String rawTpsHex =
          ((tpsPercentage * 255) / 100).toInt().toRadixString(16).padLeft(2, '0').toUpperCase();

      final String can770 = '770 08 $byte0 $byte1 $rawTpsHex 00 00 00 00 00';
      _dataStreamController.add('$can770\r');

      if (count % 3 == 0) {
        final int mapKpa = 40 + ((count * 3) % 60);
        final String mapHex = mapKpa.toRadixString(16).padLeft(2, '0').toUpperCase();
        _dataStreamController.add('41 0B $mapHex\r');
      }

      if (count % 5 == 0) {
        const int ectValue = 82;
        final String ectHex = (ectValue + 40).toRadixString(16).padLeft(2, '0').toUpperCase();
        _dataStreamController.add('41 05 $ectHex\r');
      }

      if (count % 7 == 0) {
        final bool isVva = rpmValue >= 7400;
        _dataStreamController.add('212 04 ${isVva ? "01" : "00"} 00 00 00\r');
      }
    });
  }

  /// Terminates connection, cancels polling timers, and clears stream listeners.
  Future<void> disconnect() async {
    _mockTimer?.cancel();
    _mockTimer = null;
    _hardwarePollingTimer?.cancel();
    _hardwarePollingTimer = null;
    _deviceStateSubscription?.cancel();
    _deviceStateSubscription = null;

    for (final StreamSubscription<List<int>> subscription in _notifySubscriptions) {
      subscription.cancel();
    }
    _notifySubscriptions.clear();

    try {
      await _connectedDevice?.disconnect();
    } catch (exception) {
      // Ignore disconnect cleanup errors
    }
    _connectedDevice = null;
    _writeCharacteristic = null;

    _updateState(BleConnectionState.disconnected);
  }
}
