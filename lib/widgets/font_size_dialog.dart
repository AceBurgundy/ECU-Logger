// ECU = Electronic Control Unit
// OBD = On-Board Diagnostics
// RPM = Revolutions Per Minute
// TPS = Throttle Position Sensor
// MAP = Manifold Absolute Pressure
// ECT = Engine Coolant Temperature
import 'package:flutter/material.dart';
import '../theme/github_theme.dart';

/// Modal dialog allowing riders to customize font sizes for the active card's
/// title label, value readout, and engineering unit pill.
class FontSizeDialog extends StatefulWidget {
  /// Current or initial title font size.
  final double currentTitleSize;

  /// Current or initial value readout font size.
  final double currentValueSize;

  /// Current or initial unit badge font size.
  final double currentUnitSize;

  /// Card title name displayed in the dialog header.
  final String cardTitle;

  /// Creates a [FontSizeDialog] instance.
  const FontSizeDialog({
    super.key,
    required this.currentTitleSize,
    required this.currentValueSize,
    required this.currentUnitSize,
    required this.cardTitle,
  });

  /// Static helper to display the dialog and return the updated sizes as a record.
  static Future<({double titleSize, double valueSize, double unitSize})?> show({
    required BuildContext context,
    required String cardTitle,
    required double currentTitleSize,
    required double currentValueSize,
    required double currentUnitSize,
  }) {
    return showDialog<({double titleSize, double valueSize, double unitSize})>(
      context: context,
      builder: (BuildContext dialogContext) => FontSizeDialog(
        cardTitle: cardTitle,
        currentTitleSize: currentTitleSize,
        currentValueSize: currentValueSize,
        currentUnitSize: currentUnitSize,
      ),
    );
  }

  @override
  State<FontSizeDialog> createState() => _FontSizeDialogState();
}

class _FontSizeDialogState extends State<FontSizeDialog> {
  static const double _titleMin = 8.0;
  static const double _valueMin = 18.0;
  static const double _unitMin = 7.0;
  static const double _maxFontSize = 80.0;

  late double _titleSize;
  late double _valueSize;
  late double _unitSize;

  @override
  void initState() {
    super.initState();
    _titleSize = widget.currentTitleSize.clamp(_titleMin, _maxFontSize);
    _valueSize = widget.currentValueSize.clamp(_valueMin, _maxFontSize);
    _unitSize = widget.currentUnitSize.clamp(_unitMin, _maxFontSize);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: GitHubTheme.canvasDefault,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: const BorderSide(color: GitHubTheme.borderDefault),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6.0),
            decoration: BoxDecoration(
              color: const Color(0xFFCCFF00).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: const Icon(
              Icons.format_size_rounded,
              color: Color(0xFFCCFF00),
              size: 20.0,
            ),
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              'Font Sizes: ${widget.cardTitle}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: GitHubTheme.fontCanela,
                fontSize: 17.0,
                fontWeight: FontWeight.w700,
                color: GitHubTheme.fgDefault,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Title Font Size
            _buildSliderRow(
              label: 'Title Label',
              value: _titleSize,
              min: _titleMin,
              max: _maxFontSize,
              onChanged: (double val) => setState(() => _titleSize = val),
            ),
            const Divider(color: GitHubTheme.borderMuted, height: 24.0),

            // 2. Value Font Size
            _buildSliderRow(
              label: 'Numeric Value',
              value: _valueSize,
              min: _valueMin,
              max: _maxFontSize,
              onChanged: (double val) => setState(() => _valueSize = val),
            ),
            const Divider(color: GitHubTheme.borderMuted, height: 24.0),

            // 3. Unit Pill Font Size
            _buildSliderRow(
              label: 'Unit Badge Pill',
              value: _unitSize,
              min: _unitMin,
              max: _maxFontSize,
              onChanged: (double val) => setState(() => _unitSize = val),
            ),

            const SizedBox(height: 16.0),
            // Live Preview Box (overflow-safe up to 80.0 pt across all 3 texts)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: GitHubTheme.canvasSubtle,
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: const Color(0xFFCCFF00), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 56.0),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.cardTitle.toUpperCase(),
                            maxLines: 1,
                            style: TextStyle(
                              fontFamily: GitHubTheme.fontGoogleSans,
                              fontSize: _titleSize,
                              fontWeight: FontWeight.w600,
                              color: GitHubTheme.fgMuted,
                            ),
                          ),
                          const SizedBox(width: 4.0),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: GitHubTheme.canvasInset,
                              borderRadius: BorderRadius.circular(4.0),
                              border: Border.all(color: GitHubTheme.borderMuted, width: 0.8),
                            ),
                            child: Text(
                              'UNIT',
                              style: TextStyle(
                                fontFamily: GitHubTheme.fontGoogleSansCode,
                                fontSize: _unitSize,
                                fontWeight: FontWeight.w500,
                                color: GitHubTheme.fgSubtle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 92.0),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '8888',
                        style: TextStyle(
                          fontFamily: GitHubTheme.fontGoogleSansCode,
                          fontSize: _valueSize,
                          fontWeight: FontWeight.w700,
                          color: GitHubTheme.fgDefault,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _titleSize = 10.5;
              _valueSize = 28.0;
              _unitSize = 9.5;
            });
          },
          child: const Text(
            'Reset Default',
            style: TextStyle(color: GitHubTheme.fgSubtle),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFCCFF00),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          ),
          onPressed: () {
            Navigator.of(context).pop((
              titleSize: _titleSize,
              valueSize: _valueSize,
              unitSize: _unitSize,
            ));
          },
          child: const Text(
            'Apply',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: GitHubTheme.fontGoogleSans,
                fontSize: 13.0,
                fontWeight: FontWeight.w600,
                color: GitHubTheme.fgDefault,
              ),
            ),
            Text(
              '${value.toStringAsFixed(1)} pt',
              style: const TextStyle(
                fontFamily: GitHubTheme.fontGoogleSansCode,
                fontSize: 12.0,
                color: GitHubTheme.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFFCCFF00),
            inactiveTrackColor: GitHubTheme.borderDefault,
            thumbColor: const Color(0xFFCCFF00),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
