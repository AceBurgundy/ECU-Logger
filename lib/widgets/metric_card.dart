// ECU = Electronic Control Unit
// OBD = On-Board Diagnostics
// RPM = Revolutions Per Minute
// TPS = Throttle Position Sensor
// MAP = Manifold Absolute Pressure
// ECT = Engine Coolant Temperature
import 'package:flutter/material.dart';
import '../theme/github_theme.dart';

/// Card widget presenting a single telemetry readout parameter with a label,
/// digital value, and unit badge. Supports both flush View Mode and interactive
/// Edit Mode with active neon border, corner resize handles, and font size triggers.
class MetricCard extends StatelessWidget {
  /// Descriptive uppercase metric title (e.g. ENGINE SPEED, MANIFOLD PRESSURE).
  final String label;

  /// Formatted digital readout value string. Defaults to '00' if empty.
  final String value;

  /// Engineering unit badge text (e.g. RPM, %, kPa, °C).
  final String unit;

  /// Optional custom highlight accent color.
  final Color? accentColor;

  /// Whether the card border and glow should be highlighted.
  final bool isHighlight;

  /// Whether Edit Mode (Jiggle Mode) is currently active.
  final bool isEditMode;

  /// Whether this card is currently selected as active in Edit Mode.
  final bool isActive;

  /// Optional customized font size for the metric title label.
  final double? titleFontSize;

  /// Optional customized font size for the value readout text.
  final double? valueFontSize;

  /// Optional customized font size for the unit pill badge.
  final double? unitFontSize;

  /// Optional callback invoked when the user taps the card.
  final VoidCallback? onTap;

  /// Optional callback invoked when the user long-presses the card.
  final VoidCallback? onLongPress;

  /// Optional callback invoked when the on-card Edit button is tapped.
  final VoidCallback? onEditFontSizes;

  /// Optional callback for dragging corner resize handles.
  final void Function(DragUpdateDetails details, Alignment corner)? onCornerDragUpdate;

  /// Optional callback when a corner resize handle drag completes.
  final void Function(DragEndDetails details, Alignment corner)? onCornerDragEnd;

  /// Creates a [MetricCard] instance.
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.unit = '',
    this.accentColor,
    this.isHighlight = false,
    this.isEditMode = false,
    this.isActive = false,
    this.titleFontSize,
    this.valueFontSize,
    this.unitFontSize,
    this.onTap,
    this.onLongPress,
    this.onEditFontSizes,
    this.onCornerDragUpdate,
    this.onCornerDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveAccent = accentColor ?? GitHubTheme.accent;
    final String displayValue = value.isEmpty ? '00' : value;

    // View Mode: Flush styling (transparent background, no borders, no chrome)
    // Edit Mode: Restored card backgrounds, borders, and shadows
    final Color cardBackground = isEditMode
        ? GitHubTheme.canvasSubtle
        : Colors.transparent;

    final Border border = isEditMode
        ? (isActive
            ? Border.all(color: const Color(0xFFCCFF00), width: 2.5)
            : Border.all(
                color: isHighlight
                    ? effectiveAccent.withValues(alpha: 0.7)
                    : GitHubTheme.borderDefault,
                width: isHighlight ? 1.5 : 1.0,
              ))
        : Border.all(color: Colors.transparent, width: 0.0);

    final List<BoxShadow>? shadows = isEditMode
        ? (isActive
            ? <BoxShadow>[
                BoxShadow(
                  color: const Color(0xFFCCFF00).withValues(alpha: 0.25),
                  blurRadius: 10.0,
                  offset: const Offset(0.0, 2.0),
                ),
              ]
            : (isHighlight
                ? <BoxShadow>[
                    BoxShadow(
                      color: effectiveAccent.withValues(alpha: 0.15),
                      blurRadius: 8.0,
                      offset: const Offset(0.0, 2.0),
                    ),
                  ]
                : null))
        : null;

    final Widget cardBody = Container(
      padding: EdgeInsets.symmetric(
        horizontal: isEditMode ? 12.0 : 8.0,
        vertical: isEditMode ? 10.0 : 6.0,
      ),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12.0),
        border: border,
        boxShadow: shadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header Row: Title and Value-Type Pill tightly beside each other
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        label.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: GitHubTheme.fontGoogleSans,
                          fontSize: titleFontSize ?? 10.5,
                          fontWeight: FontWeight.w600,
                          color: GitHubTheme.fgMuted,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    if (unit.isNotEmpty) ...[
                      const SizedBox(width: 5.0),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: GitHubTheme.canvasInset,
                          borderRadius: BorderRadius.circular(5.0),
                          border: Border.all(color: GitHubTheme.borderMuted, width: 0.8),
                        ),
                        child: Text(
                          unit,
                          style: TextStyle(
                            fontFamily: GitHubTheme.fontGoogleSansCode,
                            fontSize: unitFontSize ?? 9.5,
                            fontWeight: FontWeight.w500,
                            color: GitHubTheme.fgSubtle,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // On-card Edit button (visible only on active card in Edit Mode)
              if (isEditMode && isActive)
                GestureDetector(
                  onTap: onEditFontSizes,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCFF00),
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.format_size_rounded, size: 12.0, color: Colors.black),
                        SizedBox(width: 2.0),
                        Text(
                          'EDIT',
                          style: TextStyle(
                            fontSize: 9.0,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Small gap between title row and value readout (P3.T1 requirement)
          const SizedBox(height: 3.0),

          // Numeric readout value with FittedBox to prevent clipping
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  displayValue,
                  style: TextStyle(
                    fontFamily: GitHubTheme.fontGoogleSansCode,
                    fontSize: valueFontSize ?? 28.0,
                    fontWeight: FontWeight.w700,
                    color: isHighlight ? effectiveAccent : GitHubTheme.fgDefault,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          cardBody,

          // 4 Draggable Corner Handles when selected active in Edit Mode (P3.T4)
          if (isEditMode && isActive) ...[
            _buildCornerHandle(Alignment.topLeft),
            _buildCornerHandle(Alignment.topRight),
            _buildCornerHandle(Alignment.bottomLeft),
            _buildCornerHandle(Alignment.bottomRight),
          ],
        ],
      ),
    );
  }

  Widget _buildCornerHandle(Alignment alignment) {
    double? top;
    double? bottom;
    double? left;
    double? right;

    if (alignment == Alignment.topLeft) {
      top = -6.0;
      left = -6.0;
    } else if (alignment == Alignment.topRight) {
      top = -6.0;
      right = -6.0;
    } else if (alignment == Alignment.bottomLeft) {
      bottom = -6.0;
      left = -6.0;
    } else if (alignment == Alignment.bottomRight) {
      bottom = -6.0;
      right = -6.0;
    }

    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (DragUpdateDetails details) {
          onCornerDragUpdate?.call(details, alignment);
        },
        onPanEnd: (DragEndDetails details) {
          onCornerDragEnd?.call(details, alignment);
        },
        child: Container(
          width: 16.0,
          height: 16.0,
          decoration: BoxDecoration(
            color: const Color(0xFFCCFF00),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 3.0,
                offset: Offset(0.0, 1.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
