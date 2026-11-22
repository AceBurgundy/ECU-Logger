// ECU = Electronic Control Unit
// FAB = Floating Action Button
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecu_logger/screens/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeScreen Edit Mode & Wobble Tests', () {
    testWidgets('Long press on card enters edit mode and displays Done button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pump();

      // Initially in normal mode
      expect(find.text('ECU Logger'), findsOneWidget);
      expect(find.text('Edit Dashboard'), findsNothing);
      expect(find.text('Done'), findsNothing);

      // Long press the first metric card
      await tester.longPress(find.text('ENGINE SPEED'));
      // Pump frame for animation and let toast dismiss
      await tester.pump(const Duration(milliseconds: 100));

      // Edit mode is now active
      expect(find.text('Edit Dashboard'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Drag here to remove from dashboard'), findsOneWidget);

      // Advance past toast duration so Done button is hit-testable
      await tester.pump(const Duration(seconds: 4));

      // Tap Done button to exit edit mode
      await tester.tap(find.text('Done'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('ECU Logger'), findsOneWidget);
      expect(find.text('Done'), findsNothing);
    });

    testWidgets('Channel selector FAB opens metric selection sheet',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pump();

      // Find the metric list FAB
      expect(find.byIcon(Icons.playlist_add_check_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.playlist_add_check_rounded));
      await tester.pump(const Duration(milliseconds: 300));

      // Verify bottom sheet appears
      expect(find.text('Live Telemetry Channels'), findsOneWidget);
    });

    testWidgets('Back navigation in edit mode exits edit mode cleanly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pump();

      // Enter edit mode via long press
      await tester.longPress(find.text('ENGINE SPEED'));
      await tester.pump();

      expect(find.text('Edit Dashboard'), findsOneWidget);

      // Trigger system back route
      await tester.binding.handlePopRoute();
      await tester.pump();

      expect(find.text('ECU Logger'), findsOneWidget);
      expect(find.text('Done'), findsNothing);

      // Elapse toast timer to avoid pending timer exception
      await tester.pump(const Duration(seconds: 4));
    });
  });
}
