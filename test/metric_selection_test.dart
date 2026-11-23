// ECU = Electronic Control Unit
// OBD = On-Board Diagnostics
// RPM = Revolutions Per Minute
// TPS = Throttle Position Sensor
// MAP = Manifold Absolute Pressure
// ECT = Engine Coolant Temperature
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecu_logger/models/telemetry_metric.dart';
import 'package:ecu_logger/services/telemetry_engine.dart';
import 'package:ecu_logger/widgets/metric_selection_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Metric Selection & Placeholder Tests', () {
    test('Unconnected TelemetryData returns type-matched zero placeholders for all metrics', () {
      final TelemetryData emptyData = TelemetryData();
      const bool isConnected = false;

      for (final TelemetryMetric metric in TelemetryMetric.allMetrics) {
        final String formatted = metric.valueFormatter(emptyData, isConnected);
        expect(formatted, isNot(equals('--')), reason: 'Metric ${metric.name} must not display dashes');
        if (metric.id == 'rpm' || metric.id == 'speed') {
          expect(formatted, equals('00'), reason: 'Integer metric ${metric.name} should display 00');
        } else if (metric.id == 'tps' || metric.id == 've' || metric.id == 'stft' || metric.id == 'ltft' || metric.id == 'load') {
          expect(formatted, equals('0%'), reason: 'Percentage metric ${metric.name} should display 0%');
        } else if (metric.id == 'volt') {
          expect(formatted, equals('0.00'), reason: 'Voltage metric ${metric.name} should display 0.00');
        } else if (metric.id == 'o2') {
          expect(formatted, equals('0.000'), reason: 'O2 metric ${metric.name} should display 0.000');
        } else if (metric.id == 'vva') {
          expect(formatted, equals('OFF'), reason: 'VVA status metric should display OFF');
        } else {
          expect(formatted, equals('0.0'), reason: 'Decimal metric ${metric.name} should display 0.0');
        }
        expect(metric.isHighlight(emptyData, isConnected), isFalse);
      }
    });

    test('Connected TelemetryData displays valid sensor numbers', () {
      final TelemetryData liveData = TelemetryData(
        rpm: 3500.0,
        tps: 22.5,
        mapKpa: 65.0,
        ectC: 82.0,
        iatC: 32.0,
        baroKpa: 101.3,
        batteryVoltage: 12.8,
        engineLoad: 45.0,
        timingAdvance: 12.0,
        o2Voltage: 0.825,
        speedKmh: 48.0,
        isVvaActive: false,
      );
      const bool isConnected = true;

      final TelemetryMetric rpmMetric = TelemetryMetric.findById('rpm')!;
      expect(rpmMetric.valueFormatter(liveData, isConnected), equals('3500'));

      final TelemetryMetric tpsMetric = TelemetryMetric.findById('tps')!;
      expect(tpsMetric.valueFormatter(liveData, isConnected), equals('22.5'));

      final TelemetryMetric mapMetric = TelemetryMetric.findById('map')!;
      expect(mapMetric.valueFormatter(liveData, isConnected), equals('65.0'));

      final TelemetryMetric ectMetric = TelemetryMetric.findById('ect')!;
      expect(ectMetric.valueFormatter(liveData, isConnected), equals('82.0'));

      final TelemetryMetric voltMetric = TelemetryMetric.findById('volt')!;
      expect(voltMetric.valueFormatter(liveData, isConnected), equals('12.80'));
    });

    test('TelemetryEngine adds and removes dashboard metrics', () {
      final TelemetryEngine engine = TelemetryEngine.instance;
      expect(engine.activeDashboardMetricIds, contains('rpm'));
      expect(engine.activeDashboardMetricIds, contains('tps'));

      // Add a metric
      engine.toggleMetric('volt');
      expect(engine.activeDashboardMetricIds, contains('volt'));

      // Remove a metric
      engine.removeDashboardMetric('volt');
      expect(engine.activeDashboardMetricIds, isNot(contains('volt')));

      // Reorder metrics
      final String firstMetric = engine.activeDashboardMetricIds.first;
      final String secondMetric = engine.activeDashboardMetricIds[1];
      engine.reorderDashboardMetrics(0, 1);
      expect(engine.activeDashboardMetricIds[0], equals(secondMetric));
      expect(engine.activeDashboardMetricIds[1], equals(firstMetric));
    });

    testWidgets('MetricSelectionSheet shows only supported metrics and toggles them',
        (WidgetTester tester) async {
      final Set<String> supported = <String>{'rpm', 'tps', 'map'};
      final List<String> active = <String>['rpm'];
      String? toggledMetricId;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetricSelectionSheet(
              supportedMetricIds: supported,
              activeMetricIds: active,
              onToggle: (String id) {
                toggledMetricId = id;
              },
            ),
          ),
        ),
      );

      // Verify header and count
      expect(find.text('Live Telemetry Channels'), findsOneWidget);
      expect(find.text('3 Found'), findsOneWidget);

      // Verify supported items appear
      expect(find.text('Engine Speed'), findsOneWidget);
      expect(find.text('Throttle Position'), findsOneWidget);
      expect(find.text('Manifold Absolute Pressure'), findsOneWidget);

      // Unsupported items should NOT appear
      expect(find.text('Vehicle Speed'), findsNothing);

      // Tap on Throttle Position checkbox
      await tester.tap(find.text('Throttle Position'));
      await tester.pumpAndSettle();

      expect(toggledMetricId, equals('tps'));
    });

    testWidgets('MetricSelectionSheet shows empty state when no metrics discovered',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetricSelectionSheet(
              supportedMetricIds: const <String>{},
              activeMetricIds: const <String>['rpm'],
              onToggle: (String id) {},
            ),
          ),
        ),
      );

      expect(find.text('No Discovered Telemetry Channels'), findsOneWidget);
      expect(find.text('0 Found'), findsOneWidget);
    });

    test('TelemetryEngine dynamic discovery and voltage updates work', () {
      final TelemetryEngine engine = TelemetryEngine.instance;
      expect(engine.supportedMetricIds, isEmpty);

      // Register discovered metric
      engine.registerDiscoveredMetric('rpm');
      expect(engine.supportedMetricIds, contains('rpm'));

      // Update battery voltage
      engine.updateBatteryVoltage(12.7);
      expect(engine.supportedMetricIds, contains('volt'));
      expect(engine.currentData.batteryVoltage, equals(12.7));
    });

    testWidgets('MetricSelectionSheet with TelemetryEngine dynamically updates checkbox UI',
        (WidgetTester tester) async {
      final TelemetryEngine engine = TelemetryEngine.instance;
      engine.registerDiscoveredMetric('volt');
      engine.registerDiscoveredMetric('map');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetricSelectionSheet(
              telemetry: engine,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // volt should be in availableMetrics
      expect(find.text('ECU Module Voltage'), findsOneWidget);
      CheckboxListTile voltTile = tester.widget<CheckboxListTile>(
        find.widgetWithText(CheckboxListTile, 'ECU Module Voltage'),
      );
      expect(voltTile.value, isFalse);

      // Tap volt to toggle it ON
      await tester.tap(find.text('ECU Module Voltage'));
      await tester.pumpAndSettle();

      voltTile = tester.widget<CheckboxListTile>(
        find.widgetWithText(CheckboxListTile, 'ECU Module Voltage'),
      );
      expect(voltTile.value, isTrue);
      expect(engine.activeDashboardMetricIds, contains('volt'));
    });
  });
}
