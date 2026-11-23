// ECU = Electronic Control Unit
// OBD = On-Board Diagnostics
// RPM = Revolutions Per Minute
// TPS = Throttle Position Sensor
// MAP = Manifold Absolute Pressure
// ECT = Engine Coolant Temperature
// VE = Volumetric Efficiency
import 'package:flutter/material.dart';
import '../theme/github_theme.dart';
import '../models/dashboard_layout.dart';
import '../models/telemetry_metric.dart';
import '../services/telemetry_engine.dart';
import 'metric_card.dart';
import 'font_size_dialog.dart';

/// Responsive 2-column reflow flow layout for telemetry cards.
/// Provides view-mode flush styling, continuous jiggle animation in Edit Mode,
/// drag-and-drop reordering, active card selection with bright neon yellow border,
/// corner resizing with overflow reflow, and on-card typography customization.
class DashboardFlowLayout extends StatefulWidget {
  /// Ordered list of card configurations.
  final List<CardConfig> cards;

  /// Current decoded telemetry parameters.
  final TelemetryData telemetryData;

  /// Whether the OBD-II connection is active.
  final bool isConnected;

  /// Whether Edit Mode (Jiggle Mode) is active.
  final bool isEditMode;

  /// Shake animation driving card jiggle in Edit Mode.
  final Animation<double> shakeAnimation;

  /// Callback when Edit Mode is triggered via background long-press.
  final VoidCallback onTriggerEditMode;

  /// Callback when cards are reordered via drag-and-drop.
  final void Function(int oldIndex, int newIndex) onReorderCards;

  /// Callback when a card is updated (e.g. resized or font customized).
  final ValueChanged<CardConfig> onUpdateCard;

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
  });

  @override
  State<DashboardFlowLayout> createState() => _DashboardFlowLayoutState();
}

class _DashboardFlowLayoutState extends State<DashboardFlowLayout> {
  String? _activeMetricId;

  // Sensitivity thresholds for corner dragging
  double _accumulatedDeltaX = 0.0;
  double _accumulatedDeltaY = 0.0;

  void _handleCornerDragUpdate(DragUpdateDetails details, Alignment corner, CardConfig card) {
    _accumulatedDeltaX += details.delta.dx;
    _accumulatedDeltaY += details.delta.dy;

    int newColSpan = card.colSpan;
    int newRowSpan = card.rowSpan;

    // Horizontal resize logic
    if (corner == Alignment.topRight || corner == Alignment.bottomRight) {
      if (_accumulatedDeltaX > 35.0 && card.colSpan < 2) {
        newColSpan = 2;
        _accumulatedDeltaX = 0.0;
      } else if (_accumulatedDeltaX < -35.0 && card.colSpan > 1) {
        newColSpan = 1;
        _accumulatedDeltaX = 0.0;
      }
    } else if (corner == Alignment.topLeft || corner == Alignment.bottomLeft) {
      if (_accumulatedDeltaX < -35.0 && card.colSpan < 2) {
        newColSpan = 2;
        _accumulatedDeltaX = 0.0;
      } else if (_accumulatedDeltaX > 35.0 && card.colSpan > 1) {
        newColSpan = 1;
        _accumulatedDeltaX = 0.0;
      }
    }

    // Vertical resize logic
    if (corner == Alignment.bottomLeft || corner == Alignment.bottomRight) {
      if (_accumulatedDeltaY > 35.0 && card.rowSpan < 2) {
        newRowSpan = 2;
        _accumulatedDeltaY = 0.0;
      } else if (_accumulatedDeltaY < -35.0 && card.rowSpan > 1) {
        newRowSpan = 1;
        _accumulatedDeltaY = 0.0;
      }
    } else if (corner == Alignment.topLeft || corner == Alignment.topRight) {
      if (_accumulatedDeltaY < -35.0 && card.rowSpan < 2) {
        newRowSpan = 2;
        _accumulatedDeltaY = 0.0;
      } else if (_accumulatedDeltaY > 35.0 && card.rowSpan > 1) {
        newRowSpan = 1;
        _accumulatedDeltaY = 0.0;
      }
    }

    if (newColSpan != card.colSpan || newRowSpan != card.rowSpan) {
      widget.onUpdateCard(card.copyWith(colSpan: newColSpan, rowSpan: newRowSpan));
    }
  }

  void _handleCornerDragEnd(DragEndDetails details, Alignment corner) {
    _accumulatedDeltaX = 0.0;
    _accumulatedDeltaY = 0.0;
  }

  Future<void> _openFontSizeDialog(CardConfig card, TelemetryMetric metric) async {
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
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (_activeMetricId != null) {
          setState(() => _activeMetricId = null);
        }
      },
      onLongPress: () {
        if (!widget.isEditMode) {
          widget.onTriggerEditMode();
        }
      },
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // 2-Column setup: in Edit Mode, gap expands significantly so cards shrink down
          // within their 2-column slots, providing wide channels for redesigning.
          final double gap = widget.isEditMode ? 24.0 : 12.0;
          final double horizontalPadding = widget.isEditMode ? 20.0 : 16.0;
          final double verticalPadding = widget.isEditMode ? 18.0 : 12.0;

          // Compute exact available width inside the scroll view accounting for padding
          final double availableWidth = constraints.maxWidth - (horizontalPadding * 2);
          final double halfWidth = (availableWidth - gap) / 2.0;
          final double fullWidth = availableWidth;
          const double standardHeight = 108.0;
          final double tallHeight = (standardHeight * 2) + gap;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(horizontalPadding, verticalPadding, horizontalPadding, 90.0),
            child: Wrap(
              spacing: gap,
              runSpacing: gap,
              children: widget.cards.asMap().entries.map((MapEntry<int, CardConfig> entry) {
                final int index = entry.key;
                final CardConfig card = entry.value;
                final TelemetryMetric? metric = TelemetryMetric.findById(card.metricId);
                if (metric == null) return const SizedBox.shrink();

                final double cardW = card.colSpan == 2 ? fullWidth : halfWidth;
                final double cardH = card.rowSpan == 2 ? tallHeight : standardHeight;
                final bool isActive = widget.isEditMode && (_activeMetricId == card.metricId);

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
                  titleFontSize: card.titleFontSize,
                  valueFontSize: card.valueFontSize,
                  unitFontSize: card.unitFontSize,
                  onTap: () {
                    if (widget.isEditMode) {
                      setState(() {
                        _activeMetricId = isActive ? null : card.metricId;
                      });
                    }
                  },
                  onEditFontSizes: () => _openFontSizeDialog(card, metric),
                  onCornerDragUpdate: (DragUpdateDetails details, Alignment corner) {
                    _handleCornerDragUpdate(details, corner, card);
                  },
                  onCornerDragEnd: _handleCornerDragEnd,
                );

                if (!widget.isEditMode) {
                  return SizedBox(
                    width: cardW,
                    height: cardH,
                    child: metricCard,
                  );
                }

                // Jiggle animation during Edit Mode
                final Widget animatedCard = AnimatedBuilder(
                  animation: widget.shakeAnimation,
                  builder: (BuildContext cardContext, Widget? child) {
                    final double sign = (index % 2 == 0) ? 1.0 : -1.0;
                    final double rotationAngle = sign * 0.020 * widget.shakeAnimation.value;
                    final double translationY = (index % 3 == 0 ? 1.0 : -1.0) * 1.2 * widget.shakeAnimation.value;

                    return Transform.scale(
                      scale: isActive ? 0.95 : 0.88,
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
                );

                // Drag Target for reordering cards
                return DragTarget<String>(
                  onWillAcceptWithDetails: (DragTargetDetails<String> details) => details.data != card.metricId,
                  onAcceptWithDetails: (DragTargetDetails<String> details) {
                    final int oldIdx = widget.cards.indexWhere((CardConfig c) => c.metricId == details.data);
                    if (oldIdx != -1) {
                      widget.onReorderCards(oldIdx, index);
                    }
                  },
                  builder: (BuildContext dropContext, List<String?> candidateData, List<dynamic> rejectedData) {
                    return SizedBox(
                      width: cardW,
                      height: cardH,
                      child: LongPressDraggable<String>(
                        data: card.metricId,
                        feedback: Material(
                          color: Colors.transparent,
                          child: SizedBox(
                            width: cardW,
                            height: cardH,
                            child: Transform.scale(
                              scale: 1.05,
                              child: metricCard,
                            ),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.35,
                          child: Container(
                            decoration: BoxDecoration(
                              color: GitHubTheme.canvasInset,
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(
                                color: const Color(0xFFCCFF00).withValues(alpha: 0.6),
                                width: 2.0,
                              ),
                            ),
                          ),
                        ),
                        child: animatedCard,
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
