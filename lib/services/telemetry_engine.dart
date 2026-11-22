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
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'ble_service.dart';
import 'elm327_protocol.dart';
import 'file_logger_service.dart';
import '../models/remap_matrix.dart';

/// Immutable snapshot containing real-time telemetry sensor channels and calculated VE.
class TelemetryData {
  /// Engine speed in Revolutions Per Minute.
  final double rpm;

  /// Throttle valve opening position in percentage (0% - 100%).
  final double tps;

  /// Manifold absolute pressure in kPa.
  final double mapKpa;

  /// Engine coolant temperature in degrees Celsius.
  final double ectC;

  /// Intake air temperature in degrees Celsius.
  final double iatC;

  /// Barometric atmospheric pressure in kPa.
  final double baroKpa;

  /// Short term fuel trim percentage.
  final double stft;

  /// Long term fuel trim percentage.
  final double ltft;

  /// Uncorrected Speed-Density Volumetric Efficiency percentage.
  final double veDensity;

  /// Fuel-trim corrected Volumetric Efficiency percentage.
  final double veCorrected;

  /// Whether Variable Valve Actuation high-cam profile is actively engaged.
  final bool isVvaActive;

  /// Timestamp when this telemetry snapshot was captured.
  final DateTime timestamp;

  /// Creates a [TelemetryData] instance with default resting sensor values.
  TelemetryData({
    this.rpm = 0.0,
    this.tps = 0.0,
    this.mapKpa = 101.3,
    this.ectC = 25.0,
    this.iatC = 25.0,
    this.baroKpa = 101.3,
    this.stft = 0.0,
    this.ltft = 0.0,
    this.veDensity = 0.0,
    this.veCorrected = 0.0,
    this.isVvaActive = false,
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
      timestamp: DateTime.now(),
    );
  }
}

/// Central state notifier orchestrating raw frame decoding, Speed-Density VE math,
/// VVA hysteresis evaluation, and disk logging hooks.
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
        FileLoggerService.instance.startSession();
        addLogLine('[SYSTEM] BLE Connected. Logging session initiated.');
      } else if (state == BleConnectionState.disconnected) {
        FileLoggerService.instance.stopSession(remapMatrix);
        addLogLine('[SYSTEM] BLE Disconnected. Session auto-saved.');
      }
      notifyListeners();
    });

    _bleDataSub = BleService.instance.dataStream.listen((String chunk) {
      _processIncomingChunk(chunk);
    });
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

      for (int index = 0; index < lines.length - 1; index++) {
        final String line = lines[index].trim();
        if (line.isNotEmpty) {
          _parseLine(line);
        }
      }
    }
  }

  void _parseLine(String line) {
    addLogLine(line);

    // 1. Check raw CAN frames (Yamaha 0x770, 0x212, etc.)
    final Map<String, dynamic>? rawCan = Elm327Protocol.parseRawCanFrame(line);
    if (rawCan != null) {
      if (rawCan['rpm'] != null || rawCan['tps'] != null) {
        final double rpm = rawCan['rpm'] as double? ?? _currentData.rpm;
        final double tps = rawCan['tps'] as double? ?? _currentData.tps;
        _updateMetrics(newRpm: rpm, newTps: tps);
      }
      if (rawCan['vva'] != null) {
        final bool isVva = rawCan['vva'] as bool;
        _updateMetrics(newVva: isVva);
      }
      return;
    }

    // 2. Check OBD-II standard PIDs
    final double? rpm = Elm327Protocol.parseMode01Rpm(line);
    if (rpm != null) {
      _updateMetrics(newRpm: rpm);
      return;
    }

    final double? tps = Elm327Protocol.parseMode01Tps(line);
    if (tps != null) {
      _updateMetrics(newTps: tps);
      return;
    }

    final double? mapKpa = Elm327Protocol.parseMode01Map(line);
    if (mapKpa != null) {
      _updateMetrics(newMap: mapKpa);
      return;
    }

    final double? ect = Elm327Protocol.parseMode01Ect(line);
    if (ect != null) {
      _updateMetrics(newEct: ect);
      return;
    }

    final double? iat = Elm327Protocol.parseMode01Iat(line);
    if (iat != null) {
      _updateMetrics(newIat: iat);
      return;
    }
  }

  void _updateMetrics({
    double? newRpm,
    double? newTps,
    double? newMap,
    double? newEct,
    double? newIat,
    bool? newVva,
  }) {
    final double rpm = newRpm ?? _currentData.rpm;
    final double tps = newTps ?? _currentData.tps;
    final double mapKpa = newMap ?? _currentData.mapKpa;
    final double ectC = newEct ?? _currentData.ectC;
    final double iatC = newIat ?? _currentData.iatC;
    final double baroKpa = _currentData.baroKpa;
    final double stft = _currentData.stft;
    final double ltft = _currentData.ltft;

    // VVA Hysteresis calculation:
    // Engages at >= 7,400 RPM (when ECT >= 60°C); Disengages at < 7,000 RPM
    bool vvaActive = _currentData.isVvaActive;
    if (newVva != null) {
      vvaActive = newVva;
    } else {
      if (!vvaActive && rpm >= 7400.0 && ectC >= 60.0) {
        vvaActive = true;
      } else if (vvaActive && rpm < 7000.0) {
        vvaActive = false;
      }
    }

    // VE% Speed-Density Calculation:
    // VE_density = (MAP / Baro) * (293.15 / (273.15 + IAT)) * 100%
    final double veDensity = (mapKpa / (baroKpa > 0 ? baroKpa : 101.3)) *
        (293.15 / (273.15 + iatC)) *
        100.0;

    // Fuel-Corrected VE:
    // VE_corrected = VE_density * (1 + (STFT + LTFT) / 100)
    final double veCorrected = veDensity * (1.0 + ((stft + ltft) / 100.0));

    _currentData = _currentData.copyWith(
      rpm: rpm,
      tps: tps,
      mapKpa: mapKpa,
      ectC: ectC,
      iatC: iatC,
      veDensity: veDensity,
      veCorrected: veCorrected,
      isVvaActive: vvaActive,
    );

    // Record sample in remap matrix accumulator
    remapMatrix.recordSample(
      rpm: rpm,
      tps: tps,
      ve: veCorrected,
      isVvaActive: vvaActive,
    );

    // Write row to telemetry CSV
    FileLoggerService.instance.logTelemetryRow(
      rpm: rpm,
      tps: tps,
      mapKpa: mapKpa,
      ectC: ectC,
      iatC: iatC,
      stft: stft,
      ltft: ltft,
      veDensity: veDensity,
      veCorrected: veCorrected,
      isVvaActive: vvaActive,
    );

    notifyListeners();
  }

  @override
  void dispose() {
    _bleDataSub?.cancel();
    _bleStateSub?.cancel();
    super.dispose();
  }
}
