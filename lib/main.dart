import 'package:flutter/material.dart';
import 'theme/github_theme.dart';
import 'screens/home_screen.dart';
import 'services/ble_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EcuLoggerApp());
  // Request required permissions in background after initial render
  Future.microtask(() => BleService.instance.requestPermissions());
}

class EcuLoggerApp extends StatelessWidget {
  const EcuLoggerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ecu_logger',
      debugShowCheckedModeBanner: false,
      theme: GitHubTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
