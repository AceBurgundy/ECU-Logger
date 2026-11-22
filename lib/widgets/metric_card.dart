import 'package:flutter/material.dart';
import '../theme/github_theme.dart';

/// Card widget presenting a single telemetry readout parameter with a label,
/// digital value, and unit badge.
class MetricCard extends StatelessWidget {
  /// Descriptive uppercase metric title (e.g. ENGINE SPEED, MANIFOLD PRESSURE).
  final String label;

  /// Formatted digital readout value string. Defaults to '--' if empty.
  final String value;

  /// Engineering unit badge text (e.g. RPM, %, kPa, °C).
  final String unit;

  /// Optional custom highlight accent color.
  final Color? accentColor;

  /// Whether the card border and glow should be highlighted.
  final bool isHighlight;

  /// Optional callback invoked when the user long-presses the card.
  final VoidCallback? onLongPress;

  /// Creates a [MetricCard] instance.
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.unit = '',
    this.accentColor,
    this.isHighlight = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveAccent = accentColor ?? GitHubTheme.accent;
    final String displayValue = value.isEmpty ? '--' : value;

    return InkWell(
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: GitHubTheme.canvasSubtle,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isHighlight
                ? effectiveAccent.withValues(alpha: 0.7)
                : GitHubTheme.borderDefault,
            width: isHighlight ? 1.5 : 1.0,
          ),
          boxShadow: isHighlight
              ? [
                  BoxShadow(
                    color: effectiveAccent.withValues(alpha: 0.15),
                    blurRadius: 8.0,
                    offset: const Offset(0.0, 2.0),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: GitHubTheme.fontGoogleSans,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: GitHubTheme.fgMuted,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 4.0),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: GitHubTheme.canvasInset,
                      borderRadius: BorderRadius.circular(6.0),
                      border: Border.all(color: GitHubTheme.borderMuted, width: 0.8),
                    ),
                    child: Text(
                      unit,
                      style: const TextStyle(
                        fontFamily: GitHubTheme.fontGoogleSansCode,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: GitHubTheme.fgSubtle,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8.0),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                displayValue,
                style: TextStyle(
                  fontFamily: GitHubTheme.fontGoogleSansCode,
                  fontSize: 28.0,
                  fontWeight: FontWeight.w700,
                  color: isHighlight ? effectiveAccent : GitHubTheme.fgDefault,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
