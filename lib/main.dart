// ECU = Electronic Control Unit
import 'package:flutter/material.dart';
import 'theme/github_theme.dart';
import 'screens/home_screen.dart';
import 'services/ble_service.dart';
import 'services/file_logger_service.dart';

/// Application entry point initializing the widget tree, restoring user settings,
/// and requesting necessary hardware and storage permissions.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FileLoggerService.instance.initialize();
  runApp(const EcuLoggerApp());
  // Request required permissions in background after initial render
  Future<void>.microtask(() async {
    await BleService.instance.requestPermissions();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await FileLoggerService.instance.requestStoragePermissions();
  });
}

/// Root widget configuring the application theme and top-level MaterialApp.
class EcuLoggerApp extends StatelessWidget {
  /// Creates the root [EcuLoggerApp] instance.
  const EcuLoggerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ECU Logger',
      debugShowCheckedModeBanner: false,
      theme: GitHubTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
