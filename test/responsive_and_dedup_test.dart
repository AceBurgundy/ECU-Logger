// ECU = Electronic Control Unit
// RPM = Revolutions Per Minute
// TPS = Throttle Position Sensor
// MAP = Manifold Absolute Pressure
// VE = Volumetric Efficiency
// ECT = Engine Coolant Temperature
// VVA = Variable Valve Actuation
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecu_logger/models/dashboard_layout.dart';
import 'package:ecu_logger/models/remap_matrix.dart';
import 'package:ecu_logger/screens/home_screen.dart';
import 'package:ecu_logger/services/ble_service.dart';
import 'package:ecu_logger/services/dashboard_layout_service.dart';
import 'package:ecu_logger/services/file_logger_service.dart';
import 'package:ecu_logger/services/telemetry_engine.dart';
import 'package:ecu_logger/widgets/dashboard_flow_layout.dart';
import 'package:ecu_logger/widgets/font_size_dialog.dart';
import 'package:ecu_logger/widgets/metric_card.dart';
import 'package:ecu_logger/widgets/saved_layouts_dialog.dart';

Finder _cardFinderByLabel(String shortLabelUpper) {
  return find.ancestor(
    of: find.text(shortLabelUpper),
    matching: find.byType(MetricCard),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Adaptive Responsive Columns & Resizing Tests', () {
    test('computeDashboardColumnsForWidth maps breakpoints <600, 600-900, and >900 accurately', () {
      expect(computeDashboardColumnsForWidth(360.0), equals(4));
      expect(computeDashboardColumnsForWidth(412.0), equals(4));
      expect(computeDashboardColumnsForWidth(599.9), equals(4));
      expect(computeDashboardColumnsForWidth(600.0), equals(6));
      expect(computeDashboardColumnsForWidth(768.0), equals(6));
      expect(computeDashboardColumnsForWidth(900.0), equals(6));
      expect(computeDashboardColumnsForWidth(900.1), equals(8));
      expect(computeDashboardColumnsForWidth(1200.0), equals(8));
    });

    testWidgets('600dp-900dp viewport renders 6 columns (3 cards/row) and supports resizing up to 6 cols',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(780.0, 900.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      DashboardLayoutService.instance.resetForTesting();
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      final Rect rpmRect = tester.getRect(_cardFinderByLabel('ENGINE SPEED'));
      final Rect tpsRect = tester.getRect(_cardFinderByLabel('THROTTLE (TPS)'));
      final Rect mapRect = tester.getRect(_cardFinderByLabel('MANIFOLD PRESSURE'));
      final Rect veRect = tester.getRect(_cardFinderByLabel('VOLUMETRIC EFF.'));

      // 3 cards per row at 2-span on a 6-column grid
      expect(rpmRect.top, closeTo(tpsRect.top, 0.5));
      expect(tpsRect.top, closeTo(mapRect.top, 0.5));
      expect(veRect.top, greaterThan(rpmRect.bottom));

      // Enter Edit Mode, select ENGINE SPEED, and resize full width across 6 columns
      await tester.longPress(find.text('ENGINE SPEED'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text('ENGINE SPEED'));
      await tester.pump(const Duration(milliseconds: 350));

      final Rect editRpmRect = tester.getRect(_cardFinderByLabel('ENGINE SPEED'));
      final TestGesture rightDrag = await tester.startGesture(editRpmRect.centerRight);
      await tester.pump();
      await rightDrag.moveBy(const Offset(520.0, 0.0));
      await tester.pump();
      await rightDrag.up();
      await tester.pumpAndSettle();

      final CardConfig updatedRpm = DashboardLayoutService.instance.displayCards
          .firstWhere((CardConfig c) => c.metricId == 'rpm');
      expect(updatedRpm.colSpan, equals(6));

      await tester.pump(const Duration(seconds: 4));
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('>900dp viewport renders 8 columns (4 cards/row) and supports resizing up to 8 cols',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1100.0, 800.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      DashboardLayoutService.instance.resetForTesting();
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      final Rect rpmRect = tester.getRect(_cardFinderByLabel('ENGINE SPEED'));
      final Rect tpsRect = tester.getRect(_cardFinderByLabel('THROTTLE (TPS)'));
      final Rect mapRect = tester.getRect(_cardFinderByLabel('MANIFOLD PRESSURE'));
      final Rect veRect = tester.getRect(_cardFinderByLabel('VOLUMETRIC EFF.'));
      final Rect ectRect = tester.getRect(_cardFinderByLabel('COOLANT TEMP'));

      // 4 cards per row at 2-span on an 8-column grid
      expect(rpmRect.top, closeTo(tpsRect.top, 0.5));
      expect(tpsRect.top, closeTo(mapRect.top, 0.5));
      expect(mapRect.top, closeTo(veRect.top, 0.5));
      expect(ectRect.top, greaterThan(rpmRect.bottom));

      // Enter Edit Mode, select ENGINE SPEED, and resize full width across 8 columns
      await tester.longPress(find.text('ENGINE SPEED'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text('ENGINE SPEED'));
      await tester.pump(const Duration(milliseconds: 350));

      final Rect editRpmRect = tester.getRect(_cardFinderByLabel('ENGINE SPEED'));
      final TestGesture rightDrag = await tester.startGesture(editRpmRect.centerRight);
      await tester.pump();
      await rightDrag.moveBy(const Offset(850.0, 0.0));
      await tester.pump();
      await rightDrag.up();
      await tester.pumpAndSettle();

      final CardConfig updatedRpm = DashboardLayoutService.instance.displayCards
          .firstWhere((CardConfig c) => c.metricId == 'rpm');
      expect(updatedRpm.colSpan, equals(8));

      await tester.pump(const Duration(seconds: 4));
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4));
    });
  });

  group('Saved Layout Deduplication, Default Protection & Miniature Preview Tests', () {
    test('Deduplication prevents saving identical or default layouts and protects Factory Cockpit', () async {
      final DashboardLayoutService service = DashboardLayoutService.instance;
      service.resetForTesting();
      await service.initialize();

      expect(service.savedDesigns.length, equals(1));
      expect(service.savedDesigns.first.isDefault, isTrue);
      expect(service.canShowGridIcon, isFalse);

      // 1. Save with zero modifications -> must NOT duplicate
      service.startEditMode();
      expect(await service.saveEditMode(), isFalse);
      expect(service.savedDesigns.length, equals(1));
      expect(service.canShowGridIcon, isFalse);

      // 2. Save with explicit default font sizes (10.5, 28.0, 9.5) -> must NOT duplicate
      service.startEditMode();
      service.updateCardConfig(
        service.displayCards.first.copyWith(
          titleFontSize: 10.5,
          valueFontSize: 28.0,
          unitFontSize: 9.5,
        ),
      );
      expect(await service.saveEditMode(), isFalse);
      expect(service.savedDesigns.length, equals(1));

      // 3. Attempting to delete Factory Cockpit must be blocked
      await service.deleteDesign(DashboardDesign.defaultDesignId);
      expect(service.savedDesigns.length, equals(1));
      expect(service.savedDesigns.first.id, equals(DashboardDesign.defaultDesignId));

      // 4. Genuine layout change (resize colSpan to 4) creates new saved layout
      service.startEditMode();
      service.updateCardConfig(service.displayCards.first.copyWith(colSpan: 4));
      expect(await service.saveEditMode(), isTrue);
      expect(service.savedDesigns.length, equals(2));
      expect(service.canShowGridIcon, isTrue);

      // 5. Editing font size creates another unique saved layout with strictly unique ID
      service.startEditMode();
      service.updateCardConfig(service.displayCards.first.copyWith(valueFontSize: 64.0));
      expect(await service.saveEditMode(), isTrue);
      expect(service.savedDesigns.length, equals(3));
      expect(
        service.savedDesigns.map((DashboardDesign d) => d.id).toSet().length,
        equals(3),
      );

      // 6. Editing back to exact Factory Cockpit switches active without duplicating
      service.startEditMode();
      service.updateDraftCards(DashboardDesign.createDefault().cards);
      expect(await service.saveEditMode(), isFalse);
      expect(service.savedDesigns.length, equals(3));
      expect(service.activeDesign.isDefault, isTrue);

      // 7. Custom layouts CAN be deleted; default remains undeletable
      final String customId = service.savedDesigns[1].id;
      await service.deleteDesign(customId);
      expect(service.savedDesigns.length, equals(2));
    });

    testWidgets('SavedLayoutsDialog renders real miniature cards, hides delete on Factory Cockpit, and fits landscape',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(820.0, 400.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final DashboardLayoutService service = DashboardLayoutService.instance;
      service.resetForTesting();
      await service.initialize();

      service.startEditMode();
      service.updateCardConfig(service.displayCards.first.copyWith(colSpan: 4, valueFontSize: 55.0));
      await service.saveEditMode();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () {
                  SavedLayoutsDialog.show(
                    context: context,
                    onPreviewSelected: (_) {},
                  );
                },
                child: const Text('Open Dialog'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Factory Cockpit'), findsOneWidget);
      // Real miniature MetricCards rendered (not generic blue-dot wireframe)
      expect(find.byType(MetricCard), findsWidgets);

      // On Factory Cockpit card itself, delete button is strictly absent
      final Finder factoryCard = find.ancestor(
        of: find.text('Factory Cockpit'),
        matching: find.byWidgetPredicate(
          (Widget w) => w is Container && w.decoration is BoxDecoration,
        ),
      ).first;
      expect(
        find.descendant(
          of: factoryCard,
          matching: find.byIcon(Icons.delete_outline_rounded),
        ),
        findsNothing,
      );

      // Swipe to Page 1 (Cockpit Layout 2) -> delete button IS present on custom layout
      await tester.drag(find.byType(PageView), const Offset(-450.0, 0.0));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });
  });

  group('FontSizeDialog 80.0 pt Max Limit & Audit Regression Tests', () {
    testWidgets('FontSizeDialog supports up to 80.0 pt on Title, Value, and Unit without overflow',
        (WidgetTester tester) async {
      ({double titleSize, double valueSize, double unitSize})? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await FontSizeDialog.show(
                    context: context,
                    cardTitle: 'Manifold Absolute Pressure',
                    currentTitleSize: 80.0,
                    currentValueSize: 80.0,
                    currentUnitSize: 80.0,
                  );
                },
                child: const Text('Open Font Dialog'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Font Dialog'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('80.0 pt'), findsNWidgets(3));

      final List<Slider> sliders = tester.widgetList<Slider>(find.byType(Slider)).toList();
      expect(sliders.length, equals(3));
      for (final Slider slider in sliders) {
        expect(slider.max, equals(80.0));
        expect(slider.value, equals(80.0));
      }

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.titleSize, equals(80.0));
      expect(result!.valueSize, equals(80.0));
      expect(result!.unitSize, equals(80.0));
    });

    test('FileLoggerService.stopSession persists remap matrix JSON and clears _matrixFile', () async {
      final Directory tempDir = await Directory.systemTemp.createTemp('ecu_logger_audit_test_');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final FileLoggerService logger = FileLoggerService.instance;
      await logger.startSession(explicitDirectoryPath: tempDir.path);
      expect(logger.isLogging, isTrue);

      final RemapMatrix matrix = RemapMatrix();
      matrix.recordSample(rpm: 4000.0, tps: 30.0, ve: 91.5, isVvaActive: false);

      await logger.stopSession(matrix);
      expect(logger.isLogging, isFalse);

      final List<FileSystemEntity> files = tempDir.listSync();
      final File matrixFile = files.whereType<File>().firstWhere(
        (File f) => f.path.contains('remap_matrix_') && f.path.endsWith('.json'),
      );
      final String firstContent = await matrixFile.readAsString();
      // dynamic required here: jsonDecode returns untyped structure
      final dynamic decoded = jsonDecode(firstContent);
      expect(decoded['low_cam_matrix'][5][5]['count'], equals(1));

      // Mutate matrix and invoke saveRemapMatrix AFTER stopSession: must NOT overwrite closed file
      matrix.recordSample(rpm: 8000.0, tps: 80.0, ve: 99.0, isVvaActive: true);
      await logger.saveRemapMatrix(matrix);
      final String contentAfterStop = await matrixFile.readAsString();
      expect(contentAfterStop, equals(firstContent));
    });

    test('TelemetryEngine cleanly splits CRLF-terminated BleService [SYSTEM] messages before CAN frames',
        () async {
      final TelemetryEngine engine = TelemetryEngine.instance;
      final BleService ble = BleService.instance;
      addTearDown(() async {
        ble.configureTransportForTesting(state: BleConnectionState.disconnected);
      });

      ble.configureTransportForTesting(state: BleConnectionState.connected);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      engine.clearLogs();

      // Emit [SYSTEM]\r\n immediately followed by a 0x770 CAN frame (8000 raw => 2000 RPM, 0x33 => ~20% TPS)
      ble.emitIncomingTextForTesting('[SYSTEM] Starting ELM327 protocol handshake...\r\n');
      ble.emitIncomingTextForTesting('770 08 1F 40 33 00 00 00 00 00\r');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(engine.rollingLogs, contains('[SYSTEM] Starting ELM327 protocol handshake...'));
      expect(engine.rollingLogs, contains('770 08 1F 40 33 00 00 00 00 00'));
      expect(engine.currentData.rpm, closeTo(2000.0, 0.1));
      expect(engine.currentData.tps, closeTo(20.0, 0.5));
    });

    test('BleService.sendCommand clears _pendingCommandCompleter on timeout so next command succeeds',
        () async {
      final BleService ble = BleService.instance;
      final List<String> writtenCommands = <String>[];
      addTearDown(() {
        ble.configureTransportForTesting(state: BleConnectionState.disconnected);
      });

      ble.configureTransportForTesting(
        state: BleConnectionState.connected,
        onWrite: (List<int> bytes) async {
          final String cmd = utf8.decode(bytes);
          writtenCommands.add(cmd);
          if (cmd == '0100\r') {
            // Partial chunk without '>' prompt -> forces timeout
            ble.emitIncomingTextForTesting('SEARCHING...');
          } else if (cmd == '010C\r') {
            Future<void>.microtask(() {
              ble.emitIncomingTextForTesting('41 0C 1F 40\r>');
            });
          }
        },
      );

      final String timedOutResp = await ble.sendCommand(
        '0100',
        timeout: const Duration(milliseconds: 30),
      );
      expect(timedOutResp, equals('SEARCHING...'));
      expect(ble.hasPendingCommandForTesting, isFalse);

      // Late prompt arriving after timeout must be safely ignored
      ble.emitIncomingTextForTesting('NO DATA\r>');
      expect(ble.hasPendingCommandForTesting, isFalse);

      // Next command must succeed cleanly with its own buffer and completer
      final String rpmResp = await ble.sendCommand(
        '010C',
        timeout: const Duration(milliseconds: 200),
      );
      expect(rpmResp, equals('41 0C 1F 40\r>'));
      expect(ble.hasPendingCommandForTesting, isFalse);
      expect(writtenCommands, equals(<String>['0100\r', '010C\r']));
    });

    test('FileLoggerService.stopSession snapshots _matrixFile atomically against concurrent lifecycle save',
        () async {
      final Directory tempDir = await Directory.systemTemp.createTemp('ecu_logger_race_test_');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final FileLoggerService logger = FileLoggerService.instance;
      await logger.startSession(explicitDirectoryPath: tempDir.path);

      final RemapMatrix matrixAtStop = RemapMatrix();
      matrixAtStop.recordSample(rpm: 3000.0, tps: 20.0, ve: 82.0, isVvaActive: false);

      final RemapMatrix lateMutatedMatrix = RemapMatrix();
      lateMutatedMatrix.recordSample(rpm: 9000.0, tps: 90.0, ve: 99.0, isVvaActive: true);

      // Invoke stopSession and concurrently trigger saveRemapMatrix as lifecycle pause would
      await Future.wait(<Future<void>>[
        logger.stopSession(matrixAtStop),
        logger.saveRemapMatrix(lateMutatedMatrix),
      ]);

      final File matrixFile = tempDir
          .listSync()
          .whereType<File>()
          .firstWhere((File f) => f.path.contains('remap_matrix_'));
      final dynamic decoded = jsonDecode(await matrixFile.readAsString());
      expect(decoded['low_cam_matrix'][4][4]['count'], equals(1));
      expect(decoded['high_cam_matrix'][10][9]['count'], equals(0));
    });

    test('DashboardLayoutService disk initialization restores Factory Cockpit, deduplicates legacy JSON, and persists 8-col 80pt layouts',
        () async {
      final Directory tempDir = await Directory.systemTemp.createTemp('ecu_layout_disk_test_');
      final DashboardLayoutService service = DashboardLayoutService.instance;
      addTearDown(() async {
        service.setStorageDirectoryForTesting(null);
        service.resetForTesting();
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      service.setStorageDirectoryForTesting(tempDir);

      // Seed legacy JSON missing default_design and having duplicate default cards + custom 8-col 80pt layout
      final List<Map<String, dynamic>> defaultCardsJson =
          DashboardDesign.createDefault().cards.map((CardConfig c) => c.toJson()).toList();
      final DashboardDesign customWide = DashboardDesign(
        id: 'design_custom_wide',
        name: 'Cockpit Layout 2',
        createdAt: DateTime(2026, 11, 23),
        cards: const <CardConfig>[
          CardConfig(
            metricId: 'rpm',
            colSpan: 8,
            rowSpan: 2,
            titleFontSize: 80.0,
            valueFontSize: 80.0,
            unitFontSize: 80.0,
          ),
          CardConfig(metricId: 'tps', colSpan: 2, rowSpan: 2),
        ],
      );
      final DashboardDesign dupDefault = DashboardDesign(
        id: 'design_dup_default',
        name: 'Default Cockpit',
        createdAt: DateTime(2026, 11, 22),
        cards: defaultCardsJson.map(CardConfig.fromJson).toList(),
      );

      await File('${tempDir.path}/saved_dashboard_layouts.json').writeAsString(
        jsonEncode(<Map<String, dynamic>>[dupDefault.toJson(), customWide.toJson()]),
      );
      await File('${tempDir.path}/active_dashboard_layout.json').writeAsString(
        jsonEncode(dupDefault.toJson()),
      );

      await service.initialize();

      // Factory Cockpit restored at index 0, duplicate removed, custom 8-col 80pt preserved
      expect(service.savedDesigns.length, equals(2));
      expect(service.savedDesigns.first.id, equals(DashboardDesign.defaultDesignId));
      expect(service.savedDesigns.first.name, equals(DashboardDesign.defaultDesignName));
      expect(service.savedDesigns[1].id, equals('design_custom_wide'));
      expect(service.savedDesigns[1].cards.first.colSpan, equals(8));
      expect(service.savedDesigns[1].cards.first.valueFontSize, equals(80.0));
      expect(service.activeDesign.id, equals(DashboardDesign.defaultDesignId));

      // Re-initialize from newly persisted disk files to confirm clean round-trip
      await service.initialize();
      expect(service.savedDesigns.length, equals(2));
      expect(service.savedDesigns[1].cards.first.colSpan, equals(8));
    });

    testWidgets('SavedLayoutsDialog clamps carousel page cleanly when deleting the last of 3 layouts',
        (WidgetTester tester) async {
      final DashboardLayoutService service = DashboardLayoutService.instance;
      service.resetForTesting();
      await service.initialize();

      service.startEditMode();
      service.updateCardConfig(service.displayCards.first.copyWith(colSpan: 4));
      await service.saveEditMode();

      service.startEditMode();
      service.updateCardConfig(service.displayCards.first.copyWith(colSpan: 3, valueFontSize: 70.0));
      await service.saveEditMode();
      expect(service.savedDesigns.length, equals(3));

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () => SavedLayoutsDialog.show(
                  context: context,
                  onPreviewSelected: (_) {},
                ),
                child: const Text('Open Carousel'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Open Carousel'));
      await tester.pumpAndSettle();

      // Swipe to Page 1 then Page 2 (Cockpit Layout 3)
      await tester.drag(find.byType(PageView), const Offset(-350.0, 0.0));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(PageView), const Offset(-350.0, 0.0));
      await tester.pumpAndSettle();

      expect(find.text('Cockpit Layout 3'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.delete_outline_rounded).last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(service.savedDesigns.length, equals(2));
      expect(find.text('Saved Cockpit Layouts'), findsOneWidget);
      expect(find.text('Cockpit Layout 2'), findsOneWidget);
    });

    testWidgets('FontSizeDialog sliders drag smoothly up to 80.0 pt from default values',
        (WidgetTester tester) async {
      ({double titleSize, double valueSize, double unitSize})? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await FontSizeDialog.show(
                    context: context,
                    cardTitle: 'Engine Speed',
                    currentTitleSize: 10.5,
                    currentValueSize: 28.0,
                    currentUnitSize: 9.5,
                  );
                },
                child: const Text('Open Slider Test'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Slider Test'));
      await tester.pumpAndSettle();

      final Finder sliderFinder = find.byType(Slider);
      expect(sliderFinder, findsNWidgets(3));
      for (int idx = 0; idx < 3; idx++) {
        final Rect r = tester.getRect(sliderFinder.at(idx));
        await tester.tapAt(Offset(r.right - 2.0, r.center.dy));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.titleSize, greaterThan(70.0));
      expect(result!.valueSize, greaterThan(70.0));
      expect(result!.unitSize, greaterThan(70.0));
    });

    testWidgets('SavedLayoutsDialog and FontSizeDialog render without overflow on compact landscape (640x320 & 800x360)',
        (WidgetTester tester) async {
      final DashboardLayoutService service = DashboardLayoutService.instance;
      service.resetForTesting();
      await service.initialize();
      service.startEditMode();
      service.updateCardConfig(service.displayCards.first.copyWith(colSpan: 4));
      await service.saveEditMode();

      for (final Size sz in const <Size>[Size(800.0, 360.0), Size(640.0, 320.0), Size(640.0, 270.0)]) {
        tester.view.physicalSize = sz;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (BuildContext context) {
                return Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => SavedLayoutsDialog.show(
                        context: context,
                        onPreviewSelected: (_) {},
                      ),
                      child: const Text('Open Layouts'),
                    ),
                    ElevatedButton(
                      onPressed: () => FontSizeDialog.show(
                        context: context,
                        cardTitle: 'Engine Speed',
                        currentTitleSize: 80.0,
                        currentValueSize: 80.0,
                        currentUnitSize: 80.0,
                      ),
                      child: const Text('Open Font'),
                    ),
                  ],
                );
              },
            ),
          ),
        );
        await tester.tap(find.text('Open Layouts'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'SavedLayoutsDialog overflowed at $sz');
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Font'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'FontSizeDialog overflowed at $sz');
        await tester.tap(find.text('Apply'));
        await tester.pumpAndSettle();
      }
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });

    testWidgets('Vertical-only resize in portrait preserves wider colSpan from tablet/landscape',
        (WidgetTester tester) async {
      final DashboardLayoutService service = DashboardLayoutService.instance;
      service.resetForTesting();
      await service.initialize();

      // Simulate wide-screen 6-col card active on portrait 4-col screen
      service.startEditMode();
      service.updateCardConfig(service.displayCards.first.copyWith(colSpan: 6, rowSpan: 2));
      await service.saveEditMode();

      tester.view.physicalSize = const Size(412.0, 915.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('ENGINE SPEED'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text('ENGINE SPEED'));
      await tester.pump(const Duration(milliseconds: 350));

      final Rect rpmRect = tester.getRect(_cardFinderByLabel('ENGINE SPEED'));
      final TestGesture bottomDrag = await tester.startGesture(rpmRect.bottomCenter);
      await tester.pump();
      await bottomDrag.moveBy(const Offset(0.0, 70.0));
      await tester.pump();
      await bottomDrag.up();
      await tester.pumpAndSettle();

      final CardConfig rpmAfterVertical = DashboardLayoutService.instance.displayCards
          .firstWhere((CardConfig c) => c.metricId == 'rpm');
      expect(rpmAfterVertical.rowSpan, equals(3));
      expect(rpmAfterVertical.colSpan, equals(6));

      await tester.pump(const Duration(seconds: 4));
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4));
    });
  });
}
