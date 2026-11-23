// ECU = Electronic Control Unit
// OBD = On-Board Diagnostics
// RPM = Revolutions Per Minute
// TPS = Throttle Position Sensor
// MAP = Manifold Absolute Pressure
// ECT = Engine Coolant Temperature
import 'package:flutter/material.dart';
import '../theme/github_theme.dart';
import '../models/dashboard_layout.dart';
import '../services/dashboard_layout_service.dart';

/// Modal dialog presenting a horizontal carousel of wireframe skeleton previews
/// for all persisted cockpit designs, providing icon-only Delete and Preview actions.
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
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<DashboardDesign> designs = _layoutService.savedDesigns;

    return AlertDialog(
      backgroundColor: GitHubTheme.canvasDefault,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: const BorderSide(color: GitHubTheme.borderDefault),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20.0, 18.0, 20.0, 10.0),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6.0),
                decoration: BoxDecoration(
                  color: GitHubTheme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  color: GitHubTheme.accent,
                  size: 20.0,
                ),
              ),
              const SizedBox(width: 10.0),
              const Text(
                'Saved Cockpit Layouts',
                style: TextStyle(
                  fontFamily: GitHubTheme.fontCanela,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w700,
                  color: GitHubTheme.fgDefault,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20.0, color: GitHubTheme.fgMuted),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      content: SizedBox(
        width: 340.0,
        height: 380.0,
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

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: GitHubTheme.canvasSubtle,
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: isActiveDesign
                                  ? GitHubTheme.accent
                                  : GitHubTheme.borderDefault,
                              width: isActiveDesign ? 1.8 : 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Design Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      design.name,
                                      style: const TextStyle(
                                        fontFamily: GitHubTheme.fontGoogleSans,
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.w700,
                                        color: GitHubTheme.fgDefault,
                                      ),
                                    ),
                                  ),
                                  if (isActiveDesign)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                                      decoration: BoxDecoration(
                                        color: GitHubTheme.accent.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4.0),
                                      ),
                                      child: const Text(
                                        'ACTIVE',
                                        style: TextStyle(
                                          fontSize: 9.0,
                                          fontWeight: FontWeight.w800,
                                          color: GitHubTheme.accent,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8.0),

                              // Wireframe Skeleton Representation
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: GitHubTheme.canvasDefault,
                                    borderRadius: BorderRadius.circular(8.0),
                                    border: Border.all(color: GitHubTheme.borderMuted),
                                  ),
                                  child: _buildWireframeSkeleton(design),
                                ),
                              ),
                              const SizedBox(height: 10.0),

                              // Icon-only Action Buttons: Delete & Preview
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // Delete Button
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: GitHubTheme.dangerFg,
                                      size: 20.0,
                                    ),
                                    tooltip: 'Delete Design',
                                    onPressed: () async {
                                      await _layoutService.deleteDesign(design.id);
                                      if (mounted && context.mounted) {
                                        setState(() {});
                                        if (_layoutService.savedDesigns.length < 2) {
                                          Navigator.of(context).pop();
                                        }
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8.0),

                                  // Preview Button
                                  IconButton(
                                    icon: const Icon(
                                      Icons.visibility_outlined,
                                      color: GitHubTheme.accent,
                                      size: 20.0,
                                    ),
                                    tooltip: 'Preview Layout',
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
                    children: List.generate(designs.length, (int dotIndex) {
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

  /// Builds a miniature wireframe skeleton layout of cards inside the carousel item.
  Widget _buildWireframeSkeleton(DashboardDesign design) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double gridWidth = constraints.maxWidth;
        const double gap = 4.0;
        final double halfWidth = (gridWidth - gap) / 2;

        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Wrap(
            spacing: gap,
            runSpacing: gap,
            children: design.cards.map((CardConfig card) {
              final double cardW = card.colSpan == 2 ? gridWidth : halfWidth;
              final double cardH = card.rowSpan == 2 ? 52.0 : 26.0;

              return Container(
                width: cardW,
                height: cardH,
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: GitHubTheme.canvasInset,
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(
                    color: GitHubTheme.borderDefault,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4.0,
                      height: 4.0,
                      decoration: const BoxDecoration(
                        color: GitHubTheme.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4.0),
                    Expanded(
                      child: Text(
                        card.metricId.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w600,
                          color: GitHubTheme.fgSubtle,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
