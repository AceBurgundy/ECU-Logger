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
/// Provides view-mode flush styling, smooth edit entry scale animation,
/// continuous jiggle animation in Edit Mode, drag-and-drop reordering with reflow preview,
/// active card selection with bright neon yellow border, corner and edge resizing with low friction,
/// and on-card typography customization.
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

  /// Optional currently active metric ID (controlled externally or synchronized).
  final String? activeMetricId;

  /// Callback when the active card selection changes.
  final ValueChanged<String?>? onActiveMetricChanged;

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
  });

  @override
  State<DashboardFlowLayout> createState() => DashboardFlowLayoutState();
}

class DashboardFlowLayoutState extends State<DashboardFlowLayout>
    with SingleTickerProviderStateMixin {
  String? _internalActiveMetricId;
  String? _draggedMetricId;
  int? _hoverDropIndex;

  late final AnimationController _entryAnimationController;
  late final Animation<double> _entryScaleAnimation;

  // Sensitivity thresholds for dragging corners/edges
  double _accumulatedDeltaX = 0.0;
  double _accumulatedDeltaY = 0.0;

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
      duration: const Duration(milliseconds: 250),
      value: widget.isEditMode ? 1.0 : 0.0,
    );
    _entryScaleAnimation = CurvedAnimation(
      parent: _entryAnimationController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(DashboardFlowLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeMetricId != oldWidget.activeMetricId) {
      _internalActiveMetricId = widget.activeMetricId;
    }
    if (widget.isEditMode != oldWidget.isEditMode) {
      if (widget.isEditMode) {
        _entryAnimationController.forward(from: 0.0);
      } else {
        _entryAnimationController.reverse();
        _internalActiveMetricId = null;
        _draggedMetricId = null;
        _hoverDropIndex = null;
      }
    }
  }

  @override
  void dispose() {
    _entryAnimationController.dispose();
    super.dispose();
  }

  void _handleCornerDragUpdate(DragUpdateDetails details, Alignment corner, CardConfig card) {
    _accumulatedDeltaX += details.delta.dx;
    _accumulatedDeltaY += details.delta.dy;

    int newColSpan = card.colSpan;
    int newRowSpan = card.rowSpan;
    const double threshold = 18.0;

    // Horizontal resize logic
    if (corner == Alignment.topRight || corner == Alignment.bottomRight) {
      if (_accumulatedDeltaX > threshold && card.colSpan < 2) {
        newColSpan = 2;
        _accumulatedDeltaX = 0.0;
      } else if (_accumulatedDeltaX < -threshold && card.colSpan > 1) {
        newColSpan = 1;
        _accumulatedDeltaX = 0.0;
      }
    } else if (corner == Alignment.topLeft || corner == Alignment.bottomLeft) {
      if (_accumulatedDeltaX < -threshold && card.colSpan < 2) {
        newColSpan = 2;
        _accumulatedDeltaX = 0.0;
      } else if (_accumulatedDeltaX > threshold && card.colSpan > 1) {
        newColSpan = 1;
        _accumulatedDeltaX = 0.0;
      }
    }

    // Vertical resize logic
    if (corner == Alignment.bottomLeft || corner == Alignment.bottomRight) {
      if (_accumulatedDeltaY > threshold && card.rowSpan < 2) {
        newRowSpan = 2;
        _accumulatedDeltaY = 0.0;
      } else if (_accumulatedDeltaY < -threshold && card.rowSpan > 1) {
        newRowSpan = 1;
        _accumulatedDeltaY = 0.0;
      }
    } else if (corner == Alignment.topLeft || corner == Alignment.topRight) {
      if (_accumulatedDeltaY < -threshold && card.rowSpan < 2) {
        newRowSpan = 2;
        _accumulatedDeltaY = 0.0;
      } else if (_accumulatedDeltaY > threshold && card.rowSpan > 1) {
        newRowSpan = 1;
        _accumulatedDeltaY = 0.0;
      }
    }

    if (newColSpan != card.colSpan || newRowSpan != card.rowSpan) {
      widget.onUpdateCard(card.copyWith(colSpan: newColSpan, rowSpan: newRowSpan));
    }
  }

  void _handleEdgeDragUpdate(DragUpdateDetails details, Alignment edge, CardConfig card) {
    _accumulatedDeltaX += details.delta.dx;
    _accumulatedDeltaY += details.delta.dy;

    int newColSpan = card.colSpan;
    int newRowSpan = card.rowSpan;
    const double threshold = 18.0;

    if (edge == Alignment.centerRight) {
      if (_accumulatedDeltaX > threshold && card.colSpan < 2) {
        newColSpan = 2;
        _accumulatedDeltaX = 0.0;
      } else if (_accumulatedDeltaX < -threshold && card.colSpan > 1) {
        newColSpan = 1;
        _accumulatedDeltaX = 0.0;
      }
    } else if (edge == Alignment.centerLeft) {
      if (_accumulatedDeltaX < -threshold && card.colSpan < 2) {
        newColSpan = 2;
        _accumulatedDeltaX = 0.0;
      } else if (_accumulatedDeltaX > threshold && card.colSpan > 1) {
        newColSpan = 1;
        _accumulatedDeltaX = 0.0;
      }
    } else if (edge == Alignment.bottomCenter) {
      if (_accumulatedDeltaY > threshold && card.rowSpan < 2) {
        newRowSpan = 2;
        _accumulatedDeltaY = 0.0;
      } else if (_accumulatedDeltaY < -threshold && card.rowSpan > 1) {
        newRowSpan = 1;
        _accumulatedDeltaY = 0.0;
      }
    } else if (edge == Alignment.topCenter) {
      if (_accumulatedDeltaY < -threshold && card.rowSpan < 2) {
        newRowSpan = 2;
        _accumulatedDeltaY = 0.0;
      } else if (_accumulatedDeltaY > threshold && card.rowSpan > 1) {
        newRowSpan = 1;
        _accumulatedDeltaY = 0.0;
      }
    }

    if (newColSpan != card.colSpan || newRowSpan != card.rowSpan) {
      widget.onUpdateCard(card.copyWith(colSpan: newColSpan, rowSpan: newRowSpan));
    }
  }

  void _handleDragEnd(DragEndDetails details, Alignment _) {
    _accumulatedDeltaX = 0.0;
    _accumulatedDeltaY = 0.0;
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
          final double gap = widget.isEditMode ? 24.0 : 12.0;
          final double horizontalPadding = widget.isEditMode ? 20.0 : 16.0;
          final double verticalPadding = widget.isEditMode ? 18.0 : 12.0;

          final double availableWidth = constraints.maxWidth - (horizontalPadding * 2);
          final double halfWidth = (availableWidth - gap) / 2.0;
          final double fullWidth = availableWidth;
          const double standardHeight = 108.0;
          final double tallHeight = (standardHeight * 2) + gap;

          // Compute reflow preview order if a card is currently being dragged over another slot
          List<CardConfig> displayCards = widget.cards;
          if (_draggedMetricId != null && _hoverDropIndex != null) {
            final int oldIdx = widget.cards.indexWhere((CardConfig c) => c.metricId == _draggedMetricId);
            if (oldIdx != -1 && oldIdx != _hoverDropIndex && _hoverDropIndex! < widget.cards.length) {
              final List<CardConfig> rearranged = List<CardConfig>.from(widget.cards);
              final CardConfig item = rearranged.removeAt(oldIdx);
              rearranged.insert(_hoverDropIndex!, item);
              displayCards = rearranged;
            }
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(horizontalPadding, verticalPadding, horizontalPadding, 90.0),
            child: Wrap(
              spacing: gap,
              runSpacing: gap,
              children: displayCards.asMap().entries.map((MapEntry<int, CardConfig> entry) {
                final int index = entry.key;
                final CardConfig card = entry.value;
                final TelemetryMetric? metric = TelemetryMetric.findById(card.metricId);
                if (metric == null) return const SizedBox.shrink();

                final double cardW = card.colSpan == 2 ? fullWidth : halfWidth;
                final double cardH = card.rowSpan == 2 ? tallHeight : standardHeight;
                final bool isActive = widget.isEditMode && (currentActiveMetricId == card.metricId);

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
                      _setActiveMetricId(isActive ? null : card.metricId);
                    }
                  },
                  onEditFontSizes: () => openFontSizeDialogForCard(card, metric),
                  onCornerDragUpdate: (DragUpdateDetails details, Alignment corner) {
                    _handleCornerDragUpdate(details, corner, card);
                  },
                  onCornerDragEnd: _handleDragEnd,
                  onEdgeDragUpdate: (DragUpdateDetails details, Alignment edge) {
                    _handleEdgeDragUpdate(details, edge, card);
                  },
                  onEdgeDragEnd: _handleDragEnd,
                );

                if (!widget.isEditMode) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    width: cardW,
                    height: cardH,
                    child: metricCard,
                  );
                }

                // Jiggle and Entry transition during Edit Mode
                final Widget animatedCard = AnimatedBuilder(
                  animation: Listenable.merge([widget.shakeAnimation, _entryAnimationController]),
                  builder: (BuildContext cardContext, Widget? child) {
                    final double sign = (index % 2 == 0) ? 1.0 : -1.0;
                    // Jiggle rotation and translation only fully kicks in as entry transition completes
                    final double jiggleProgress = _entryAnimationController.value;
                    final double rotationAngle = sign * 0.020 * widget.shakeAnimation.value * jiggleProgress;
                    final double translationY = (index % 3 == 0 ? 1.0 : -1.0) * 1.2 * widget.shakeAnimation.value * jiggleProgress;

                    // Smooth entry downscale transition: 1.0 down to edit mode scale (0.88 normal, 0.95 active)
                    final double targetScale = isActive ? 0.95 : 0.88;
                    final double currentScale = 1.0 - ((1.0 - targetScale) * _entryScaleAnimation.value);

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
                );

                // Drag Target for smooth reflow reordering
                return DragTarget<String>(
                  onWillAcceptWithDetails: (DragTargetDetails<String> details) {
                    if (details.data != card.metricId) {
                      setState(() {
                        _hoverDropIndex = index;
                      });
                      return true;
                    }
                    return false;
                  },
                  onLeave: (Object? data) {
                    if (_hoverDropIndex == index) {
                      setState(() {
                        _hoverDropIndex = null;
                      });
                    }
                  },
                  onAcceptWithDetails: (DragTargetDetails<String> details) {
                    final int oldIdx = widget.cards.indexWhere((CardConfig c) => c.metricId == details.data);
                    setState(() {
                      _hoverDropIndex = null;
                      _draggedMetricId = null;
                    });
                    if (oldIdx != -1) {
                      widget.onReorderCards(oldIdx, index);
                    }
                  },
                  builder: (BuildContext dropContext, List<String?> candidateData, List<dynamic> rejectedData) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOutCubic,
                      width: cardW,
                      height: cardH,
                      child: LongPressDraggable<String>(
                        data: card.metricId,
                        onDragStarted: () {
                          setState(() {
                            _draggedMetricId = card.metricId;
                          });
                        },
                        onDragEnd: (DraggableDetails details) {
                          setState(() {
                            _draggedMetricId = null;
                            _hoverDropIndex = null;
                          });
                        },
                        onDraggableCanceled: (Velocity velocity, Offset offset) {
                          setState(() {
                            _draggedMetricId = null;
                            _hoverDropIndex = null;
                          });
                        },
                        feedback: TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          tween: Tween<double>(begin: 0.88, end: 1.05),
                          builder: (BuildContext context, double animatedScale, Widget? child) {
                            return Material(
                              color: Colors.transparent,
                              child: Opacity(
                                opacity: 0.85,
                                child: SizedBox(
                                  width: cardW,
                                  height: cardH,
                                  child: Transform.scale(
                                    scale: animatedScale,
                                    child: metricCard,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        childWhenDragging: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: 0.45,
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
