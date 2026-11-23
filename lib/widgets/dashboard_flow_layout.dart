// ECU = Electronic Control Unit
// OBD = On-Board Diagnostics
// RPM = Revolutions Per Minute
// TPS = Throttle Position Sensor
// MAP = Manifold Absolute Pressure
// ECT = Engine Coolant Temperature
// VE = Volumetric Efficiency
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../theme/github_theme.dart';
import '../models/dashboard_layout.dart';
import '../models/telemetry_metric.dart';
import '../services/telemetry_engine.dart';
import 'metric_card.dart';
import 'font_size_dialog.dart';

/// Computed layout output for a 4-column telemetry card grid.
class DashboardGridLayout {
  /// Mapping of metric ID to its pixel [Rect] inside the grid canvas.
  final Map<String, Rect> rects;

  /// Total pixel height occupied by all rows including inter-row gaps.
  final double totalHeight;

  /// Creates a [DashboardGridLayout].
  const DashboardGridLayout({
    required this.rects,
    required this.totalHeight,
  });
}

/// Computes deterministic order-preserving 2D grid coordinates for cards
/// on a 4-column grid where each card spans 1..4 columns and 1..4 rows.
DashboardGridLayout computeDashboardGridLayout({
  required List<CardConfig> cards,
  required double unitColWidth,
  required double unitRowHeight,
  required double gap,
  int totalColumns = 4,
}) {
  final Map<String, Rect> rects = <String, Rect>{};
  if (cards.isEmpty) {
    return const DashboardGridLayout(rects: <String, Rect>{}, totalHeight: 0.0);
  }

  final List<List<bool>> occupied = <List<bool>>[];
  void ensureRows(int targetRowCount) {
    while (occupied.length < targetRowCount) {
      occupied.add(List<bool>.filled(totalColumns, false));
    }
  }

  bool canFit(int row, int col, int colSpan, int rowSpan) {
    if (col + colSpan > totalColumns) return false;
    ensureRows(row + rowSpan);
    for (int r = row; r < row + rowSpan; r++) {
      for (int c = col; c < col + colSpan; c++) {
        if (occupied[r][c]) return false;
      }
    }
    return true;
  }

  void markOccupied(int row, int col, int colSpan, int rowSpan) {
    ensureRows(row + rowSpan);
    for (int r = row; r < row + rowSpan; r++) {
      for (int c = col; c < col + colSpan; c++) {
        occupied[r][c] = true;
      }
    }
  }

  int cursorRow = 0;
  int cursorCol = 0;
  int maxUsedRow = 0;

  for (final CardConfig card in cards) {
    final int cSpan = card.colSpan.clamp(1, totalColumns);
    final int rSpan = card.rowSpan.clamp(1, 4);

    int placedRow = cursorRow;
    int placedCol = cursorCol;
    bool placed = false;

    for (int r = cursorRow; !placed; r++) {
      final int startCol = (r == cursorRow) ? cursorCol : 0;
      for (int c = startCol; c <= totalColumns - cSpan; c++) {
        if (canFit(r, c, cSpan, rSpan)) {
          placedRow = r;
          placedCol = c;
          placed = true;
          break;
        }
      }
    }

    markOccupied(placedRow, placedCol, cSpan, rSpan);
    if (placedRow + rSpan > maxUsedRow) {
      maxUsedRow = placedRow + rSpan;
    }

    final double left = placedCol * (unitColWidth + gap);
    final double top = placedRow * (unitRowHeight + gap);
    final double width = (cSpan * unitColWidth) + ((cSpan - 1) * gap);
    final double height = (rSpan * unitRowHeight) + ((rSpan - 1) * gap);

    rects[card.metricId] = Rect.fromLTWH(left, top, width, height);

    cursorRow = placedRow;
    cursorCol = placedCol + cSpan;
    if (cursorCol >= totalColumns) {
      cursorRow += 1;
      cursorCol = 0;
    }
  }

  final double totalHeight = maxUsedRow == 0
      ? 0.0
      : (maxUsedRow * unitRowHeight) + ((maxUsedRow - 1) * gap);

  return DashboardGridLayout(rects: rects, totalHeight: totalHeight);
}

/// Responsive 4-column reflow layout for telemetry cards.
/// Features:
/// - Default 2x2 card span on install on a 4-column grid (resizable up to 4x4).
/// - Smooth cubic downscale entry into Edit Mode (without idle jiggle) and smooth scale-back exit.
/// - Drag-only jiggle animation that begins on card hold-drag and stops cleanly on drop.
/// - Physical slide-away reflow via [AnimatedPositioned] with stable keys when hovering over/between cards.
/// - Pixel-accurate 8-point edge & corner resizing that tracks the user's finger 1:1 and snaps on release.
class DashboardFlowLayout extends StatefulWidget {
  /// Ordered list of card configurations.
  final List<CardConfig> cards;

  /// Current decoded telemetry parameters.
  final TelemetryData telemetryData;

  /// Whether the OBD-II connection is active.
  final bool isConnected;

  /// Whether Edit Mode is active.
  final bool isEditMode;

  /// Shake animation driving card jiggle strictly while dragging a card.
  final Animation<double> shakeAnimation;

  /// Callback when Edit Mode is triggered via background or card long-press.
  final VoidCallback onTriggerEditMode;

  /// Callback when cards are reordered via drag-and-drop.
  final void Function(int oldIndex, int newIndex) onReorderCards;

  /// Callback when a card is updated (e.g. resized or font customized).
  final ValueChanged<CardConfig> onUpdateCard;

  /// Optional currently active metric ID (controlled externally or synchronized).
  final String? activeMetricId;

  /// Callback when the active card selection changes.
  final ValueChanged<String?>? onActiveMetricChanged;

  /// Callback notifying parent when a card reorder drag starts or ends (to start/stop jiggle).
  final ValueChanged<bool>? onDraggingChanged;

  /// Creates a [DashboardFlowLayout] instance.
  const DashboardFlowLayout({
    super.key,
    required this.cards,
    required this.telemetryData,
    required this.isConnected,
    required this.isEditMode,
    required this.shakeAnimation,
    required this.onTriggerEditMode,
    required this.onReorderCards,
    required this.onUpdateCard,
    this.activeMetricId,
    this.onActiveMetricChanged,
    this.onDraggingChanged,
  });

  @override
  State<DashboardFlowLayout> createState() => DashboardFlowLayoutState();
}

class DashboardFlowLayoutState extends State<DashboardFlowLayout>
    with TickerProviderStateMixin {
  static const double _editScaleInactive = 0.90;
  static const double _editScaleActive = 0.96;
  static const double _handleHitPad = 14.0;

  final GlobalKey _gridCanvasKey = GlobalKey();

  String? _internalActiveMetricId;
  String? _exitingActiveMetricId;
  String? _draggedMetricId;
  int? _hoverDropIndex;

  // Grab offset from dragged card's top-left corner to pointer down position
  Offset _lastPointerDownGlobal = Offset.zero;
  Offset _dragGrabOffset = Offset.zero;

  late final AnimationController _entryAnimationController;
  late final Animation<double> _entryScaleAnimation;
  late final AnimationController _jiggleFadeController;

  // Real-time interactive drag resizing state
  bool _isTouchingResizeHandle = false;
  String? _resizingMetricId;
  Alignment? _resizeHandle;
  Offset _resizeOriginGlobal = Offset.zero;
  Rect? _resizeBaseRect;
  Rect? _liveResizeRect;
  double _resizeScaleAtStart = 1.0;

  String? get currentActiveMetricId => widget.activeMetricId ?? _internalActiveMetricId;

  void _setActiveMetricId(String? id) {
    if (widget.activeMetricId != null || widget.onActiveMetricChanged != null) {
      widget.onActiveMetricChanged?.call(id);
    }
    setState(() {
      _internalActiveMetricId = id;
    });
  }

  @override
  void initState() {
    super.initState();
    _internalActiveMetricId = widget.activeMetricId;
    _entryAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: widget.isEditMode ? 1.0 : 0.0,
    );
    _entryScaleAnimation = CurvedAnimation(
      parent: _entryAnimationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    _entryAnimationController.addListener(() {
      if (mounted && currentActiveMetricId != null && _resizingMetricId == null) {
        setState(() {});
      }
    });
    _entryAnimationController.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.dismissed && mounted) {
        setState(() {
          _exitingActiveMetricId = null;
        });
      }
    });

    _jiggleFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      value: 0.0,
    );
  }

  @override
  void didUpdateWidget(DashboardFlowLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEditMode != oldWidget.isEditMode) {
      if (widget.isEditMode) {
        _exitingActiveMetricId = null;
        _entryAnimationController.forward();
      } else {
        _exitingActiveMetricId = oldWidget.activeMetricId ?? _internalActiveMetricId;
        _entryAnimationController.reverse();
        if (_draggedMetricId != null) {
          widget.onDraggingChanged?.call(false);
        }
        _jiggleFadeController.value = 0.0;
        _internalActiveMetricId = null;
        _draggedMetricId = null;
        _hoverDropIndex = null;
        _isTouchingResizeHandle = false;
        _resizingMetricId = null;
        _resizeHandle = null;
        _resizeBaseRect = null;
        _liveResizeRect = null;
      }
    } else if (widget.activeMetricId != oldWidget.activeMetricId) {
      _internalActiveMetricId = widget.activeMetricId;
    }
  }

  @override
  void dispose() {
    _entryAnimationController.dispose();
    _jiggleFadeController.dispose();
    super.dispose();
  }

  double _currentScaleForCard(bool isActive) {
    final double targetScale = isActive ? _editScaleActive : _editScaleInactive;
    return 1.0 - ((1.0 - targetScale) * _entryScaleAnimation.value);
  }

  void _handleResizeDown(
    DragDownDetails details,
    Alignment handle,
    CardConfig card,
    Rect baseRect,
    double currentScale,
  ) {
    setState(() {
      _isTouchingResizeHandle = true;
      _resizeHandle = handle;
      _resizeOriginGlobal = details.globalPosition;
      _resizeBaseRect = baseRect;
      _resizeScaleAtStart = currentScale;
    });
  }

  void _handleResizeStart(
    DragStartDetails details,
    Alignment handle,
    CardConfig card,
    Rect baseRect,
    double currentScale,
    double unitColWidth,
    double unitRowHeight,
    double gap,
    double availableWidth,
  ) {
    setState(() {
      _resizingMetricId = card.metricId;
      _resizeHandle = handle;
      _resizeBaseRect ??= baseRect;
      _resizeScaleAtStart = currentScale;
    });
    _applyLiveResizeDelta(
      details.globalPosition - _resizeOriginGlobal,
      unitColWidth,
      unitRowHeight,
      gap,
      availableWidth,
    );
  }

  void _handleResizeUpdate(
    DragUpdateDetails details,
    double unitColWidth,
    double unitRowHeight,
    double gap,
    double availableWidth,
  ) {
    if (_resizingMetricId == null || _resizeBaseRect == null || _resizeHandle == null) {
      return;
    }
    _applyLiveResizeDelta(
      details.globalPosition - _resizeOriginGlobal,
      unitColWidth,
      unitRowHeight,
      gap,
      availableWidth,
    );
  }

  void _applyLiveResizeDelta(
    Offset globalDelta,
    double unitColWidth,
    double unitRowHeight,
    double gap,
    double availableWidth,
  ) {
    final Rect base = _resizeBaseRect!;
    final Alignment handle = _resizeHandle!;
    final double s = _resizeScaleAtStart > 0.0 ? _resizeScaleAtStart : 1.0;

    // Visual rect of the card (accounting for centered scale s)
    final double vBaseLeft = base.left + ((1.0 - s) * 0.5 * base.width);
    final double vBaseTop = base.top + ((1.0 - s) * 0.5 * base.height);
    final double vBaseW = base.width * s;
    final double vBaseH = base.height * s;
    final double vBaseRight = vBaseLeft + vBaseW;
    final double vBaseBottom = vBaseTop + vBaseH;

    final double minVW = unitColWidth * s;
    final double maxVW = availableWidth * s;
    final double minVH = unitRowHeight * s;
    final double maxVH = ((4 * unitRowHeight) + (3 * gap)) * s;

    final bool movesLeft = handle == Alignment.topLeft ||
        handle == Alignment.centerLeft ||
        handle == Alignment.bottomLeft;
    final bool movesRight = handle == Alignment.topRight ||
        handle == Alignment.centerRight ||
        handle == Alignment.bottomRight;
    final bool movesTop = handle == Alignment.topLeft ||
        handle == Alignment.topCenter ||
        handle == Alignment.topRight;
    final bool movesBottom = handle == Alignment.bottomLeft ||
        handle == Alignment.bottomCenter ||
        handle == Alignment.bottomRight;

    double vLeft = vBaseLeft;
    double vRight = vBaseRight;
    double vTop = vBaseTop;
    double vBottom = vBaseBottom;

    if (movesRight) {
      final double upperRight = math.min(vBaseLeft + maxVW, availableWidth + 4.0);
      vRight = (vBaseRight + globalDelta.dx).clamp(vBaseLeft + minVW, math.max(vBaseLeft + minVW, upperRight));
    }
    if (movesLeft) {
      final double lowerLeft = math.max(vBaseRight - maxVW, -4.0);
      vLeft = (vBaseLeft + globalDelta.dx).clamp(math.min(lowerLeft, vBaseRight - minVW), vBaseRight - minVW);
    }
    if (movesBottom) {
      vBottom = (vBaseBottom + globalDelta.dy).clamp(vBaseTop + minVH, vBaseTop + maxVH);
    }
    if (movesTop) {
      final double lowerTop = math.max(vBaseBottom - maxVH, -4.0);
      vTop = (vBaseTop + globalDelta.dy).clamp(math.min(lowerTop, vBaseBottom - minVH), vBaseBottom - minVH);
    }

    // Invert centered scale s so visual edges match (vLeft, vTop, vRight, vBottom) to the exact pixel
    final double liveW = (vRight - vLeft) / s;
    final double liveH = (vBottom - vTop) / s;
    final double liveLeft = vLeft - ((1.0 - s) * 0.5 * liveW);
    final double liveTop = vTop - ((1.0 - s) * 0.5 * liveH);

    setState(() {
      _liveResizeRect = Rect.fromLTWH(liveLeft, liveTop, liveW, liveH);
    });
  }

  void _handleResizeEnd(
    CardConfig card,
    double unitColWidth,
    double unitRowHeight,
    double gap,
  ) {
    final Rect? finalRect = _liveResizeRect;
    setState(() {
      _isTouchingResizeHandle = false;
      _resizingMetricId = null;
      _resizeHandle = null;
      _resizeBaseRect = null;
      _liveResizeRect = null;
    });

    if (finalRect == null) return;

    final int targetColSpan = ((finalRect.width + gap) / (unitColWidth + gap)).round().clamp(1, 4);
    final int targetRowSpan = ((finalRect.height + gap) / (unitRowHeight + gap)).round().clamp(1, 4);

    if (targetColSpan != card.colSpan || targetRowSpan != card.rowSpan) {
      widget.onUpdateCard(card.copyWith(colSpan: targetColSpan, rowSpan: targetRowSpan));
    }
  }

  void _handleResizeCancel() {
    if (_isTouchingResizeHandle || _resizingMetricId != null) {
      setState(() {
        _isTouchingResizeHandle = false;
        _resizingMetricId = null;
        _resizeHandle = null;
        _resizeBaseRect = null;
        _liveResizeRect = null;
      });
    }
  }

  void _updateHoverTargetFromPointer(
    Offset globalPointer,
    double unitColWidth,
    double unitRowHeight,
    double gap,
  ) {
    final String? draggedId = _draggedMetricId;
    if (draggedId == null) return;

    final RenderObject? renderObj = _gridCanvasKey.currentContext?.findRenderObject();
    if (renderObj is! RenderBox) return;

    final Offset pointerLocal = renderObj.globalToLocal(globalPointer);
    final int oldIdx = widget.cards.indexWhere((CardConfig c) => c.metricId == draggedId);
    if (oldIdx == -1) return;

    final CardConfig draggedCard = widget.cards[oldIdx];
    final double cardW = (draggedCard.colSpan.clamp(1, 4) * unitColWidth) +
        ((draggedCard.colSpan.clamp(1, 4) - 1) * gap);
    final double cardH = (draggedCard.rowSpan.clamp(1, 4) * unitRowHeight) +
        ((draggedCard.rowSpan.clamp(1, 4) - 1) * gap);

    final Offset cardTopLeft = pointerLocal - _dragGrabOffset;
    final Offset cardCenter = cardTopLeft + Offset(cardW * 0.5, cardH * 0.5);
    // Blend card center and finger pointer so hovering directly between 2 cards feels natural
    final Offset probe = Offset.lerp(cardCenter, pointerLocal, 0.35)!;

    // Build static candidate slot positions for every possible drop index k (immune to ping-pong)
    final List<CardConfig> otherCards = List<CardConfig>.from(widget.cards)..removeAt(oldIdx);
    final List<Rect> candidateSlots = <Rect>[];
    for (int k = 0; k < widget.cards.length; k++) {
      final List<CardConfig> candidate = List<CardConfig>.from(otherCards)..insert(k, draggedCard);
      final DashboardGridLayout candidateLayout = computeDashboardGridLayout(
        cards: candidate,
        unitColWidth: unitColWidth,
        unitRowHeight: unitRowHeight,
        gap: gap,
      );
      candidateSlots.add(candidateLayout.rects[draggedId]!);
    }

    double slotMetric(Rect slot) {
      final double dx = probe.dx - slot.center.dx;
      final double dy = (probe.dy - slot.center.dy) * 2.2;
      return math.sqrt((dx * dx) + (dy * dy));
    }

    int bestIndex = _hoverDropIndex ?? oldIdx;
    double bestDist = (bestIndex >= 0 && bestIndex < candidateSlots.length)
        ? slotMetric(candidateSlots[bestIndex])
        : double.infinity;

    for (int k = 0; k < candidateSlots.length; k++) {
      final double d = slotMetric(candidateSlots[k]);
      // 12px hysteresis prevents flicker when resting right on a midpoint boundary
      if (k != bestIndex && (d + 12.0) < bestDist) {
        bestDist = d;
        bestIndex = k;
      }
    }

    if (bestIndex != _hoverDropIndex) {
      setState(() {
        _hoverDropIndex = bestIndex;
      });
    }
  }

  void _finishCardDrag({required bool commit}) {
    final String? draggedId = _draggedMetricId;
    final int? targetIdx = _hoverDropIndex;

    if (draggedId == null) return;

    final int oldIdx = widget.cards.indexWhere((CardConfig c) => c.metricId == draggedId);

    setState(() {
      _draggedMetricId = null;
      _hoverDropIndex = null;
    });
    _jiggleFadeController.value = 0.0;
    widget.onDraggingChanged?.call(false);

    if (commit && oldIdx != -1 && targetIdx != null && targetIdx != oldIdx) {
      final int clampedTarget = targetIdx.clamp(0, widget.cards.length - 1);
      widget.onReorderCards(oldIdx, clampedTarget);
    }
  }

  /// Opens font size customization for a given card config.
  Future<void> openFontSizeDialogForCard(CardConfig card, TelemetryMetric metric) async {
    final ({double titleSize, double valueSize, double unitSize})? result =
        await FontSizeDialog.show(
      context: context,
      cardTitle: metric.name,
      currentTitleSize: card.titleFontSize ?? 10.5,
      currentValueSize: card.valueFontSize ?? 28.0,
      currentUnitSize: card.unitFontSize ?? 9.5,
    );

    if (result != null) {
      widget.onUpdateCard(
        card.copyWith(
          titleFontSize: result.titleSize,
          valueFontSize: result.valueSize,
          unitFontSize: result.unitSize,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showEditLayer =
        widget.isEditMode || _entryAnimationController.value > 0.0 || _entryAnimationController.isAnimating;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (currentActiveMetricId != null) {
          _setActiveMetricId(null);
        }
      },
      onLongPress: () {
        if (!widget.isEditMode) {
          widget.onTriggerEditMode();
        }
      },
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double gap = widget.isEditMode ? 14.0 : 12.0;
          const double horizontalPadding = 16.0;
          const double verticalPadding = 14.0;

          // 4-column unit grid calculation
          final double availableWidth = math.max(100.0, constraints.maxWidth - (horizontalPadding * 2));
          final double unitColWidth = (availableWidth - (3 * gap)) / 4.0;
          const double unitRowHeight = 52.0;

          // Compute reflow preview order when dragging a card
          List<CardConfig> displayCards = widget.cards;
          if (_draggedMetricId != null && _hoverDropIndex != null) {
            final int oldIdx = widget.cards.indexWhere((CardConfig c) => c.metricId == _draggedMetricId);
            if (oldIdx != -1 && oldIdx != _hoverDropIndex && _hoverDropIndex! < widget.cards.length) {
              final List<CardConfig> rearranged = List<CardConfig>.from(widget.cards);
              final CardConfig item = rearranged.removeAt(oldIdx);
              rearranged.insert(_hoverDropIndex!.clamp(0, rearranged.length), item);
              displayCards = rearranged;
            }
          }

          final DashboardGridLayout layout = computeDashboardGridLayout(
            cards: displayCards,
            unitColWidth: unitColWidth,
            unitRowHeight: unitRowHeight,
            gap: gap,
          );

          final double minCanvasHeight = math.max(0.0, constraints.maxHeight - verticalPadding - 90.0);
          final double liveBottom = _liveResizeRect?.bottom ?? 0.0;
          final double canvasHeight = math.max(
            minCanvasHeight,
            math.max(layout.totalHeight, liveBottom) + 16.0,
          );

          // Keep child iteration order stable during drags; elevate active card when idle/resizing
          final List<CardConfig> paintOrderCards = List<CardConfig>.from(widget.cards);
          if (_draggedMetricId == null && currentActiveMetricId != null) {
            final int activeIdx = paintOrderCards.indexWhere(
              (CardConfig c) => c.metricId == currentActiveMetricId,
            );
            if (activeIdx != -1) {
              final CardConfig activeCard = paintOrderCards.removeAt(activeIdx);
              paintOrderCards.add(activeCard);
            }
          }

          CardConfig? activeCardForOverlay;
          Rect? activeRectForOverlay;

          final List<Widget> cardChildren = <Widget>[];
          for (int i = 0; i < paintOrderCards.length; i++) {
            final CardConfig card = paintOrderCards[i];
            final TelemetryMetric? metric = TelemetryMetric.findById(card.metricId);
            final Rect? gridRect = layout.rects[card.metricId];
            if (metric == null || gridRect == null) continue;

            final bool isActive = widget.isEditMode && (currentActiveMetricId == card.metricId);
            final bool scaleAsActive = widget.isEditMode
                ? (currentActiveMetricId == card.metricId)
                : (_exitingActiveMetricId == card.metricId);
            final bool isResizingThis = (_resizingMetricId == card.metricId) && _liveResizeRect != null;
            final Rect effectiveRect = isResizingThis ? _liveResizeRect! : gridRect;

            if (isActive && _draggedMetricId == null) {
              activeCardForOverlay = card;
              activeRectForOverlay = effectiveRect;
            }

            final String displayValue = metric.valueFormatter(widget.telemetryData, widget.isConnected);
            final bool isHighlight = metric.isHighlight(widget.telemetryData, widget.isConnected);

            final Widget metricCard = MetricCard(
              label: metric.shortLabel,
              value: displayValue,
              unit: metric.unit,
              accentColor: metric.accentColor,
              isHighlight: isHighlight,
              isEditMode: widget.isEditMode,
              isActive: isActive,
              interactiveHandles: false,
              showHandles: _draggedMetricId == null,
              isResizing: isResizingThis,
              titleFontSize: card.titleFontSize,
              valueFontSize: card.valueFontSize,
              unitFontSize: card.unitFontSize,
              onTap: () {
                if (widget.isEditMode) {
                  _setActiveMetricId(isActive ? null : card.metricId);
                }
              },
              onLongPress: widget.isEditMode ? null : widget.onTriggerEditMode,
              onEditFontSizes: () => openFontSizeDialogForCard(card, metric),
            );

            // Keep AnimatedBuilder mounted throughout both entry and exit scale transitions!
            final Widget cardContent = showEditLayer
                ? AnimatedBuilder(
                    animation: Listenable.merge([
                      widget.shakeAnimation,
                      _entryAnimationController,
                      _jiggleFadeController,
                    ]),
                    builder: (BuildContext cardContext, Widget? child) {
                      final double currentScale = _currentScaleForCard(scaleAsActive);

                      // Jiggle ONLY while actively holding & dragging a card
                      final double jiggleAmount = _jiggleFadeController.value;
                      final double sign = (i % 2 == 0) ? 1.0 : -1.0;
                      final double rotationAngle =
                          sign * 0.020 * widget.shakeAnimation.value * jiggleAmount;
                      final double translationY =
                          (i % 3 == 0 ? 1.0 : -1.0) * 1.2 * widget.shakeAnimation.value * jiggleAmount;

                      return Transform.scale(
                        scale: currentScale,
                        child: Transform.translate(
                          offset: Offset(0.0, translationY),
                          child: Transform.rotate(
                            angle: rotationAngle,
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: metricCard,
                  )
                : metricCard;

            final Widget interactiveCard = widget.isEditMode
                ? Listener(
                    onPointerDown: (PointerDownEvent event) {
                      _lastPointerDownGlobal = event.position;
                    },
                    child: LongPressDraggable<String>(
                      data: card.metricId,
                      delay: const Duration(milliseconds: 240),
                      maxSimultaneousDrags:
                          (_resizingMetricId != null || _isTouchingResizeHandle) ? 0 : 1,
                      onDragStarted: () {
                        final RenderObject? ro = _gridCanvasKey.currentContext?.findRenderObject();
                        Offset grabOffset = Offset(effectiveRect.width * 0.5, effectiveRect.height * 0.5);
                        if (ro is RenderBox) {
                          final Offset localDown = ro.globalToLocal(_lastPointerDownGlobal);
                          grabOffset = localDown - effectiveRect.topLeft;
                        }
                        final int startIndex = widget.cards.indexWhere(
                          (CardConfig c) => c.metricId == card.metricId,
                        );
                        setState(() {
                          _draggedMetricId = card.metricId;
                          _hoverDropIndex = startIndex == -1 ? null : startIndex;
                          _dragGrabOffset = grabOffset;
                        });
                        _jiggleFadeController.forward();
                        widget.onDraggingChanged?.call(true);
                      },
                      onDragUpdate: (DragUpdateDetails details) {
                        _updateHoverTargetFromPointer(
                          details.globalPosition,
                          unitColWidth,
                          unitRowHeight,
                          gap,
                        );
                      },
                      onDragEnd: (DraggableDetails details) {
                        // Commit even if released slightly past canvas edge; _commit handles dedup
                        _finishCardDrag(commit: true);
                      },
                      onDraggableCanceled: (Velocity velocity, Offset offset) {
                        _finishCardDrag(commit: true);
                      },
                      feedback: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOutCubic,
                        tween: Tween<double>(begin: 0.92, end: 1.05),
                        builder: (BuildContext fbContext, double liftScale, Widget? child) {
                          return AnimatedBuilder(
                            animation: Listenable.merge([widget.shakeAnimation, _jiggleFadeController]),
                            builder: (BuildContext jContext, Widget? innerChild) {
                              final double angle =
                                  0.022 * widget.shakeAnimation.value * _jiggleFadeController.value;
                              return Material(
                                color: Colors.transparent,
                                elevation: 12.0,
                                borderRadius: BorderRadius.circular(12.0),
                                child: SizedBox(
                                  width: effectiveRect.width,
                                  height: effectiveRect.height,
                                  child: Transform.scale(
                                    scale: liftScale,
                                    child: Transform.rotate(
                                      angle: angle,
                                      child: MetricCard(
                                        label: metric.shortLabel,
                                        value: displayValue,
                                        unit: metric.unit,
                                        accentColor: metric.accentColor,
                                        isHighlight: isHighlight,
                                        isEditMode: true,
                                        isActive: true,
                                        interactiveHandles: false,
                                        showHandles: false,
                                        titleFontSize: card.titleFontSize,
                                        valueFontSize: card.valueFontSize,
                                        unitFontSize: card.unitFontSize,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      childWhenDragging: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: 0.35,
                        child: Container(
                          decoration: BoxDecoration(
                            color: GitHubTheme.canvasInset,
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: const Color(0xFFCCFF00).withValues(alpha: 0.75),
                              width: 2.0,
                            ),
                          ),
                        ),
                      ),
                      child: cardContent,
                    ),
                  )
                : cardContent;

            cardChildren.add(
              AnimatedPositioned(
                key: ValueKey<String>('card_pos_${card.metricId}'),
                duration: isResizingThis ? Duration.zero : const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: effectiveRect.left,
                top: effectiveRect.top,
                width: effectiveRect.width,
                height: effectiveRect.height,
                child: interactiveCard,
              ),
            );
          }

          // Unclipped expanded 8-point resize overlay on top of the active card
          Widget? resizeOverlay;
          if (widget.isEditMode &&
              activeCardForOverlay != null &&
              activeRectForOverlay != null &&
              _draggedMetricId == null) {
            final CardConfig activeCard = activeCardForOverlay;
            final Rect baseRect = activeRectForOverlay;
            final bool isResizingActive = (_resizingMetricId == activeCard.metricId);
            final double s = isResizingActive ? _resizeScaleAtStart : _currentScaleForCard(true);
            final Rect visualRect = Rect.fromCenter(
              center: baseRect.center,
              width: baseRect.width * s,
              height: baseRect.height * s,
            );

            Widget buildZone({
              required Alignment handle,
              double? left,
              double? right,
              double? top,
              double? bottom,
              double? width,
              double? height,
            }) {
              return Positioned(
                left: left,
                right: right,
                top: top,
                bottom: bottom,
                width: width,
                height: height,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  dragStartBehavior: DragStartBehavior.down,
                  onPanDown: (DragDownDetails d) =>
                      _handleResizeDown(d, handle, activeCard, baseRect, s),
                  onPanStart: (DragStartDetails d) => _handleResizeStart(
                    d,
                    handle,
                    activeCard,
                    baseRect,
                    s,
                    unitColWidth,
                    unitRowHeight,
                    gap,
                    availableWidth,
                  ),
                  onPanUpdate: (DragUpdateDetails d) => _handleResizeUpdate(
                    d,
                    unitColWidth,
                    unitRowHeight,
                    gap,
                    availableWidth,
                  ),
                  onPanEnd: (DragEndDetails d) => _handleResizeEnd(
                    activeCard,
                    unitColWidth,
                    unitRowHeight,
                    gap,
                  ),
                  onPanCancel: _handleResizeCancel,
                  child: const SizedBox.expand(),
                ),
              );
            }

            const double zoneSize = _handleHitPad * 2.0; // 28x28 corner & 28px edge grab zones
            resizeOverlay = AnimatedPositioned(
              key: ValueKey<String>('resize_overlay_${activeCard.metricId}'),
              duration: isResizingActive ? Duration.zero : const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              left: horizontalPadding + visualRect.left - _handleHitPad,
              top: verticalPadding + visualRect.top - _handleHitPad,
              width: visualRect.width + zoneSize,
              height: visualRect.height + zoneSize,
              child: Stack(
                children: [
                  // Edge hit strips (between corners)
                  buildZone(
                    handle: Alignment.topCenter,
                    left: zoneSize,
                    right: zoneSize,
                    top: 0.0,
                    height: zoneSize,
                  ),
                  buildZone(
                    handle: Alignment.bottomCenter,
                    left: zoneSize,
                    right: zoneSize,
                    bottom: 0.0,
                    height: zoneSize,
                  ),
                  buildZone(
                    handle: Alignment.centerLeft,
                    top: zoneSize,
                    bottom: zoneSize,
                    left: 0.0,
                    width: zoneSize,
                  ),
                  buildZone(
                    handle: Alignment.centerRight,
                    top: zoneSize,
                    bottom: zoneSize,
                    right: 0.0,
                    width: zoneSize,
                  ),
                  // Corner hit boxes (centered right on the visual corners)
                  buildZone(
                    handle: Alignment.topLeft,
                    left: 0.0,
                    top: 0.0,
                    width: zoneSize,
                    height: zoneSize,
                  ),
                  buildZone(
                    handle: Alignment.topRight,
                    right: 0.0,
                    top: 0.0,
                    width: zoneSize,
                    height: zoneSize,
                  ),
                  buildZone(
                    handle: Alignment.bottomLeft,
                    left: 0.0,
                    bottom: 0.0,
                    width: zoneSize,
                    height: zoneSize,
                  ),
                  buildZone(
                    handle: Alignment.bottomRight,
                    right: 0.0,
                    bottom: 0.0,
                    width: zoneSize,
                    height: zoneSize,
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            physics: (_isTouchingResizeHandle || _resizingMetricId != null || _draggedMetricId != null)
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            child: DragTarget<String>(
              onWillAcceptWithDetails: (_) => true,
              onAcceptWithDetails: (DragTargetDetails<String> details) {
                _finishCardDrag(commit: true);
              },
              builder: (BuildContext dropCtx, List<String?> candidateData, List<dynamic> rejectedData) {
                return SizedBox(
                  width: constraints.maxWidth,
                  height: verticalPadding + canvasHeight + 90.0,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: horizontalPadding,
                        top: verticalPadding,
                        width: availableWidth,
                        height: canvasHeight,
                        child: SizedBox(
                          key: _gridCanvasKey,
                          width: availableWidth,
                          height: canvasHeight,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: cardChildren,
                          ),
                        ),
                      ),
                      if (resizeOverlay != null) resizeOverlay,
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
