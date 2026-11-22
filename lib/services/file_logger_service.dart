// CAN = Controller Area Network
// ECU = Electronic Control Unit
// CSV = Comma-Separated Values
// JSON = JavaScript Object Notation
// VE = Volumetric Efficiency
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/remap_matrix.dart';

/// Service managing disk logging for raw CAN frames, telemetry CSV rows,
/// and accumulated remap matrices.
class FileLoggerService {
  /// Singleton instance of [FileLoggerService].
  static final FileLoggerService instance = FileLoggerService._internal();
  FileLoggerService._internal();

  IOSink? _rawCanSink;
  IOSink? _telemetrySink;
  File? _matrixFile;

  String? _sessionTimestamp;
  String? _logDirectoryPath;
  bool _isLogging = false;

  /// Whether a logging session is actively open on disk.
  bool get isLogging => _isLogging;

  /// Absolute filesystem path to the directory where active logs are written.
  String? get logDirectoryPath => _logDirectoryPath;

  /// Initializes file streams on disk for a new logging session.
  Future<void> startSession() async {
    if (_isLogging) {
      await stopSession();
    }

    final DateTime now = DateTime.now();
    _sessionTimestamp = DateFormat('yyyyMMdd_HHmmss').format(now);

    Directory baseDir;
    try {
      baseDir = await getApplicationDocumentsDirectory();
    } catch (exception) {
      baseDir = Directory.current;
    }

    final Directory logsDir = Directory('${baseDir.path}/ecu_logs');
    if (!await logsDir.exists()) {
      await logsDir.create(recursive: true);
    }
    _logDirectoryPath = logsDir.path;

    // 1. Raw CAN file
    final File rawCanFile = File('${logsDir.path}/raw_can_$_sessionTimestamp.log');
    _rawCanSink = rawCanFile.openWrite(mode: FileMode.append);
    _rawCanSink?.writeln('# ECU Logger Raw CAN Session Started: ${now.toIso8601String()}');

    // 2. Telemetry CSV file
    final File telemetryFile = File('${logsDir.path}/telemetry_$_sessionTimestamp.csv');
    _telemetrySink = telemetryFile.openWrite(mode: FileMode.append);
    _telemetrySink?.writeln(
      'timestamp,rpm,tps,map_kpa,ect_c,iat_c,stft,ltft,ve_density,ve_corrected,vva_status'
    );

    // 3. Matrix JSON file
    _matrixFile = File('${logsDir.path}/remap_matrix_$_sessionTimestamp.json');

    _isLogging = true;
  }

  /// Appends a raw CAN frame line to the raw frame disk log.
  void logRawCan(String line) {
    if (!_isLogging || _rawCanSink == null) return;
    final String timestamp = DateTime.now().toIso8601String();
    _rawCanSink?.writeln('[$timestamp] $line');
  }

  /// Appends a structured telemetry row to the active CSV file.
  void logTelemetryRow({
    required double rpm,
    required double tps,
    required double mapKpa,
    required double ectC,
    required double iatC,
    required double stft,
    required double ltft,
    required double veDensity,
    required double veCorrected,
    required bool isVvaActive,
  }) {
    if (!_isLogging || _telemetrySink == null) return;
    final String timestamp = DateTime.now().toIso8601String();
    _telemetrySink?.writeln(
      '$timestamp,${rpm.toStringAsFixed(1)},${tps.toStringAsFixed(1)},'
      '${mapKpa.toStringAsFixed(1)},${ectC.toStringAsFixed(1)},${iatC.toStringAsFixed(1)},'
      '${stft.toStringAsFixed(2)},${ltft.toStringAsFixed(2)},'
      '${veDensity.toStringAsFixed(2)},${veCorrected.toStringAsFixed(2)},'
      '${isVvaActive ? "ACTIVE" : "INACTIVE"}'
    );
  }

  /// Flushes all active file sinks to guarantee persistence.
  Future<void> flush() async {
    try {
      await _rawCanSink?.flush();
      await _telemetrySink?.flush();
    } catch (exception) {
      // Ignore background disk flush exceptions during app lifecycle transitions
    }
  }

  /// Writes the accumulated remap matrix to disk in formatted JSON.
  Future<void> saveRemapMatrix(RemapMatrix matrix) async {
    if (_matrixFile != null) {
      try {
        await _matrixFile?.writeAsString(matrix.toFormattedJson());
      } catch (exception) {
        // Ignore background write exceptions
      }
    }
  }

  /// Finalizes and closes the active logging session and persists the [matrix].
  Future<void> stopSession([RemapMatrix? matrix]) async {
    if (!_isLogging) return;
    _isLogging = false;

    if (matrix != null) {
      await saveRemapMatrix(matrix);
    }

    try {
      await _rawCanSink?.flush();
      await _rawCanSink?.close();
    } catch (exception) {
      // Ignore sink close exceptions
    }
    _rawCanSink = null;

    try {
      await _telemetrySink?.flush();
      await _telemetrySink?.close();
    } catch (exception) {
      // Ignore sink close exceptions
    }
    _telemetrySink = null;
  }
}
