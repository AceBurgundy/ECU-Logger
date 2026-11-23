// ECU = Electronic Control Unit
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecu_logger/models/dashboard_layout.dart';
import 'package:ecu_logger/screens/home_screen.dart';
import 'package:ecu_logger/services/dashboard_layout_service.dart';
import 'package:ecu_logger/widgets/dashboard_flow_layout.dart';
import 'package:ecu_logger/widgets/metric_card.dart';

double _extractRotationZ(Matrix4 matrix) {
  // For a 2D Z-rotation + uniform scale matrix, atan2(m[1], m[0]) gives angle in radians
  return math.atan2(matrix.storage[1], matrix.storage[0]);
}

double _extractScaleX(Matrix4 matrix) {
  final double a = matrix.storage[0];
  final double b = matrix.storage[1];
  return math.sqrt(a * a + b * b);
}

Finder _cardFinder(String shortLabelUpper) {
  return find.ancestor(
    of: find.text(shortLabelUpper),
    matching: find.byType(MetricCard),
  );
}

double _cardEffectiveRotation(WidgetTester tester, String label) {
  final Finder transforms = find.ancestor(
    of: _cardFinder(label),
    matching: find.byType(Transform),
  );
  double totalAngle = 0.0;
  for (final Element el in transforms.evaluate()) {
    final Transform t = el.widget as Transform;
    totalAngle += _extractRotationZ(t.transform);
  }
  return totalAngle;
}

double _cardEffectiveScale(WidgetTester tester, String label) {
  final Finder transforms = find.ancestor(
    of: _cardFinder(label),
    matching: find.byType(Transform),
  );
  double totalScale = 1.0;
  for (final Element el in transforms.evaluate()) {
    final Transform t = el.widget as Transform;
    totalScale *= _extractScaleX(t.transform);
  }
  return totalScale;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Fluid 4-Column Grid, Resize, Reflow & Animations Tests', () {
    test('Default install layout sets all 6 cards to 2 columns x 2 rows on 4-column grid', () {
      final DashboardDesign def = DashboardDesign.createDefault();
      expect(def.cards.length, equals(6));
      for (final CardConfig card in def.cards) {
        expect(card.colSpan, equals(2), reason: '${card.metricId} must default to 2 columns');
        expect(card.rowSpan, equals(2), reason: '${card.metricId} must default to 2 rows');
      }

      const CardConfig defaultConstructed = CardConfig(metricId: 'volt');
      expect(defaultConstructed.colSpan, equals(2));
      expect(defaultConstructed.rowSpan, equals(2));

      final CardConfig fromEmptyJson = CardConfig.fromJson(<String, dynamic>{'metric_id': 'o2'});
      expect(fromEmptyJson.colSpan, equals(2));
      expect(fromEmptyJson.rowSpan, equals(2));

      final CardConfig clampedJson = CardConfig.fromJson(<String, dynamic>{
        'metric_id': 'rpm',
        'col_span': 9,
        'row_span': 7,
      });
      expect(clampedJson.colSpan, equals(4));
      expect(clampedJson.rowSpan, equals(4));
    });

    test('computeDashboardGridLayout packs 2x2 defaults and mixed 1..4 spans cleanly without overlap', () {
      final DashboardDesign def = DashboardDesign.createDefault();
      final DashboardGridLayout defaultLayout = computeDashboardGridLayout(
        cards: def.cards,
        unitColWidth: 80.0,
        unitRowHeight: 52.0,
        gap: 12.0,
      );

      // 2x2 cards: 2 per row (col 0..1 and col 2..3), 3 visual rows (6 grid rows)
      expect(defaultLayout.rects['rpm']!.left, equals(0.0));
      expect(defaultLayout.rects['rpm']!.top, equals(0.0));
      expect(defaultLayout.rects['rpm']!.width, closeTo(172.0, 0.01));
      expect(defaultLayout.rects['rpm']!.height, closeTo(116.0, 0.01));

      expect(defaultLayout.rects['tps']!.left, closeTo(184.0, 0.01));
      expect(defaultLayout.rects['tps']!.top, equals(0.0));
      expect(defaultLayout.rects['map']!.left, equals(0.0));
      expect(defaultLayout.rects['map']!.top, closeTo(128.0, 0.01));

      // Mixed spans: 2x4 tall card alongside two 2x2 cards
      final DashboardGridLayout mixedLayout = computeDashboardGridLayout(
        cards: const <CardConfig>[
          CardConfig(metricId: 'rpm', colSpan: 2, rowSpan: 4),
          CardConfig(metricId: 'tps', colSpan: 2, rowSpan: 2),
          CardConfig(metricId: 'map', colSpan: 2, rowSpan: 2),
          CardConfig(metricId: 've', colSpan: 4, rowSpan: 1),
        ],
        unitColWidth: 80.0,
        unitRowHeight: 52.0,
        gap: 12.0,
      );

      expect(mixedLayout.rects['rpm']!.top, equals(0.0));
      expect(mixedLayout.rects['tps']!.left, closeTo(184.0, 0.01));
      expect(mixedLayout.rects['tps']!.top, equals(0.0));
      // map neatly stacks at col 2..3, row 2..3 beside bottom half of rpm!
      expect(mixedLayout.rects['map']!.left, closeTo(184.0, 0.01));
      expect(mixedLayout.rects['map']!.top, closeTo(128.0, 0.01));
      // ve spans full 4 cols below rpm
      expect(mixedLayout.rects['ve']!.left, equals(0.0));
      expect(mixedLayout.rects['ve']!.width, closeTo(356.0, 0.01));
      expect(mixedLayout.rects['ve']!.top, closeTo(256.0, 0.01));
    });

    testWidgets('Edit mode does NOT jiggle at rest; jiggles ONLY during drag and stops on drop',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(440.0, 900.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      // Enter Edit Mode via long press
      await tester.longPress(find.text('ENGINE SPEED'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Edit Dashboard'), findsOneWidget);

      // Verify ZERO jiggle when resting in Edit Mode
      expect(_cardEffectiveRotation(tester, 'ENGINE SPEED').abs(), lessThan(0.0001));
      expect(_cardEffectiveRotation(tester, 'THROTTLE (TPS)').abs(), lessThan(0.0001));

      // Now hold and drag ENGINE SPEED to trigger drag-only jiggle
      final Offset rpmCenter = tester.getCenter(_cardFinder('ENGINE SPEED'));
      final TestGesture drag = await tester.startGesture(rpmCenter);
      await tester.pump(const Duration(milliseconds: 300));
      await drag.moveBy(const Offset(40.0, 0.0));
      await tester.pump(const Duration(milliseconds: 120));

      // While actively dragging, remaining cards and lifted card jiggle!
      expect(
        _cardEffectiveRotation(tester, 'THROTTLE (TPS)').abs(),
        greaterThan(0.001),
        reason: 'Cards must jiggle while actively dragging a card',
      );

      // Drop card -> jiggle stops immediately!
      await drag.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        _cardEffectiveRotation(tester, 'THROTTLE (TPS)').abs(),
        lessThan(0.0001),
        reason: 'Jiggle must stop once card is dropped',
      );

      // Clean up toast timer
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('Edge and corner resize follows finger pixel-by-pixel and snaps up to 4x4 on release',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(440.0, 900.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      // Enter Edit Mode & select ENGINE SPEED
      await tester.longPress(find.text('ENGINE SPEED'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text('ENGINE SPEED'));
      await tester.pump(const Duration(milliseconds: 350));

      final Rect initialVisualRect = tester.getRect(_cardFinder('ENGINE SPEED'));
      expect(initialVisualRect.width, lessThan(220.0)); // 2 cols out of 4

      // Grab RIGHT edge and drag +70px without releasing: must track pixel-for-pixel immediately
      final TestGesture rightEdgeGesture = await tester.startGesture(initialVisualRect.centerRight);
      await tester.pump();
      await rightEdgeGesture.moveBy(const Offset(70.0, 0.0));
      await tester.pump();

      final Rect midDragRect = tester.getRect(_cardFinder('ENGINE SPEED'));
      expect(
        midDragRect.right - initialVisualRect.right,
        closeTo(70.0, 3.0),
        reason: 'Right edge must follow finger by the pixel without animation lag',
      );
      expect(
        midDragRect.left,
        closeTo(initialVisualRect.left, 2.0),
        reason: 'Anchored left edge must stay stationary while dragging right edge',
      );

      // Continue dragging past full 4-column width and release -> snaps to 4 columns
      await rightEdgeGesture.moveBy(const Offset(200.0, 0.0));
      await tester.pump();
      await rightEdgeGesture.up();
      await tester.pumpAndSettle();

      final CardConfig rpmAfterWidth = DashboardLayoutService.instance.displayCards
          .firstWhere((CardConfig c) => c.metricId == 'rpm');
      expect(rpmAfterWidth.colSpan, equals(4));

      // Now grab BOTTOM edge of ENGINE SPEED and drag down 150px -> verify real-time height + snap up to 4 rows
      final Rect afterWidthRect = tester.getRect(_cardFinder('ENGINE SPEED'));
      final TestGesture bottomEdgeGesture = await tester.startGesture(afterWidthRect.bottomCenter);
      await tester.pump();
      await bottomEdgeGesture.moveBy(const Offset(0.0, 90.0));
      await tester.pump();

      final Rect midVerticalRect = tester.getRect(_cardFinder('ENGINE SPEED'));
      expect(
        midVerticalRect.bottom - afterWidthRect.bottom,
        closeTo(90.0, 3.0),
        reason: 'Bottom edge must follow finger vertically by the pixel',
      );
      expect(
        midVerticalRect.top,
        closeTo(afterWidthRect.top, 2.0),
        reason: 'Top edge must remain anchored while dragging bottom edge',
      );

      await bottomEdgeGesture.moveBy(const Offset(0.0, 120.0));
      await tester.pump();
      await bottomEdgeGesture.up();
      await tester.pumpAndSettle();

      final CardConfig rpmAfterHeight = DashboardLayoutService.instance.displayCards
          .firstWhere((CardConfig c) => c.metricId == 'rpm');
      expect(rpmAfterHeight.rowSpan, equals(4));

      // Discard edits so singleton layout returns clean for subsequent tests
      await tester.pump(const Duration(seconds: 4));
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Discard'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('Right-side card left-edge drag follows finger leftwards pixel-by-pixel',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(440.0, 900.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('THROTTLE (TPS)'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text('THROTTLE (TPS)'));
      await tester.pump(const Duration(milliseconds: 350));

      final Rect initialTpsRect = tester.getRect(_cardFinder('THROTTLE (TPS)'));
      final TestGesture leftEdgeDrag = await tester.startGesture(initialTpsRect.centerLeft);
      await tester.pump();
      await leftEdgeDrag.moveBy(const Offset(-90.0, 0.0));
      await tester.pump();

      final Rect midTpsRect = tester.getRect(_cardFinder('THROTTLE (TPS)'));
      expect(
        initialTpsRect.left - midTpsRect.left,
        closeTo(90.0, 3.0),
        reason: 'Left edge must track finger leftwards pixel-for-pixel',
      );
      expect(
        midTpsRect.right,
        closeTo(initialTpsRect.right, 2.0),
        reason: 'Right edge must stay anchored when dragging left edge',
      );

      await leftEdgeDrag.up();
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 4));
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Discard'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('Hovering dragged card between/over other cards physically slides them smoothly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(440.0, 900.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('ENGINE SPEED'));
      await tester.pump(const Duration(milliseconds: 350));

      final Offset initialTpsTopLeft = tester.getTopLeft(_cardFinder('THROTTLE (TPS)'));
      final Offset initialRpmCenter = tester.getCenter(_cardFinder('ENGINE SPEED'));
      final Offset tpsCenter = tester.getCenter(_cardFinder('THROTTLE (TPS)'));

      // Hold ENGINE SPEED and drag right over/into THROTTLE (TPS)'s space
      final TestGesture drag = await tester.startGesture(initialRpmCenter);
      await tester.pump(const Duration(milliseconds: 300));
      await drag.moveTo(tpsCenter);
      await tester.pump(); // trigger hover index change
      await tester.pump(const Duration(milliseconds: 110)); // mid-flight of 260ms slide!

      final Offset midSlideTpsTopLeft = tester.getTopLeft(_cardFinder('THROTTLE (TPS)'));
      expect(
        midSlideTpsTopLeft.dx,
        lessThan(initialTpsTopLeft.dx - 10.0),
        reason: 'THROTTLE (TPS) card itself must slide left across screen',
      );
      expect(
        midSlideTpsTopLeft.dx,
        greaterThan(10.0),
        reason: 'THROTTLE (TPS) must animate smoothly through intermediate coordinates rather than teleporting',
      );

      await tester.pump(const Duration(milliseconds: 220));
      final Offset finalSlideTpsTopLeft = tester.getTopLeft(_cardFinder('THROTTLE (TPS)'));
      expect(
        finalSlideTpsTopLeft.dx,
        lessThan(midSlideTpsTopLeft.dx),
        reason: 'THROTTLE (TPS) completes smooth slide into slot 0',
      );

      await drag.up();
      await tester.pumpAndSettle();

      // First two cards are now tps, rpm
      expect(DashboardLayoutService.instance.displayCards[0].metricId, equals('tps'));
      expect(DashboardLayoutService.instance.displayCards[1].metricId, equals('rpm'));

      await tester.pump(const Duration(seconds: 4));
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Discard'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('Checking Save and Canceling Discard smoothly animate cards back to 1.0 scale',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(440.0, 900.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      // 1. Test Save (Check) exit scale animation
      await tester.longPress(find.text('ENGINE SPEED'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(_cardEffectiveScale(tester, 'ENGINE SPEED'), closeTo(0.90, 0.01));

      await tester.pump(const Duration(seconds: 4));
      await tester.tap(find.byIcon(Icons.check_rounded));
      await tester.pump(); // frame 0 of exit
      await tester.pump(const Duration(milliseconds: 100)); // mid exit (280ms total)

      final double midSaveScale = _cardEffectiveScale(tester, 'ENGINE SPEED');
      expect(
        midSaveScale,
        greaterThan(0.91),
        reason: 'Card must begin scaling back up on Save',
      );
      expect(
        midSaveScale,
        lessThan(0.99),
        reason: 'Card must animate smoothly through intermediate scale rather than snapping to 1.0',
      );

      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(seconds: 4));
      expect(_cardEffectiveScale(tester, 'ENGINE SPEED'), closeTo(1.0, 0.005));

      // 2. Test Cancel (Discard) exit scale animation
      await tester.longPress(find.text('ENGINE SPEED'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(_cardEffectiveScale(tester, 'ENGINE SPEED'), closeTo(0.90, 0.01));

      await tester.pump(const Duration(seconds: 4));
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.text('Discard'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final double midCancelScale = _cardEffectiveScale(tester, 'ENGINE SPEED');
      expect(midCancelScale, greaterThan(0.91));
      expect(midCancelScale, lessThan(0.99));

      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(seconds: 4));
      expect(_cardEffectiveScale(tester, 'ENGINE SPEED'), closeTo(1.0, 0.005));
    });

    testWidgets('Bottom-right corner drag tracks both axes pixel-by-pixel and clamps to 4x4 on 412x915 viewport',
        (WidgetTester tester) async {
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

      final Rect initialRect = tester.getRect(_cardFinder('ENGINE SPEED'));
      final TestGesture cornerDrag = await tester.startGesture(initialRect.bottomRight);
      await tester.pump();
      await cornerDrag.moveBy(const Offset(65.0, 55.0));
      await tester.pump();

      final Rect midCornerRect = tester.getRect(_cardFinder('ENGINE SPEED'));
      expect(midCornerRect.right - initialRect.right, closeTo(65.0, 3.0));
      expect(midCornerRect.bottom - initialRect.bottom, closeTo(55.0, 3.0));
      expect(midCornerRect.left, closeTo(initialRect.left, 2.0));
      expect(midCornerRect.top, closeTo(initialRect.top, 2.0));

      // Over-drag well past 4x4 and verify clamp to 4 cols x 4 rows
      await cornerDrag.moveBy(const Offset(300.0, 300.0));
      await tester.pump();
      await cornerDrag.up();
      await tester.pumpAndSettle();

      final CardConfig resizedRpm = DashboardLayoutService.instance.displayCards
          .firstWhere((CardConfig c) => c.metricId == 'rpm');
      expect(resizedRpm.colSpan, equals(4));
      expect(resizedRpm.rowSpan, equals(4));

      await tester.pump(const Duration(seconds: 4));
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Discard'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('Hovering a bottom-row card between two top-row cards slides top-row card away smoothly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412.0, 915.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('MANIFOLD PRESSURE'));
      await tester.pump(const Duration(milliseconds: 350));

      final Offset initialRpmPos = tester.getTopLeft(_cardFinder('ENGINE SPEED'));
      final Offset initialTpsPos = tester.getTopLeft(_cardFinder('THROTTLE (TPS)'));
      final Offset rpmCenter = tester.getCenter(_cardFinder('ENGINE SPEED'));
      final Offset tpsCenter = tester.getCenter(_cardFinder('THROTTLE (TPS)'));
      final Offset mapCenter = tester.getCenter(_cardFinder('MANIFOLD PRESSURE'));

      // Target slightly left of seam between ENGINE SPEED and THROTTLE (TPS) -> BOTH cards shift away!
      final Offset seamLeft = Offset(((rpmCenter.dx + tpsCenter.dx) * 0.5) - 25.0, tpsCenter.dy);

      final TestGesture drag = await tester.startGesture(mapCenter);
      await tester.pump(const Duration(milliseconds: 300));
      await drag.moveTo(seamLeft);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      final Offset midRpmPos = tester.getTopLeft(_cardFinder('ENGINE SPEED'));
      final Offset midTpsPos = tester.getTopLeft(_cardFinder('THROTTLE (TPS)'));
      expect(midRpmPos.dx, greaterThan(initialRpmPos.dx + 10.0),
          reason: 'ENGINE SPEED must physically slide right to open slot 0');
      expect(midTpsPos.dy, greaterThan(initialTpsPos.dy + 10.0),
          reason: 'THROTTLE (TPS) must physically slide down to row 2');

      // Now move slightly right of seam -> ENGINE SPEED slides back left, opening slot 1 right next to it
      final Offset seamRight = Offset(((rpmCenter.dx + tpsCenter.dx) * 0.5) + 30.0, tpsCenter.dy);
      await drag.moveTo(seamRight);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.getTopLeft(_cardFinder('ENGINE SPEED')).dx, closeTo(initialRpmPos.dx, 2.0));

      await drag.up();
      await tester.pumpAndSettle();

      // MANIFOLD PRESSURE is now in slot 1 (between rpm and tps)
      expect(DashboardLayoutService.instance.displayCards[1].metricId, equals('map'));

      await tester.pump(const Duration(seconds: 4));
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Discard'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('Active card scales smoothly from 0.96 to 1.0 on Save & Cancel without dipping to 0.90',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412.0, 915.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('ENGINE SPEED'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text('ENGINE SPEED'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(_cardEffectiveScale(tester, 'ENGINE SPEED'), closeTo(0.96, 0.01));

      await tester.pump(const Duration(seconds: 4));
      await tester.tap(find.byIcon(Icons.check_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));

      final double earlyExitScale = _cardEffectiveScale(tester, 'ENGINE SPEED');
      expect(
        earlyExitScale,
        greaterThanOrEqualTo(0.959),
        reason: 'Active card must scale smoothly from 0.96 upward to 1.0 without dipping to 0.90',
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(seconds: 4));
      expect(_cardEffectiveScale(tester, 'ENGINE SPEED'), closeTo(1.0, 0.005));
    });

    testWidgets('Outer perimeter of topLeft & left handles on row 0 col 0 card captures resize drags',
        (WidgetTester tester) async {
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

      final Rect initialRect = tester.getRect(_cardFinder('ENGINE SPEED'));
      // Touch 8px OUTSIDE the left border of the card (inside the 16px outer margin)
      final Offset outerLeftHandle = Offset(initialRect.left - 8.0, initialRect.center.dy);
      final TestGesture outerDrag = await tester.startGesture(outerLeftHandle);
      await tester.pump();
      await outerDrag.moveBy(const Offset(90.0, 0.0));
      await tester.pump();

      final Rect midOuterRect = tester.getRect(_cardFinder('ENGINE SPEED'));
      expect(
        midOuterRect.left - initialRect.left,
        closeTo(90.0, 4.0),
        reason: 'Outer left handle margin must capture drag and follow finger pixel-by-pixel',
      );
      expect(midOuterRect.right, closeTo(initialRect.right, 2.0));

      await outerDrag.up();
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 4));
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Discard'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('Mixed-size grid: dragging 2x2 card onto right half of 4x2 top card moves it to slot 0',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412.0, 915.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final DashboardLayoutService layoutService = DashboardLayoutService.instance;
      await layoutService.initialize();

      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('ENGINE SPEED'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text('ENGINE SPEED'));
      await tester.pump(const Duration(milliseconds: 350));

      // Resize ENGINE SPEED to 4 cols x 2 rows
      final Rect rpmRect = tester.getRect(_cardFinder('ENGINE SPEED'));
      final TestGesture expandRpm = await tester.startGesture(rpmRect.centerRight);
      await tester.pump();
      await expandRpm.moveBy(const Offset(210.0, 0.0));
      await tester.pump();
      await expandRpm.up();
      await tester.pumpAndSettle();

      expect(layoutService.displayCards.firstWhere((c) => c.metricId == 'rpm').colSpan, equals(4));

      final Rect wideRpmRect = tester.getRect(_cardFinder('ENGINE SPEED'));
      final Offset mapCenter = tester.getCenter(_cardFinder('MANIFOLD PRESSURE'));
      // Hover over the RIGHT half of the 4x2 ENGINE SPEED card
      final Offset rightHalfOfWideTop = Offset(wideRpmRect.left + wideRpmRect.width * 0.78, wideRpmRect.center.dy);

      final TestGesture drag = await tester.startGesture(mapCenter);
      await tester.pump(const Duration(milliseconds: 300));
      await drag.moveTo(rightHalfOfWideTop);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      // ENGINE SPEED must slide down away from row 0!
      expect(
        tester.getTopLeft(_cardFinder('ENGINE SPEED')).dy,
        greaterThan(wideRpmRect.top + 10.0),
        reason: '4x2 top card must slide down when hovering over its right half',
      );

      await drag.up();
      await tester.pumpAndSettle();
      expect(layoutService.displayCards[0].metricId, equals('map'));

      await tester.pump(const Duration(seconds: 4));
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Discard'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('1x1 MetricCard with max font sizes renders with zero RenderFlex overflow',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 84.0,
                height: 52.0,
                child: MetricCard(
                  label: 'MANIFOLD PRESSURE',
                  value: '101.3',
                  unit: 'kPa',
                  isEditMode: true,
                  isActive: true,
                  titleFontSize: 18.0,
                  valueFontSize: 48.0,
                  unitFontSize: 16.0,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
