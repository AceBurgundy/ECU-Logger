import 'dart:async';
import 'package:flutter/foundation.dart';
import 'ble_service.dart';
import 'elm327_protocol.dart';
import 'file_logger_service.dart';
import '../models/remap_matrix.dart';

class TelemetryData {
  final double rpm;
  final double tps;
  final double mapKpa;
  final double ectC;
  final double iatC;
  final double baroKpa;
  final double stft;
  final double ltft;
  final double veDensity;
  final double veCorrected;
  final bool isVvaActive;
  final DateTime timestamp;

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

class TelemetryEngine extends ChangeNotifier {
  static final TelemetryEngine instance = TelemetryEngine._internal();
  TelemetryEngine._internal() {
    _initListeners();
  }

  TelemetryData _currentData = TelemetryData();
  TelemetryData get currentData => _currentData;

  final RemapMatrix remapMatrix = RemapMatrix();
  final List<String> _rollingLogs = [];
  List<String> get rollingLogs => List.unmodifiable(_rollingLogs);

  static const int maxLogLines = 200;

  StreamSubscription? _bleDataSub;
  StreamSubscription? _bleStateSub;
  String _incomingBuffer = '';

  void _initListeners() {
    _bleStateSub = BleService.instance.stateStream.listen((state) {
      if (state == BleConnectionState.connected) {
        FileLoggerService.instance.startSession();
        addLogLine('[SYSTEM] BLE Connected. Logging session initiated.');
      } else if (state == BleConnectionState.disconnected) {
        FileLoggerService.instance.stopSession(remapMatrix);
        addLogLine('[SYSTEM] BLE Disconnected. Session auto-saved.');
      }
      notifyListeners();
    });

    _bleDataSub = BleService.instance.dataStream.listen((chunk) {
      _processIncomingChunk(chunk);
    });
  }

  void addLogLine(String line) {
    if (_rollingLogs.length >= maxLogLines) {
      _rollingLogs.removeAt(0);
    }
    _rollingLogs.add(line);
    FileLoggerService.instance.logRawCan(line);
    notifyListeners();
  }

  void clearLogs() {
    _rollingLogs.clear();
    notifyListeners();
  }

  void _processIncomingChunk(String chunk) {
    _incomingBuffer += chunk;
    if (_incomingBuffer.contains('\r') || _incomingBuffer.contains('\n')) {
      final lines = _incomingBuffer.split(RegExp(r'[\r\n]+'));
      // Keep last part if incomplete
      _incomingBuffer = lines.last;

      for (int i = 0; i < lines.length - 1; i++) {
        final line = lines[i].trim();
        if (line.isNotEmpty) {
          _parseLine(line);
        }
      }
    }
  }

  void _parseLine(String line) {
    addLogLine(line);

    // 1. Check raw CAN frames (Yamaha 0x770, 0x212, etc.)
    final rawCan = Elm327Protocol.parseRawCanFrame(line);
    if (rawCan != null) {
      if (rawCan['rpm'] != null || rawCan['tps'] != null) {
        final rpm = rawCan['rpm'] as double? ?? _currentData.rpm;
        final tps = rawCan['tps'] as double? ?? _currentData.tps;
        _updateMetrics(newRpm: rpm, newTps: tps);
      }
      if (rawCan['vva'] != null) {
        final isVva = rawCan['vva'] as bool;
        _updateMetrics(newVva: isVva);
      }
      return;
    }

    // 2. Check OBD-II standard PIDs
    final rpm = Elm327Protocol.parseMode01Rpm(line);
    if (rpm != null) {
      _updateMetrics(newRpm: rpm);
      return;
    }

    final tps = Elm327Protocol.parseMode01Tps(line);
    if (tps != null) {
      _updateMetrics(newTps: tps);
      return;
    }

    final mapKpa = Elm327Protocol.parseMode01Map(line);
    if (mapKpa != null) {
      _updateMetrics(newMap: mapKpa);
      return;
    }

    final ect = Elm327Protocol.parseMode01Ect(line);
    if (ect != null) {
      _updateMetrics(newEct: ect);
      return;
    }

    final iat = Elm327Protocol.parseMode01Iat(line);
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
    final rpm = newRpm ?? _currentData.rpm;
    final tps = newTps ?? _currentData.tps;
    final mapKpa = newMap ?? _currentData.mapKpa;
    final ectC = newEct ?? _currentData.ectC;
    final iatC = newIat ?? _currentData.iatC;
    final baroKpa = _currentData.baroKpa;
    final stft = _currentData.stft;
    final ltft = _currentData.ltft;

    // VVA Hysteresis calculation:
    // Engages at >= 7,400 RPM (when ECT >= 60°C); Disengages at < 7,000 RPM
    bool vvaActive = _currentData.isVvaActive;
    if (newVva != null) {
      vvaActive = newVva;
    } else {
      if (!vvaActive && rpm >= 7400 && ectC >= 60.0) {
        vvaActive = true;
      } else if (vvaActive && rpm < 7000) {
        vvaActive = false;
      }
    }

    // VE% Speed-Density Calculation:
    // VE_density = (MAP / Baro) * (293.15 / (273.15 + IAT)) * 100%
    final veDensity = (mapKpa / (baroKpa > 0 ? baroKpa : 101.3)) *
        (293.15 / (273.15 + iatC)) *
        100.0;

    // Fuel-Corrected VE:
    // VE_corrected = VE_density * (1 + (STFT + LTFT) / 100)
    final veCorrected = veDensity * (1.0 + ((stft + ltft) / 100.0));

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
