// ECU = Electronic Control Unit
import 'package:flutter/material.dart';
import 'theme/github_theme.dart';
import 'screens/home_screen.dart';
import 'services/ble_service.dart';

/// Application entry point initializing the widget tree and kicking off
/// background permission requests.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EcuLoggerApp());
  // Request required permissions in background after initial render
  Future<void>.microtask(() => BleService.instance.requestPermissions());
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
