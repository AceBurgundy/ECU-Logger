// ECU = Electronic Control Unit
// OBD = On-Board Diagnostics
// RPM = Revolutions Per Minute
// TPS = Throttle Position Sensor
// MAP = Manifold Absolute Pressure
// ECT = Engine Coolant Temperature
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/github_theme.dart';
import '../models/dashboard_layout.dart';
import '../models/telemetry_metric.dart';
import '../services/dashboard_layout_service.dart';
import '../services/telemetry_engine.dart';
import 'dashboard_flow_layout.dart';
import 'metric_card.dart';

/// Modal dialog presenting a horizontal carousel of miniature cockpit layout previews
/// for all persisted designs, providing Preview and (for custom designs) Delete actions.
class SavedLayoutsDialog extends StatefulWidget {
  /// Callback invoked when the user selects a design to preview in frozen state.
  final ValueChanged<DashboardDesign> onPreviewSelected;

  /// Creates a [SavedLayoutsDialog] instance.
  const SavedLayoutsDialog({
    super.key,
    required this.onPreviewSelected,
  });

  /// Displays the dialog.
  static Future<void> show({
    required BuildContext context,
    required ValueChanged<DashboardDesign> onPreviewSelected,
  }) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => SavedLayoutsDialog(
        onPreviewSelected: onPreviewSelected,
      ),
    );
  }

  @override
  State<SavedLayoutsDialog> createState() => _SavedLayoutsDialogState();
}

class _SavedLayoutsDialogState extends State<SavedLayoutsDialog> {
  final DashboardLayoutService _layoutService = DashboardLayoutService.instance;
  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _currentPageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<DashboardDesign> designs = _layoutService.savedDesigns;
    final Size screenSize = MediaQuery.of(context).size;
    final int activeTotalColumns = computeDashboardColumnsForWidth(screenSize.width);
    final double dialogWidth = math.min(420.0, screenSize.width * 0.88);
    final double dialogHeight = math.min(370.0, screenSize.height * 0.62);

    return AlertDialog(
      backgroundColor: GitHubTheme.canvasDefault,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: const BorderSide(color: GitHubTheme.borderDefault),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20.0, 16.0, 12.0, 6.0),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text(
              'Saved Cockpit Layouts',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: GitHubTheme.fontCanela,
                fontSize: 18.0,
                fontWeight: FontWeight.w700,
                color: GitHubTheme.fgDefault,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20.0, color: GitHubTheme.fgMuted),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(10.0, 6.0, 10.0, 14.0),
      content: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: designs.isEmpty
            ? const Center(
                child: Text(
                  'No saved layouts found.',
                  style: TextStyle(color: GitHubTheme.fgMuted),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: designs.length,
                      onPageChanged: (int index) => setState(() => _currentPageIndex = index),
                      itemBuilder: (BuildContext context, int index) {
                        final DashboardDesign design = designs[index];
                        final bool isActiveDesign = design.id == _layoutService.activeDesign.id;
                        final bool canDelete = !design.isDefault;

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 4.0),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: GitHubTheme.canvasSubtle,
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: isActiveDesign
                                  ? GitHubTheme.accent
                                  : GitHubTheme.borderDefault,
                              width: isActiveDesign ? 1.5 : 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Minimal Header
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      design.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: GitHubTheme.fontGoogleSans,
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.w600,
                                        color: GitHubTheme.fgDefault,
                                      ),
                                    ),
                                  ),
                                  if (isActiveDesign)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                                      decoration: BoxDecoration(
                                        color: GitHubTheme.accent.withValues(alpha: 0.16),
                                        borderRadius: BorderRadius.circular(4.0),
                                      ),
                                      child: const Text(
                                        'ACTIVE',
                                        style: TextStyle(
                                          fontSize: 9.0,
                                          fontWeight: FontWeight.w700,
                                          color: GitHubTheme.accent,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10.0),

                              // Real Miniature Cockpit Layout Representation
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: GitHubTheme.canvasDefault,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: _buildMiniatureLayoutPreview(
                                    design: design,
                                    referenceScreenWidth: screenSize.width,
                                    totalColumns: activeTotalColumns,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6.0),

                              // Minimal Icon Actions: Preview (+ Delete only for non-default layouts)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (canDelete) ...[
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: GitHubTheme.dangerFg,
                                        size: 20.0,
                                      ),
                                      tooltip: 'Delete Design',
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(6.0),
                                      onPressed: () async {
                                        await _layoutService.deleteDesign(design.id);
                                        if (mounted && context.mounted) {
                                          setState(() {
                                            if (_currentPageIndex >= _layoutService.savedDesigns.length &&
                                                _layoutService.savedDesigns.isNotEmpty) {
                                              _currentPageIndex = _layoutService.savedDesigns.length - 1;
                                            }
                                          });
                                          if (_layoutService.savedDesigns.length < 2) {
                                            Navigator.of(context).pop();
                                          }
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 6.0),
                                  ],
                                  IconButton(
                                    icon: const Icon(
                                      Icons.visibility_outlined,
                                      color: GitHubTheme.accent,
                                      size: 20.0,
                                    ),
                                    tooltip: 'Preview Layout',
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(6.0),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      widget.onPreviewSelected(design);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Carousel Page Indicator Dots
                  const SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List<Widget>.generate(designs.length, (int dotIndex) {
                      final bool isSelected = dotIndex == _currentPageIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3.0),
                        width: isSelected ? 16.0 : 6.0,
                        height: 6.0,
                        decoration: BoxDecoration(
                          color: isSelected ? GitHubTheme.accent : GitHubTheme.borderMuted,
                          borderRadius: BorderRadius.circular(3.0),
                        ),
                      );
                    }),
                  ),
                ],
              ),
      ),
    );
  }

  /// Renders a proportionally accurate miniature cockpit preview using the actual
  /// grid coordinates, spans, labels, units, and typography of [design].
  Widget _buildMiniatureLayoutPreview({
    required DashboardDesign design,
    required double referenceScreenWidth,
    required int totalColumns,
  }) {
    const double horizontalPadding = 16.0;
    const double gap = 12.0;
    final double refCanvasWidth = math.max(220.0, referenceScreenWidth - (horizontalPadding * 2));
    final double unitColWidth = (refCanvasWidth - ((totalColumns - 1) * gap)) / totalColumns;
    final double unitRowHeight = computeDashboardUnitRowHeight(unitColWidth);

    final DashboardGridLayout layout = computeDashboardGridLayout(
      cards: design.cards,
      unitColWidth: unitColWidth,
      unitRowHeight: unitRowHeight,
      gap: gap,
      totalColumns: totalColumns,
    );

    if (layout.totalHeight <= 0.0 || design.cards.isEmpty) {
      return const Center(
        child: Text(
          'Empty Layout',
          style: TextStyle(fontSize: 11.0, color: GitHubTheme.fgMuted),
        ),
      );
    }

    final TelemetryData emptyTelemetry = TelemetryData();

    return FittedBox(
      fit: BoxFit.contain,
      alignment: Alignment.center,
      child: SizedBox(
        width: refCanvasWidth,
        height: layout.totalHeight,
        child: IgnorePointer(
          child: Stack(
            children: design.cards.map((CardConfig card) {
              final Rect? rect = layout.rects[card.metricId];
              final TelemetryMetric? metric = TelemetryMetric.findById(card.metricId);
              if (rect == null || metric == null) {
                return const SizedBox.shrink();
              }

              return Positioned(
                left: rect.left,
                top: rect.top,
                width: rect.width,
                height: rect.height,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: GitHubTheme.canvasSubtle,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: GitHubTheme.borderMuted,
                      width: 1.0,
                    ),
                  ),
                  child: MetricCard(
                    label: metric.shortLabel,
                    value: metric.valueFormatter(emptyTelemetry, false),
                    unit: metric.unit,
                    accentColor: metric.accentColor,
                    isHighlight: false,
                    isEditMode: false,
                    titleFontSize: card.titleFontSize,
                    valueFontSize: card.valueFontSize,
                    unitFontSize: card.unitFontSize,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
