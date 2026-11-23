// BLE = Bluetooth Low Energy
// RSSI = Received Signal Strength Indicator
// GATT = Generic Attribute Profile
// UUID = Universally Unique Identifier
// OBD = On-Board Diagnostics
// UART = Universal Asynchronous Receiver-Transmitter
// PID = Parameter Identification
import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'elm327_protocol.dart';
import 'telemetry_engine.dart';

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

  /// Whether this peripheral matches known OBD-II scanner signatures.
  final bool isObd;

  /// Underlying FlutterBluePlus BluetoothDevice instance (null in simulation).
  final BluetoothDevice? device;

  /// Creates a [BleDiscoveredDevice] instance.
  BleDiscoveredDevice({
    required this.id,
    required this.name,
    required this.rssi,
    this.isObd = false,
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
  bool _isHardwarePollingActive = false;
  Completer<String>? _pendingCommandCompleter;
  final StringBuffer _commandResponseBuffer = StringBuffer();

  void _updateState(BleConnectionState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  /// Requests required runtime permissions for Bluetooth scanning, connectivity, and storage.
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

  /// Checks whether a discovered peripheral matches known OBD-II scanner signatures.
  static bool checkIsObd(String id, String name, List<Guid> serviceUuids) {
    final String upperId = id.toUpperCase();
    final String lowerName = name.toLowerCase();

    if (upperId.contains('8C:DE:52:DF:42:C3')) return true;

    final List<String> obdKeywords = <String>[
      'nexas',
      'nexlink',
      'obd',
      'vlink',
      'v-link',
      'ios-vlink',
      'carista',
      'elm327',
      'viecar',
      'konnwei',
      'icar',
    ];

    for (final String keyword in obdKeywords) {
      if (lowerName.contains(keyword)) return true;
    }

    for (final Guid uuid in serviceUuids) {
      final String strUuid = uuid.str.toLowerCase();
      if (strUuid.contains('fff0') || strUuid.contains('ffe0') || strUuid.contains('18f0')) {
        return true;
      }
    }

    return false;
  }

  void _sortDiscoveredDevices() {
    _discoveredDevices.sort((BleDiscoveredDevice a, BleDiscoveredDevice b) {
      // 1. Target NEXAS NexLink MAC or named NexLink always absolute first
      final bool aTarget = a.id.toUpperCase().contains('8C:DE:52:DF:42:C3') ||
          a.name.toUpperCase().contains('NEXAS') ||
          a.name.toUpperCase().contains('NEXLINK');
      final bool bTarget = b.id.toUpperCase().contains('8C:DE:52:DF:42:C3') ||
          b.name.toUpperCase().contains('NEXAS') ||
          b.name.toUpperCase().contains('NEXLINK');
      if (aTarget && !bTarget) return -1;
      if (!aTarget && bTarget) return 1;

      // 2. Other OBD devices next
      if (a.isObd && !b.isObd) return -1;
      if (!a.isObd && b.isObd) return 1;

      // 3. Named devices next
      final bool aNamed = a.name.isNotEmpty && a.name != 'Unknown BLE Device';
      final bool bNamed = b.name.isNotEmpty && b.name != 'Unknown BLE Device';
      if (aNamed && !bNamed) return -1;
      if (!aNamed && bNamed) return 1;

      // 4. Higher RSSI (stronger signal)
      return b.rssi.compareTo(a.rssi);
    });
  }

  /// Initiates a BLE peripheral scan searching for NexLink / OBD-II adapters.
  Future<void> startScan() async {
    await requestPermissions();
    _discoveredDevices.clear();

    // 1. Check system bonded / paired devices first
    try {
      final List<BluetoothDevice> bondedList = await FlutterBluePlus.bondedDevices;
      for (final BluetoothDevice bondedDevice in bondedList) {
        final String bondedId = bondedDevice.remoteId.str;
        String bondedName = bondedDevice.platformName;
        if (bondedName.isEmpty && bondedId.toUpperCase().contains('8C:DE:52:DF:42:C3')) {
          bondedName = 'NEXAS NexLink OBD2';
        }
        if (bondedName.isEmpty) {
          bondedName = 'Paired Bluetooth Device';
        }

        final bool isObd = checkIsObd(bondedId, bondedName, <Guid>[]);
        _discoveredDevices.add(
          BleDiscoveredDevice(
            id: bondedId,
            name: bondedName,
            rssi: -50,
            isObd: isObd,
            device: bondedDevice,
          ),
        );
      }
    } catch (exception) {
      // Ignore bonded query errors on unsupported platforms
    }

    _sortDiscoveredDevices();
    _deviceListController.add(List<BleDiscoveredDevice>.from(_discoveredDevices));
    _updateState(BleConnectionState.scanning);

    try {
      _scanSubscription?.cancel();
      _scanSubscription = FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
        for (final ScanResult scanResult in results) {
          final String deviceIdentifier = scanResult.device.remoteId.str;
          final int existingIndex =
              _discoveredDevices.indexWhere((BleDiscoveredDevice item) => item.id == deviceIdentifier);

          String name = scanResult.advertisementData.advName;
          if (name.isEmpty) {
            name = scanResult.device.platformName;
          }
          if (name.isEmpty && existingIndex >= 0) {
            final String previousName = _discoveredDevices[existingIndex].name;
            if (previousName.isNotEmpty && previousName != 'Unknown BLE Device') {
              name = previousName;
            }
          }
          if ((name.isEmpty || name == 'Unknown BLE Device') &&
              deviceIdentifier.toUpperCase().contains('8C:DE:52:DF:42:C3')) {
            name = 'NEXAS NexLink OBD2';
          }
          if (name.isEmpty) {
            name = 'Unknown BLE Device';
          }

          final bool isObd = checkIsObd(
            deviceIdentifier,
            name,
            scanResult.advertisementData.serviceUuids,
          );

          final BleDiscoveredDevice discoveredDevice = BleDiscoveredDevice(
            id: deviceIdentifier,
            name: name,
            rssi: scanResult.rssi,
            isObd: isObd,
            device: scanResult.device,
          );

          if (existingIndex >= 0) {
            _discoveredDevices[existingIndex] = discoveredDevice;
          } else {
            _discoveredDevices.add(discoveredDevice);
          }
        }
        _sortDiscoveredDevices();
        _deviceListController.add(List<BleDiscoveredDevice>.from(_discoveredDevices));
      });

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        continuousUpdates: true,
        androidScanMode: AndroidScanMode.lowLatency,
        androidCheckLocationServices: false,
      );
    } catch (exception) {
      // Add simulated NexLink device if physical scan fails (e.g. mock/emulator)
      _discoveredDevices.add(
        BleDiscoveredDevice(
          id: '8C:DE:52:DF:42:C3',
          name: 'NEXAS NexLink (Mock/Sim)',
          rssi: -58,
          isObd: true,
        ),
      );
      _sortDiscoveredDevices();
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
        timeout: const Duration(seconds: 12),
      );

      // Listen for unexpected hardware disconnection
      _deviceStateSubscription?.cancel();
      _deviceStateSubscription =
          _connectedDevice!.connectionState.listen((BluetoothConnectionState connectionState) {
        if (connectionState == BluetoothConnectionState.disconnected &&
            _state == BleConnectionState.connected) {
          _dataStreamController.add('[SYSTEM] Hardware adapter disconnected.\r\n');
          disconnect();
        }
      });

      final List<BluetoothService> services = await _connectedDevice!.discoverServices();
      BluetoothCharacteristic? rxCharacteristic;
      BluetoothCharacteristic? txCharacteristic;

      // 1. Look for NexLink / FFF0 or IS1870 49535343 UART service profiles
      for (final BluetoothService service in services) {
        final String serviceUuidStr = service.uuid.str.toLowerCase();
        if (serviceUuidStr.contains('fff0') || serviceUuidStr.contains('49535343')) {
          for (final BluetoothCharacteristic characteristic in service.characteristics) {
            if ((characteristic.properties.notify || characteristic.properties.indicate) &&
                rxCharacteristic == null) {
              rxCharacteristic = characteristic;
            }
            if ((characteristic.properties.write || characteristic.properties.writeWithoutResponse) &&
                txCharacteristic == null) {
              txCharacteristic = characteristic;
            }
          }
        }
      }

      // 2. Generic UART fallback (HM-10 FFE0, Nordic NUS, etc.)
      if (rxCharacteristic == null || txCharacteristic == null) {
        for (final BluetoothService service in services) {
          for (final BluetoothCharacteristic characteristic in service.characteristics) {
            if ((characteristic.properties.notify || characteristic.properties.indicate) &&
                rxCharacteristic == null) {
              rxCharacteristic = characteristic;
            }
            if ((characteristic.properties.write || characteristic.properties.writeWithoutResponse) &&
                txCharacteristic == null) {
              txCharacteristic = characteristic;
            }
          }
          if (rxCharacteristic != null && txCharacteristic != null) break;
        }
      }

      if (rxCharacteristic == null || txCharacteristic == null) {
        throw Exception('Failed to resolve paired UART TX/RX characteristics.');
      }

      _writeCharacteristic = txCharacteristic;

      // Subscribe exclusively to the resolved RX characteristic
      await rxCharacteristic.setNotifyValue(true);
      final StreamSubscription<List<int>> notifySubscription =
          rxCharacteristic.onValueReceived.listen((List<int> value) {
        final String text = utf8.decode(value, allowMalformed: true);
        _dataStreamController.add(text);
        _onDataReceived(text);
      });
      _notifySubscriptions.add(notifySubscription);

      _updateState(BleConnectionState.connected);

      // Execute ELM327 initialization handshake sequence
      await _runElm327InitSequence();

      // Start hardware polling loop for continuous live telemetry
      _startHardwarePollingLoop();
    } catch (exception) {
      _dataStreamController.add('[SYSTEM] Connection error: $exception\r\n');
      _updateState(BleConnectionState.error);
      disconnect();
    }
  }

  void _onDataReceived(String text) {
    _commandResponseBuffer.write(text);
    if (text.contains('>')) {
      if (_pendingCommandCompleter != null && !_pendingCommandCompleter!.isCompleted) {
        _pendingCommandCompleter!.complete(_commandResponseBuffer.toString());
      }
    }
  }

  /// Sends a raw command string terminated by carriage return and awaits the prompt.
  Future<String> sendCommand(
    String command, {
    Duration timeout = const Duration(milliseconds: 1500),
  }) async {
    if (_state != BleConnectionState.connected) return '';

    if (_writeCharacteristic != null) {
      _commandResponseBuffer.clear();
      final Completer<String> commandCompleter = Completer<String>();
      _pendingCommandCompleter = commandCompleter;

      try {
        final List<int> bytes = utf8.encode('$command\r');
        try {
          await _writeCharacteristic!.write(bytes, withoutResponse: true);
        } catch (exception) {
          await _writeCharacteristic!.write(bytes, withoutResponse: false);
        }

        final String response = await commandCompleter.future.timeout(
          timeout,
          onTimeout: () {
            if (_pendingCommandCompleter == commandCompleter) {
              _pendingCommandCompleter = null;
            }
            return _commandResponseBuffer.toString();
          },
        );
        return response;
      } catch (exception) {
        return '';
      } finally {
        if (_pendingCommandCompleter == commandCompleter) {
          _pendingCommandCompleter = null;
        }
      }
    } else {
      _dataStreamController.add('>$command\rOK\r');
      return 'OK>';
    }
  }

  Future<void> _runElm327InitSequence() async {
    _dataStreamController.add('[SYSTEM] Starting ELM327 protocol handshake...\r\n');

    // 1. Warm start and reset to clear any sticky hardware registers
    await sendCommand('ATWS', timeout: const Duration(seconds: 2));
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await sendCommand('ATZ', timeout: const Duration(seconds: 2));
    await Future<void>.delayed(const Duration(milliseconds: 300));

    // 2. Transceiver setup
    await sendCommand('ATE0', timeout: const Duration(milliseconds: 800));
    await sendCommand('ATL0', timeout: const Duration(milliseconds: 600));
    await sendCommand('ATS0', timeout: const Duration(milliseconds: 600));
    await sendCommand('ATCRA', timeout: const Duration(milliseconds: 600));
    await sendCommand('ATSP6', timeout: const Duration(milliseconds: 800));
    await sendCommand('ATST32', timeout: const Duration(milliseconds: 600));
    await sendCommand('ATAT1', timeout: const Duration(milliseconds: 600));
    await sendCommand('ATCAF1', timeout: const Duration(milliseconds: 600));
    await sendCommand('ATH1', timeout: const Duration(milliseconds: 600));

    // Check battery voltage immediately
    final String batteryResponse = await sendCommand('ATRV', timeout: const Duration(milliseconds: 800));
    final double? batteryVolts = Elm327Protocol.parseAtVoltage(batteryResponse);
    if (batteryVolts != null) {
      TelemetryEngine.instance.updateBatteryVoltage(batteryVolts);
      TelemetryEngine.instance.addLogLine('[SYSTEM] ECU Battery Voltage: ${batteryVolts.toStringAsFixed(1)}V');
    }

    // 3. Ping ECU (0100) & Supported PIDs discovery
    await sendCommand('ATSH7DF', timeout: const Duration(milliseconds: 600));
    String pingResponse = await sendCommand('0100', timeout: const Duration(seconds: 2));
    if (pingResponse.contains('CAN ERROR') || pingResponse.contains('NO DATA') || !pingResponse.contains('4100')) {
      _dataStreamController.add('[SYSTEM] 0x7DF functional address unacknowledged. Switching to physical 0x7E0...\r\n');
      await sendCommand('ATSH7E0', timeout: const Duration(milliseconds: 800));
      pingResponse = await sendCommand('0100', timeout: const Duration(seconds: 2));
    }

    // Discover Mode 01 Supported PIDs from the successful response
    final List<int> supported00 = Elm327Protocol.decodeSupportedPidsBitmask(0x00, pingResponse);
    for (final int pid in supported00) {
      TelemetryEngine.instance.registerSupportedPid(pid);
    }

    _dataStreamController.add('[SYSTEM] ELM327 handshake complete. Protocol locked.\r\n');
  }

  void _startHardwarePollingLoop() {
    _isHardwarePollingActive = true;
    int cycle = 0;

    Future<void>.microtask(() async {
      while (_state == BleConnectionState.connected && _isHardwarePollingActive) {
        cycle++;
        try {
          // Poll battery voltage frequently (every 4 cycles ~ 2s) so rider sees live voltage changes
          if (cycle % 4 == 0) {
            final String atrv = await sendCommand('ATRV', timeout: const Duration(milliseconds: 600));
            final double? volts = Elm327Protocol.parseAtVoltage(atrv);
            if (volts != null) {
              TelemetryEngine.instance.updateBatteryVoltage(volts);
            }
          }

          // If supported PIDs have not been discovered yet (dormant ECU), retry 0100 every 12 cycles (~6s)
          if (TelemetryEngine.instance.supportedMetricIds.length <= 1 && cycle % 12 == 1) {
            final String ping = await sendCommand('0100', timeout: const Duration(milliseconds: 800));
            if (ping.contains('4100') || ping.contains('41 00')) {
              final List<int> pids = Elm327Protocol.decodeSupportedPidsBitmask(0x00, ping);
              for (final int pid in pids) {
                TelemetryEngine.instance.registerSupportedPid(pid);
              }
            }
          }

          // High frequency: RPM & TPS
          if (cycle % 2 == 1) {
            await sendCommand('010C', timeout: const Duration(milliseconds: 600));
          } else {
            await sendCommand('0111', timeout: const Duration(milliseconds: 600));
          }

          // Medium frequency: MAP & ECT
          if (cycle % 6 == 0) {
            await sendCommand('010B', timeout: const Duration(milliseconds: 600));
          } else if (cycle % 8 == 0) {
            await sendCommand('0105', timeout: const Duration(milliseconds: 600));
          }

          // Low frequency: IAT, Baro, STFT, LTFT, Timing, Load
          if (cycle % 14 == 0) {
            await sendCommand('010F', timeout: const Duration(milliseconds: 600));
          } else if (cycle % 18 == 0) {
            await sendCommand('0133', timeout: const Duration(milliseconds: 600));
          } else if (cycle % 22 == 0) {
            await sendCommand('0106', timeout: const Duration(milliseconds: 600));
          } else if (cycle % 26 == 0) {
            await sendCommand('0107', timeout: const Duration(milliseconds: 600));
          } else if (cycle % 30 == 0) {
            await sendCommand('010E', timeout: const Duration(milliseconds: 600));
          } else if (cycle % 34 == 0) {
            await sendCommand('0104', timeout: const Duration(milliseconds: 600));
          }

          await Future<void>.delayed(const Duration(milliseconds: 50));
        } catch (exception) {
          // Ignore single command timeout drops
        }
      }
    });
  }

  void _startMockDataStream() {
    _mockTimer?.cancel();
    int count = 0;

    // Register simulated metrics into TelemetryEngine
    TelemetryEngine.instance.registerDiscoveredMetric('rpm');
    TelemetryEngine.instance.registerDiscoveredMetric('tps');
    TelemetryEngine.instance.registerDiscoveredMetric('map');
    TelemetryEngine.instance.registerDiscoveredMetric('ve');
    TelemetryEngine.instance.registerDiscoveredMetric('ect');
    TelemetryEngine.instance.registerDiscoveredMetric('iat');
    TelemetryEngine.instance.registerDiscoveredMetric('baro');
    TelemetryEngine.instance.registerDiscoveredMetric('volt');
    TelemetryEngine.instance.registerDiscoveredMetric('vva');

    // Simulate initial handshake responses
    _dataStreamController.add('>ATZ\rELM327 v1.5\r');
    _dataStreamController.add('>ATE0\rOK\r');
    _dataStreamController.add('>ATL0\rOK\r');
    _dataStreamController.add('>ATH1\rOK\r');
    _dataStreamController.add('>ATSP6\rOK\r');

    _mockTimer = Timer.periodic(const Duration(milliseconds: 120), (Timer timer) {
      if (_state != BleConnectionState.connected) {
        timer.cancel();
        return;
      }
      count++;
      final double rpmValue = 1800.0 + ((count * 180) % 7600);
      final String rawRpmHex =
          ((rpmValue * 4).toInt()).toRadixString(16).padLeft(4, '0').toUpperCase();
      final String byte0 = rawRpmHex.substring(0, 2);
      final String byte1 = rawRpmHex.substring(2, 4);

      final double tpsPercentage = 12.0 + ((count % 50) * 1.6);
      final String rawTpsHex =
          ((tpsPercentage * 255) / 100).toInt().toRadixString(16).padLeft(2, '0').toUpperCase();

      final String can770 = '770 08 $byte0 $byte1 $rawTpsHex 00 00 00 00 00';
      _dataStreamController.add('$can770\r');

      if (count % 3 == 0) {
        final int mapKpa = 42 + ((count * 3) % 58);
        final String mapHex = mapKpa.toRadixString(16).padLeft(2, '0').toUpperCase();
        _dataStreamController.add('41 0B $mapHex\r');
      }

      if (count % 5 == 0) {
        const int ectValue = 84;
        final String ectHex = (ectValue + 40).toRadixString(16).padLeft(2, '0').toUpperCase();
        _dataStreamController.add('41 05 $ectHex\r');
      }

      if (count % 6 == 0) {
        const int iatValue = 35;
        final String iatHex = (iatValue + 40).toRadixString(16).padLeft(2, '0').toUpperCase();
        _dataStreamController.add('41 0F $iatHex\r');
      }

      if (count % 7 == 0) {
        final bool isVva = rpmValue >= 7400;
        _dataStreamController.add('212 04 ${isVva ? "01" : "00"} 00 00 00\r');
      }

      if (count % 8 == 0) {
        _dataStreamController.add('41 33 65\r'); // Baro 101 kPa
        _dataStreamController.add('41 42 30 20\r'); // Voltage 12.32V
      }
    });
  }

  /// Terminates connection, cancels polling timers, and clears stream listeners.
  Future<void> disconnect() async {
    _isHardwarePollingActive = false;
    _mockTimer?.cancel();
    _mockTimer = null;
    if (_pendingCommandCompleter != null && !_pendingCommandCompleter!.isCompleted) {
      _pendingCommandCompleter!.complete(_commandResponseBuffer.toString());
    }
    _pendingCommandCompleter = null;
    _commandResponseBuffer.clear();
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
