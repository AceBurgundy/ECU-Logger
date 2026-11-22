// ECU = Electronic Control Unit
import 'package:flutter/material.dart';
import 'theme/github_theme.dart';
import 'screens/splash_screen.dart';

/// Application entry point initializing the widget tree and starting the application
/// with the minimalist loading splash screen.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EcuLoggerApp());
}

/// Root widget configuring the application theme and top-level MaterialApp.
class EcuLoggerApp extends StatelessWidget {
  /// Optional custom home widget (useful for targeted testing or bypassing splash).
  final Widget? home;

  /// Creates the root [EcuLoggerApp] instance.
  const EcuLoggerApp({
    super.key,
    this.home,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ECU Logger',
      debugShowCheckedModeBanner: false,
      theme: GitHubTheme.darkTheme,
      home: home ?? const SplashScreen(),
    );
  }
}
