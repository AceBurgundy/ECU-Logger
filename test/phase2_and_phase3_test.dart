// ECU = Electronic Control Unit
// OBD = On-Board Diagnostics
// RPM = Revolutions Per Minute
// TPS = Throttle Position Sensor
// MAP = Manifold Absolute Pressure
// ECT = Engine Coolant Temperature
// VE = Volumetric Efficiency
// BLE = Bluetooth Low Energy
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecu_logger/models/dashboard_layout.dart';
import 'package:ecu_logger/models/telemetry_metric.dart';
import 'package:ecu_logger/services/dashboard_layout_service.dart';
import 'package:ecu_logger/services/telemetry_engine.dart';
import 'package:ecu_logger/screens/home_screen.dart';
import 'package:ecu_logger/widgets/metric_card.dart';
import 'package:ecu_logger/widgets/font_size_dialog.dart';
import 'package:ecu_logger/widgets/saved_layouts_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 2: Empty States & Red Stop Button Tests', () {
    test('P2.T1: Every metric returns type-matched zero placeholders and never dashes', () {
      final TelemetryData emptyData = TelemetryData();
      const bool isConnected = false;

      for (final TelemetryMetric metric in TelemetryMetric.allMetrics) {
        final String formatted = metric.valueFormatter(emptyData, isConnected);
        expect(formatted, isNot(contains('--')),
            reason: '${metric.name} should not contain dashes');

        if (metric.id == 'rpm' || metric.id == 'speed') {
          expect(formatted, equals('00'),
              reason: 'Integer metric ${metric.name} must display 00');
        } else if (metric.id == 'tps' ||
            metric.id == 've' ||
            metric.id == 'stft' ||
            metric.id == 'ltft' ||
            metric.id == 'load') {
          expect(formatted, equals('0%'),
              reason: 'Percentage metric ${metric.name} must display 0%');
        } else if (metric.id == 'volt') {
          expect(formatted, equals('0.00'),
              reason: 'Voltage metric must display 0.00');
        } else if (metric.id == 'o2') {
          expect(formatted, equals('0.000'),
              reason: 'O2 metric must display 0.000');
        } else if (metric.id == 'vva') {
          expect(formatted, equals('OFF'),
              reason: 'VVA status metric must display OFF');
        } else {
          expect(formatted, equals('0.0'),
              reason: 'Decimal metric ${metric.name} must display 0.0');
        }
      }
    });

    testWidgets('P2.T2: Red Stop button is hidden when disconnected',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      // Disconnected: Red Stop button is completely hidden
      expect(find.byIcon(Icons.stop_circle_outlined), findsNothing);
      expect(find.byIcon(Icons.bluetooth), findsWidgets);
    });
  });

  group('Phase 3: Dashboard UI Overhaul Tests', () {
    testWidgets('P3.T1: Default View Mode has flush cards and tight header layout',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MetricCard(
              label: 'Engine Speed',
              value: '00',
              unit: 'RPM',
              isEditMode: false,
            ),
          ),
        ),
      );
      await tester.pump();

      // Card is rendered with flush transparent container
      final Container container = tester.widget<Container>(
        find.descendant(of: find.byType(MetricCard), matching: find.byType(Container)).first,
      );
      final BoxDecoration decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.transparent));
      expect(find.text('ENGINE SPEED'), findsOneWidget);
      expect(find.text('RPM'), findsOneWidget);
      expect(find.text('00'), findsOneWidget);
    });

    testWidgets('P3.T2: Long press activates Edit Mode, restoring card background and borders',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('ECU Logger'), findsOneWidget);
      expect(find.text('Edit Dashboard'), findsNothing);

      // Long press triggers Edit Mode
      await tester.longPress(find.text('ENGINE SPEED'));
      await tester.pump();

      expect(find.text('Edit Dashboard'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('P3.T4: Active card selection displays Bright Neon Yellow border and handles',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MetricCard(
              label: 'Throttle Position',
              value: '0%',
              unit: '%',
              isEditMode: true,
              isActive: true,
            ),
          ),
        ),
      );
      await tester.pump();

      // In active edit mode, container has neon yellow border
      final Container container = tester.widget<Container>(
        find.descendant(of: find.byType(MetricCard), matching: find.byType(Container)).first,
      );
      final BoxDecoration decoration = container.decoration as BoxDecoration;
      final Border border = decoration.border as Border;
      expect(border.top.color, equals(const Color(0xFFCCFF00)));
    });

    testWidgets('P3.T5: Font size dialog allows customizing title, value, and unit sizes',
        (WidgetTester tester) async {
      ({double titleSize, double valueSize, double unitSize})? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () async {
                  dialogResult = await FontSizeDialog.show(
                    context: context,
                    cardTitle: 'Coolant Temp',
                    currentTitleSize: 10.5,
                    currentValueSize: 28.0,
                    currentUnitSize: 9.5,
                  );
                },
                child: const Text('Open Dialog'),
              );
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Font Sizes: Coolant Temp'), findsOneWidget);
      expect(find.text('Title Label'), findsOneWidget);
      expect(find.text('Numeric Value'), findsOneWidget);
      expect(find.text('Unit Badge Pill'), findsOneWidget);

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(dialogResult, isNotNull);
      expect(dialogResult!.titleSize, equals(10.5));
      expect(dialogResult!.valueSize, equals(28.0));
      expect(dialogResult!.unitSize, equals(9.5));
    });

    testWidgets('P3.T6: Edit Mode Cancel button triggers discard confirmation dialog',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      // Enter edit mode
      await tester.longPress(find.text('ENGINE SPEED'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));

      expect(find.text('Edit Dashboard'), findsOneWidget);

      // Tap Cancel FAB while jiggle is active
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump(const Duration(milliseconds: 300));

      // Confirmation dialog appears
      expect(find.text('Discard Changes?'), findsOneWidget);
      expect(find.text('Keep Editing'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);

      // Tap Discard which stops jiggle and exits edit mode
      await tester.tap(find.text('Discard'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(seconds: 4));

      // Exits edit mode back to standard view
      expect(find.text('ECU Logger'), findsOneWidget);
      expect(find.text('Edit Dashboard'), findsNothing);
    });

    testWidgets('P3.T7 & P3.T8: Grid icon opens SavedLayoutsDialog with wireframe carousel',
        (WidgetTester tester) async {
      final DashboardLayoutService layoutService = DashboardLayoutService.instance;
      await layoutService.initialize();

      // Seed 2 designs via edit mode cycles
      layoutService.startEditMode();
      await layoutService.saveEditMode();
      layoutService.startEditMode();
      await layoutService.saveEditMode();

      expect(layoutService.canShowGridIcon, isTrue);

      DashboardDesign? previewed;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () {
                  SavedLayoutsDialog.show(
                    context: context,
                    onPreviewSelected: (DashboardDesign d) => previewed = d,
                  );
                },
                child: const Text('Open Grid Dialog'),
              );
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open Grid Dialog'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Saved Cockpit Layouts'), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsWidgets);
      expect(find.byIcon(Icons.delete_outline_rounded), findsWidgets);

      // Tap Preview button
      await tester.tap(find.byIcon(Icons.visibility_outlined).first);
      await tester.pump(const Duration(milliseconds: 300));

      expect(previewed, isNotNull);
    });
  });
}
