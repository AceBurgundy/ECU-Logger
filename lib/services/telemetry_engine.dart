// RPM = Revolutions Per Minute
// TPS = Throttle Position Sensor
// MAP = Manifold Absolute Pressure
// ECT = Engine Coolant Temperature
// IAT = Intake Air Temperature
// BARO = Barometric Pressure
// STFT = Short Term Fuel Trim
// LTFT = Long Term Fuel Trim
// VE = Volumetric Efficiency
// VVA = Variable Valve Actuation
// PID = Parameter Identification
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'ble_service.dart';
import 'elm327_protocol.dart';
import 'file_logger_service.dart';
import '../models/remap_matrix.dart';

/// Immutable snapshot containing real-time telemetry sensor channels and calculated VE.
class TelemetryData {
  /// Engine speed in Revolutions Per Minute. Null when disconnected or not yet received.
  final double? rpm;

  /// Throttle valve opening position in percentage (0% - 100%).
  final double? tps;

  /// Manifold absolute pressure in kPa.
  final double? mapKpa;

  /// Engine coolant temperature in degrees Celsius.
  final double? ectC;

  /// Intake air temperature in degrees Celsius.
  final double? iatC;

  /// Barometric atmospheric pressure in kPa.
  final double? baroKpa;

  /// Short term fuel trim percentage.
  final double? stft;

  /// Long term fuel trim percentage.
  final double? ltft;

  /// Uncorrected Speed-Density Volumetric Efficiency percentage.
  final double? veDensity;

  /// Fuel-trim corrected Volumetric Efficiency percentage.
  final double? veCorrected;

  /// Whether Variable Valve Actuation high-cam profile is actively engaged.
  final bool? isVvaActive;

  /// Control module battery voltage in Volts.
  final double? batteryVoltage;

  /// Calculated engine load in percentage.
  final double? engineLoad;

  /// Ignition timing advance in degrees BTDC.
  final double? timingAdvance;

  /// O2 sensor voltage in Volts.
  final double? o2Voltage;

  /// Vehicle speed in km/h.
  final double? speedKmh;

  /// Timestamp when this telemetry snapshot was captured.
  final DateTime timestamp;

  /// Creates a [TelemetryData] instance with all channels defaulting to null (uninitialized).
  TelemetryData({
    this.rpm,
    this.tps,
    this.mapKpa,
    this.ectC,
    this.iatC,
    this.baroKpa,
    this.stft,
    this.ltft,
    this.veDensity,
    this.veCorrected,
    this.isVvaActive,
    this.batteryVoltage,
    this.engineLoad,
    this.timingAdvance,
    this.o2Voltage,
    this.speedKmh,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Creates a copy of this [TelemetryData] updating selected fields.
  TelemetryData copyWith({
    double? rpm,
    double? tps,
    double? mapKpa,
    double? ectC,
    double? iatC,
    double? baroKpa,
    double? stft,
    double? ltft,
    double? veDensity,
    double? veCorrected,
    bool? isVvaActive,
    double? batteryVoltage,
    double? engineLoad,
    double? timingAdvance,
    double? o2Voltage,
    double? speedKmh,
  }) {
    return TelemetryData(
      rpm: rpm ?? this.rpm,
      tps: tps ?? this.tps,
      mapKpa: mapKpa ?? this.mapKpa,
      ectC: ectC ?? this.ectC,
      iatC: iatC ?? this.iatC,
      baroKpa: baroKpa ?? this.baroKpa,
      stft: stft ?? this.stft,
      ltft: ltft ?? this.ltft,
      veDensity: veDensity ?? this.veDensity,
      veCorrected: veCorrected ?? this.veCorrected,
      isVvaActive: isVvaActive ?? this.isVvaActive,
      batteryVoltage: batteryVoltage ?? this.batteryVoltage,
      engineLoad: engineLoad ?? this.engineLoad,
      timingAdvance: timingAdvance ?? this.timingAdvance,
      o2Voltage: o2Voltage ?? this.o2Voltage,
      speedKmh: speedKmh ?? this.speedKmh,
      timestamp: DateTime.now(),
    );
  }
}

/// Central state notifier orchestrating raw frame decoding, Speed-Density VE math,
/// VVA hysteresis evaluation, supported metrics catalog, and disk logging hooks.
class TelemetryEngine extends ChangeNotifier {
  /// Singleton instance of [TelemetryEngine].
  static final TelemetryEngine instance = TelemetryEngine._internal();
  TelemetryEngine._internal() {
    _initListeners();
  }

  TelemetryData _currentData = TelemetryData();

  /// Latest captured [TelemetryData] snapshot.
  TelemetryData get currentData => _currentData;

  /// Dual-cam remap matrix accumulator populated in real time.
  final RemapMatrix remapMatrix = RemapMatrix();

  /// Set of telemetry metric IDs discovered/supported by the ECU on this motorcycle.
  final Set<String> _supportedMetricIds = <String>{};

  /// Read-only view of metric IDs discovered on the motorcycle.
  Set<String> get supportedMetricIds => Set.unmodifiable(_supportedMetricIds);

  /// Ordered list of metric IDs currently displayed on the dashboard cards.
  final List<String> _activeDashboardMetricIds = <String>[
    'rpm',
    'tps',
    'map',
    've',
    'ect',
    'vva',
  ];

  /// Read-only list of active dashboard metric IDs.
  List<String> get activeDashboardMetricIds => List.unmodifiable(_activeDashboardMetricIds);

  final List<String> _rollingLogs = [];

  /// Rolling collection of console log messages.
  List<String> get rollingLogs => List.unmodifiable(_rollingLogs);

  /// Maximum number of log lines retained in the rolling buffer.
  static const int maxLogLines = 200;

  StreamSubscription<String>? _bleDataSub;
  StreamSubscription<BleConnectionState>? _bleStateSub;
  String _incomingBuffer = '';

  void _initListeners() {
    _bleStateSub = BleService.instance.stateStream.listen((BleConnectionState state) {
      if (state == BleConnectionState.connected) {
        if (FileLoggerService.instance.hasConfiguredFolder) {
          FileLoggerService.instance.startSession();
          addLogLine('[SYSTEM] BLE Connected. Logging session initiated.');
        } else {
          addLogLine('[SYSTEM] BLE Connected. Storage folder pending selection.');
        }
      } else if (state == BleConnectionState.disconnected) {
        FileLoggerService.instance.stopSession(remapMatrix);
        addLogLine('[SYSTEM] BLE Disconnected. Session auto-saved.');
        // Clear card readouts, partial line buffer, and discovered metrics on disconnect
        _incomingBuffer = '';
        _currentData = TelemetryData();
        _supportedMetricIds.clear();
      }
      notifyListeners();
    });

    _bleDataSub = BleService.instance.dataStream.listen((String chunk) {
      _processIncomingChunk(chunk);
    });
  }

  /// Registers a newly discovered telemetry metric into the supported set.
  void registerDiscoveredMetric(String metricId) {
    if (!_supportedMetricIds.contains(metricId)) {
      _supportedMetricIds.add(metricId);
      notifyListeners();
    }
  }

  /// Updates battery voltage from ATRV or Mode 01 PID 42 and marks channel supported.
  void updateBatteryVoltage(double volts) {
    registerDiscoveredMetric('volt');
    _updateMetrics(newVolt: volts);
  }

  /// Registers a discovered OBD PID into the supported metrics set.
  void registerSupportedPid(int pidNumber) {
    switch (pidNumber) {
      case 0x0C:
        _supportedMetricIds.add('rpm');
        break;
      case 0x11:
        _supportedMetricIds.add('tps');
        break;
      case 0x0B:
        _supportedMetricIds.add('map');
        _supportedMetricIds.add('ve');
        break;
      case 0x05:
        _supportedMetricIds.add('ect');
        break;
      case 0x0F:
        _supportedMetricIds.add('iat');
        break;
      case 0x33:
        _supportedMetricIds.add('baro');
        break;
      case 0x42:
        _supportedMetricIds.add('volt');
        break;
      case 0x06:
        _supportedMetricIds.add('stft');
        break;
      case 0x07:
        _supportedMetricIds.add('ltft');
        break;
      case 0x04:
        _supportedMetricIds.add('load');
        break;
      case 0x0E:
        _supportedMetricIds.add('timing');
        break;
      case 0x14:
        _supportedMetricIds.add('o2');
        break;
      case 0x0D:
        _supportedMetricIds.add('speed');
        break;
    }
    notifyListeners();
  }

  /// Sets the active dashboard cards to the provided [metricIds].
  void setDashboardMetrics(List<String> metricIds) {
    _activeDashboardMetricIds.clear();
    _activeDashboardMetricIds.addAll(metricIds);
    notifyListeners();
  }

  /// Toggles whether a metric is shown on the dashboard.
  void toggleMetric(String metricId) {
    if (_activeDashboardMetricIds.contains(metricId)) {
      if (_activeDashboardMetricIds.length > 1) {
        _activeDashboardMetricIds.remove(metricId);
      }
    } else {
      _activeDashboardMetricIds.add(metricId);
    }
    notifyListeners();
  }

  /// Removes a single metric from the active dashboard cards.
  void removeDashboardMetric(String metricId) {
    if (_activeDashboardMetricIds.length > 1 && _activeDashboardMetricIds.contains(metricId)) {
      _activeDashboardMetricIds.remove(metricId);
      notifyListeners();
    }
  }

  /// Reorders cards on the dashboard when dragged from [oldIndex] to [newIndex].
  void reorderDashboardMetrics(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _activeDashboardMetricIds.length) return;
    if (newIndex < 0 || newIndex >= _activeDashboardMetricIds.length) return;
    final String movedItem = _activeDashboardMetricIds.removeAt(oldIndex);
    _activeDashboardMetricIds.insert(newIndex, movedItem);
    notifyListeners();
  }

  /// Appends a raw log line to the rolling buffer and disk sink.
  void addLogLine(String line) {
    if (_rollingLogs.length >= maxLogLines) {
      _rollingLogs.removeAt(0);
    }
    _rollingLogs.add(line);
    FileLoggerService.instance.logRawCan(line);
    notifyListeners();
  }

  /// Clears the rolling log buffer.
  void clearLogs() {
    _rollingLogs.clear();
    notifyListeners();
  }

  void _processIncomingChunk(String chunk) {
    _incomingBuffer += chunk;
    if (_incomingBuffer.contains('\r') || _incomingBuffer.contains('\n')) {
      final List<String> lines = _incomingBuffer.split(RegExp(r'[\r\n]+'));
      // Retain last incomplete fragment
      _incomingBuffer = lines.last;
      if (_incomingBuffer == '>') {
        _incomingBuffer = '';
      }

      for (int index = 0; index < lines.length - 1; index++) {
        String line = lines[index].trim();
        line = line.replaceAll('>', '').trim();
        if (line.isNotEmpty) {
          _parseLine(line);
        }
      }
    }
  }

  void _parseLine(String line) {
    addLogLine(line);

    // 0. Check Mode 01 Supported PIDs discovery bitmask (0100 / 4100)
    if (line.contains('4100') || line.contains('41 00')) {
      final List<int> supportedPids = Elm327Protocol.decodeSupportedPidsBitmask(0x00, line);
      for (final int pid in supportedPids) {
        registerSupportedPid(pid);
      }
      return;
    }

    // 1. Check raw CAN frames (Yamaha 0x20A, 0x770, 0x212, 0x236, 0x240)
    final Map<String, dynamic>? rawCan = Elm327Protocol.parseRawCanFrame(line);
    if (rawCan != null) {
      if (rawCan['rpm'] != null || rawCan['tps'] != null) {
        final double? rpm = rawCan['rpm'] as double?;
        final double? tps = rawCan['tps'] as double?;
        if (rpm != null) registerDiscoveredMetric('rpm');
        if (tps != null) registerDiscoveredMetric('tps');
        _updateMetrics(newRpm: rpm, newTps: tps);
      }
      if (rawCan['vva'] != null) {
        final bool isVva = rawCan['vva'] as bool;
        registerDiscoveredMetric('vva');
        _updateMetrics(newVva: isVva);
      }
      if (rawCan['ect'] != null) {
        final double ect = rawCan['ect'] as double;
        registerDiscoveredMetric('ect');
        _updateMetrics(newEct: ect);
      }
      if (rawCan['stft'] != null || rawCan['ltft'] != null || rawCan['o2'] != null) {
        if (rawCan['stft'] != null) registerDiscoveredMetric('stft');
        if (rawCan['ltft'] != null) registerDiscoveredMetric('ltft');
        if (rawCan['o2'] != null) registerDiscoveredMetric('o2');
        _updateMetrics(
          newStft: rawCan['stft'] as double?,
          newLtft: rawCan['ltft'] as double?,
          newO2: rawCan['o2'] as double?,
        );
      }
      return;
    }

    // 2. Check OBD-II standard PIDs
    final double? rpm = Elm327Protocol.parseMode01Rpm(line);
    if (rpm != null) {
      registerDiscoveredMetric('rpm');
      _updateMetrics(newRpm: rpm);
      return;
    }

    final double? tps = Elm327Protocol.parseMode01Tps(line);
    if (tps != null) {
      registerDiscoveredMetric('tps');
      _updateMetrics(newTps: tps);
      return;
    }

    final double? mapKpa = Elm327Protocol.parseMode01Map(line);
    if (mapKpa != null) {
      registerDiscoveredMetric('map');
      registerDiscoveredMetric('ve');
      _updateMetrics(newMap: mapKpa);
      return;
    }

    final double? ect = Elm327Protocol.parseMode01Ect(line);
    if (ect != null) {
      registerDiscoveredMetric('ect');
      _updateMetrics(newEct: ect);
      return;
    }

    final double? iat = Elm327Protocol.parseMode01Iat(line);
    if (iat != null) {
      registerDiscoveredMetric('iat');
      _updateMetrics(newIat: iat);
      return;
    }

    final double? baro = Elm327Protocol.parseMode01Baro(line);
    if (baro != null) {
      registerDiscoveredMetric('baro');
      _updateMetrics(newBaro: baro);
      return;
    }

    final double? volt = Elm327Protocol.parseMode01Voltage(line) ?? Elm327Protocol.parseAtVoltage(line);
    if (volt != null) {
      registerDiscoveredMetric('volt');
      _updateMetrics(newVolt: volt);
      return;
    }

    final double? stft = Elm327Protocol.parseMode01Stft(line);
    if (stft != null) {
      registerDiscoveredMetric('stft');
      _updateMetrics(newStft: stft);
      return;
    }

    final double? ltft = Elm327Protocol.parseMode01Ltft(line);
    if (ltft != null) {
      registerDiscoveredMetric('ltft');
      _updateMetrics(newLtft: ltft);
      return;
    }

    final double? load = Elm327Protocol.parseMode01EngineLoad(line);
    if (load != null) {
      registerDiscoveredMetric('load');
      _updateMetrics(newLoad: load);
      return;
    }

    final double? timing = Elm327Protocol.parseMode01TimingAdvance(line);
    if (timing != null) {
      registerDiscoveredMetric('timing');
      _updateMetrics(newTiming: timing);
      return;
    }

    final double? o2 = Elm327Protocol.parseMode01O2(line);
    if (o2 != null) {
      registerDiscoveredMetric('o2');
      _updateMetrics(newO2: o2);
      return;
    }

    final double? speed = Elm327Protocol.parseMode01Speed(line);
    if (speed != null) {
      registerDiscoveredMetric('speed');
      _updateMetrics(newSpeed: speed);
      return;
    }
  }

  void _updateMetrics({
    double? newRpm,
    double? newTps,
    double? newMap,
    double? newEct,
    double? newIat,
    double? newBaro,
    double? newVolt,
    double? newStft,
    double? newLtft,
    double? newLoad,
    double? newTiming,
    double? newO2,
    double? newSpeed,
    bool? newVva,
  }) {
    final double? rpm = newRpm ?? _currentData.rpm;
    final double? tps = newTps ?? _currentData.tps;
    final double? mapKpa = newMap ?? _currentData.mapKpa;
    final double? ectC = newEct ?? _currentData.ectC;
    final double? iatC = newIat ?? _currentData.iatC;
    final double? baroKpa = newBaro ?? _currentData.baroKpa;
    final double? volt = newVolt ?? _currentData.batteryVoltage;
    final double? stft = newStft ?? _currentData.stft;
    final double? ltft = newLtft ?? _currentData.ltft;
    final double? load = newLoad ?? _currentData.engineLoad;
    final double? timing = newTiming ?? _currentData.timingAdvance;
    final double? o2 = newO2 ?? _currentData.o2Voltage;
    final double? speed = newSpeed ?? _currentData.speedKmh;

    // VVA Hysteresis calculation:
    // Engages at >= 7,400 RPM (when ECT >= 60°C); Disengages at < 7,000 RPM
    bool? vvaActive = _currentData.isVvaActive;
    if (newVva != null) {
      vvaActive = newVva;
    } else if (rpm != null) {
      final double effectiveEct = ectC ?? 25.0;
      if (vvaActive != true && rpm >= 7400.0 && effectiveEct >= 60.0) {
        vvaActive = true;
      } else if (vvaActive == true && rpm < 7000.0) {
        vvaActive = false;
      }
      vvaActive ??= false;
    }

    // VE% Speed-Density Calculation:
    // Only calculated when engine is running (RPM > 0). If engine is off, VE is 0.0%.
    double? veDensity;
    double? veCorrected;
    final bool isEngineRunning = rpm != null && rpm > 0.0;
    if (mapKpa != null) {
      if (!isEngineRunning) {
        veDensity = 0.0;
        veCorrected = 0.0;
      } else {
        final double effectiveBaro = (baroKpa != null && baroKpa > 0.0) ? baroKpa : 101.3;
        final double effectiveIat = iatC ?? 25.0;
        veDensity = (mapKpa / effectiveBaro) * (293.15 / (273.15 + effectiveIat)) * 100.0;

        final double effectiveStft = stft ?? 0.0;
        final double effectiveLtft = ltft ?? 0.0;
        veCorrected = veDensity * (1.0 + ((effectiveStft + effectiveLtft) / 100.0));
      }
    }

    _currentData = _currentData.copyWith(
      rpm: rpm,
      tps: tps,
      mapKpa: mapKpa,
      ectC: ectC,
      iatC: iatC,
      baroKpa: baroKpa,
      batteryVoltage: volt,
      stft: stft,
      ltft: ltft,
      engineLoad: load,
      timingAdvance: timing,
      o2Voltage: o2,
      speedKmh: speed,
      veDensity: veDensity,
      veCorrected: veCorrected,
      isVvaActive: vvaActive,
    );

    // Record sample in remap matrix accumulator if valid
    if (rpm != null && tps != null && veCorrected != null) {
      remapMatrix.recordSample(
        rpm: rpm,
        tps: tps,
        ve: veCorrected,
        isVvaActive: vvaActive ?? false,
      );
    }

    // Write row to telemetry CSV
    if (rpm != null || tps != null || mapKpa != null) {
      FileLoggerService.instance.logTelemetryRow(
        rpm: rpm ?? 0.0,
        tps: tps ?? 0.0,
        mapKpa: mapKpa ?? 101.3,
        ectC: ectC ?? 25.0,
        iatC: iatC ?? 25.0,
        stft: stft ?? 0.0,
        ltft: ltft ?? 0.0,
        veDensity: veDensity ?? 0.0,
        veCorrected: veCorrected ?? 0.0,
        isVvaActive: vvaActive ?? false,
      );
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _bleDataSub?.cancel();
    _bleStateSub?.cancel();
    super.dispose();
  }
}
