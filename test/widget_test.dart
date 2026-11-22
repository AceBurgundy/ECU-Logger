// ECU = Electronic Control Unit
// FAB = Floating Action Button
// RPM = Revolutions Per Minute
// TPS = Throttle Position Sensor
// MAP = Manifold Absolute Pressure
// VE = Volumetric Efficiency
// ECT = Engine Coolant Temperature
// VVA = Variable Valve Actuation
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecu_logger/main.dart';
import 'package:ecu_logger/widgets/metric_card.dart';
import 'package:ecu_logger/widgets/lock_overlay.dart';

void main() {
  testWidgets('EcuLoggerApp launches and displays Option 3 dashboard', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080.0, 2400.0);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const EcuLoggerApp());
    await tester.pumpAndSettle();

    // Verify App Title
    expect(find.text('ECU Logger'), findsOneWidget);

    // Verify Metric Readout Cards
    expect(find.text('ENGINE SPEED'), findsOneWidget);
    expect(find.text('THROTTLE (TPS)'), findsOneWidget);
    expect(find.text('MANIFOLD PRESSURE'), findsOneWidget);
    expect(find.text('VOLUMETRIC EFF.'), findsOneWidget);
    expect(find.text('COOLANT TEMP'), findsOneWidget);
    expect(find.text('VVA CAM STATUS'), findsOneWidget);

    // Verify Lock FAB exists
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);

    // Pump through any pending microtasks/timers
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('Lock FAB displays translucent lock overlay and unlocks', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080.0, 2400.0);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const EcuLoggerApp());
    await tester.pumpAndSettle();

    // Tap Lock FAB
    await tester.tap(find.byIcon(Icons.lock_outline));
    await tester.pump();

    // Translucent Lock overlay is now visible
    expect(find.byType(LockOverlay), findsOneWidget);
    expect(find.textContaining('Press "'), findsOneWidget);
    expect(find.text('Pocket touch prevention active • Logging continues underneath'), findsOneWidget);

    // Verify numeric keypad buttons exist (0-9, CLR)
    expect(find.text('CLR'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);

    // Pump through toast timers
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('MetricCard displays values and labels correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MetricCard(
            label: 'Test Metric',
            value: '4250',
            unit: 'RPM',
            isHighlight: true,
          ),
        ),
      ),
    );

    expect(find.text('TEST METRIC'), findsOneWidget);
    expect(find.text('4250'), findsOneWidget);
    expect(find.text('RPM'), findsOneWidget);
  });
}
