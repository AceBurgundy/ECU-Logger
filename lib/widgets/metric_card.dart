import 'package:flutter/material.dart';
import '../theme/github_theme.dart';

class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color? accentColor;
  final bool isHighlight;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.unit = '',
    this.accentColor,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = accentColor ?? GitHubTheme.accent;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GitHubTheme.canvasSubtle,
        borderRadius: BorderRadius.circular(12),
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
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontFamily: GitHubTheme.fontGoogleSans,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: GitHubTheme.fgMuted,
                  letterSpacing: 0.8,
                ),
              ),
              if (unit.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: GitHubTheme.canvasInset,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: GitHubTheme.borderMuted, width: 0.8),
                  ),
                  child: Text(
                    unit,
                    style: const TextStyle(
                      fontFamily: GitHubTheme.fontGoogleSansCode,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: GitHubTheme.fgSubtle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: GitHubTheme.fontGoogleSansCode,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: isHighlight ? effectiveAccent : GitHubTheme.fgDefault,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
