// ECU = Electronic Control Unit
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecu_logger/screens/splash_screen.dart';
import 'package:ecu_logger/theme/github_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SplashScreen Tests', () {
    testWidgets('SplashScreen displays title, telemetry tags, and transitions to nextScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(
            minDisplayDuration: Duration(milliseconds: 200),
            nextScreen: Scaffold(body: Text('NEXT SCREEN')),
          ),
        ),
      );

      // Verify splash screen elements
      expect(find.text('ECU Logger'), findsOneWidget);
      expect(find.text('CAN BUS • OBD-II TELEMETRY'), findsOneWidget);

      // Verify typography styling
      final Text titleWidget = tester.widget<Text>(find.text('ECU Logger'));
      expect(titleWidget.style?.fontFamily, GitHubTheme.fontCanela);

      final Text footerWidget = tester.widget<Text>(find.text('CAN BUS • OBD-II TELEMETRY'));
      expect(footerWidget.style?.fontFamily, GitHubTheme.fontGoogleSansCode);

      // Verify PopScope protection
      final PopScope popScopeWidget = tester.widget<PopScope>(find.byType(PopScope));
      expect(popScopeWidget.canPop, isFalse);

      // Wait for initialization delay and route transition
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verify destination reached
      expect(find.text('NEXT SCREEN'), findsOneWidget);
    });
  });
}
