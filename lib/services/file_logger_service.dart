// CAN = Controller Area Network
// ECU = Electronic Control Unit
// CSV = Comma-Separated Values
// JSON = JavaScript Object Notation
// VE = Volumetric Efficiency
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/remap_matrix.dart';

/// Service managing disk logging for raw CAN frames, telemetry CSV rows,
/// and accumulated remap matrices, with support for customizable folder selection.
class FileLoggerService {
  /// Singleton instance of [FileLoggerService].
  static final FileLoggerService instance = FileLoggerService._internal();
  FileLoggerService._internal();

  IOSink? _rawCanSink;
  IOSink? _telemetrySink;
  File? _matrixFile;

  String? _sessionTimestamp;
  String? _customLogDirectoryPath;
  bool _isLogging = false;

  /// Configuration file name for storing user-chosen log directory.
  static const String _configFileName = 'ecu_logger_storage_config.json';

  /// Whether a logging session is actively open on disk.
  bool get isLogging => _isLogging;

  /// Absolute filesystem path to the directory where active logs are written.
  String? get logDirectoryPath => _customLogDirectoryPath;

  /// Whether a valid custom directory has already been selected by the user.
  bool get hasConfiguredFolder =>
      _customLogDirectoryPath != null &&
      _customLogDirectoryPath!.isNotEmpty &&
      Directory(_customLogDirectoryPath!).existsSync();

  /// Initializes storage settings by restoring previously selected directory.
  Future<void> initialize() async {
    try {
      final Directory baseDirectory = await getApplicationDocumentsDirectory();
      final File configFile = File('${baseDirectory.path}/$_configFileName');
      if (await configFile.exists()) {
        final String contents = await configFile.readAsString();
        // dynamic required here: JSON decode returns untyped map structure
        final dynamic decoded = jsonDecode(contents);
        if (decoded is Map<String, dynamic> && decoded['log_path'] is String) {
          final String restoredPath = decoded['log_path'] as String;
          if (await Directory(restoredPath).exists()) {
            _customLogDirectoryPath = restoredPath;
          }
        }
      }
    } catch (exception) {
      // Ignore config read exceptions on initial startup
    }
  }

  /// Persists the custom log directory path to application storage.
  Future<void> _persistConfig(String directoryPath) async {
    try {
      final Directory baseDirectory = await getApplicationDocumentsDirectory();
      final File configFile = File('${baseDirectory.path}/$_configFileName');
      final Map<String, String> payload = <String, String>{
        'log_path': directoryPath,
      };
      await configFile.writeAsString(jsonEncode(payload));
    } catch (exception) {
      // Ignore background persistence errors
    }
  }

  /// Explicitly requests runtime storage and external management permissions.
  Future<bool> requestStoragePermissions() async {
    try {
      if (Platform.isAndroid) {
        final PermissionStatus manageStatus =
            await Permission.manageExternalStorage.status;
        if (manageStatus.isGranted) {
          return true;
        }
        final PermissionStatus requestManage =
            await Permission.manageExternalStorage.request();
        if (requestManage.isGranted) {
          return true;
        }
        final PermissionStatus storageStatus = await Permission.storage.request();
        return storageStatus.isGranted || storageStatus.isLimited;
      }
      return true;
    } catch (exception) {
      return true; // Desktop / simulated environment fallback
    }
  }

  /// Opens the native system folder picker with the existing path as initialDirectory.
  ///
  /// Returns the newly chosen folder path string, or null if the user cancelled.
  Future<String?> pickLogDirectory() async {
    await requestStoragePermissions();

    final String? selectedDirectory = await FilePickerPlatform.instance.getDirectoryPath(
      dialogTitle: 'Select ECU Telemetry Log Folder',
      initialDirectory: _customLogDirectoryPath,
    );

    if (selectedDirectory != null && selectedDirectory.isNotEmpty) {
      final Directory targetDir = Directory(selectedDirectory);
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      _customLogDirectoryPath = selectedDirectory;
      await _persistConfig(selectedDirectory);
      return selectedDirectory;
    }

    return null;
  }

  /// Sets the custom log directory directly without opening the picker.
  Future<void> setCustomLogDirectory(String path) async {
    final Directory directory = Directory(path);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    _customLogDirectoryPath = path;
    await _persistConfig(path);
  }

  /// Initializes file streams on disk for a new logging session.
  ///
  /// If [explicitDirectoryPath] is omitted and no custom folder was selected,
  /// falls back to application documents storage.
  Future<void> startSession({String? explicitDirectoryPath}) async {
    if (_isLogging) {
      await stopSession();
    }

    final DateTime now = DateTime.now();
    _sessionTimestamp = DateFormat('yyyyMMdd_HHmmss').format(now);

    String targetBasePath;
    if (explicitDirectoryPath != null && explicitDirectoryPath.isNotEmpty) {
      targetBasePath = explicitDirectoryPath;
    } else if (_customLogDirectoryPath != null && _customLogDirectoryPath!.isNotEmpty) {
      targetBasePath = _customLogDirectoryPath!;
    } else {
      Directory baseDir;
      try {
        baseDir = await getApplicationDocumentsDirectory();
      } catch (exception) {
        baseDir = Directory.current;
      }
      targetBasePath = '${baseDir.path}/ecu_logs';
    }

    final Directory logsDir = Directory(targetBasePath);
    if (!await logsDir.exists()) {
      await logsDir.create(recursive: true);
    }
    if (explicitDirectoryPath != null && explicitDirectoryPath.isNotEmpty) {
      _customLogDirectoryPath = explicitDirectoryPath;
      await _persistConfig(explicitDirectoryPath);
    }

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
        await _matrixFile?.writeAsString(matrix.toFormattedJson(), flush: true);
      } catch (exception) {
        // Ignore background write exceptions
      }
    }
  }

  /// Finalizes and closes the active logging session and persists the [matrix].
  Future<void> stopSession([RemapMatrix? matrix]) async {
    if (!_isLogging) return;
    _isLogging = false;

    final File? matrixFileToFinalize = _matrixFile;
    _matrixFile = null;

    final IOSink? rawSink = _rawCanSink;
    _rawCanSink = null;

    final IOSink? telemetrySink = _telemetrySink;
    _telemetrySink = null;

    if (matrix != null && matrixFileToFinalize != null) {
      try {
        await matrixFileToFinalize.writeAsString(
          matrix.toFormattedJson(),
          flush: true,
        );
      } catch (exception) {
        // Ignore final matrix write exceptions
      }
    }

    try {
      await rawSink?.flush();
      await rawSink?.close();
    } catch (exception) {
      // Ignore sink close exceptions
    }

    try {
      await telemetrySink?.flush();
      await telemetrySink?.close();
    } catch (exception) {
      // Ignore sink close exceptions
    }
  }
}
