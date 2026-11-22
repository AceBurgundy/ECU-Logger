// ECU = Electronic Control Unit
// OBD = On-Board Diagnostics
// PID = Parameter Identification
import 'package:flutter/material.dart';
import '../theme/github_theme.dart';
import '../models/telemetry_metric.dart';
import '../services/telemetry_engine.dart';

/// Modal bottom sheet allowing the rider to mark or unmark telemetry channels
/// discovered by the decoding algorithm on the motorcycle.
class MetricSelectionSheet extends StatefulWidget {
  /// Set of metric IDs discovered by the algorithm on this vehicle.
  final Set<String>? supportedMetricIds;

  /// Ordered list of metric IDs currently active on the dashboard.
  final List<String>? activeMetricIds;

  /// Callback triggered when a metric's marked status is toggled.
  final void Function(String metricId)? onToggle;

  /// Underlying [TelemetryEngine] provider for real-time channel state.
  final TelemetryEngine? telemetry;

  /// Creates a [MetricSelectionSheet] instance.
  const MetricSelectionSheet({
    super.key,
    this.supportedMetricIds,
    this.activeMetricIds,
    this.onToggle,
    this.telemetry,
  });

  /// Displays the modal bottom sheet for metric selection.
  static Future<void> show({
    required BuildContext context,
    TelemetryEngine? telemetry,
    Set<String>? supportedMetricIds,
    List<String>? activeMetricIds,
    void Function(String metricId)? onToggle,
  }) {
    final TelemetryEngine effectiveEngine = telemetry ?? TelemetryEngine.instance;

    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: GitHubTheme.canvasSubtle,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
        side: BorderSide(color: GitHubTheme.borderDefault, width: 1.0),
      ),
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return MetricSelectionSheet(
          telemetry: effectiveEngine,
          supportedMetricIds: supportedMetricIds,
          activeMetricIds: activeMetricIds,
          onToggle: onToggle,
        );
      },
    );
  }

  @override
  State<MetricSelectionSheet> createState() => _MetricSelectionSheetState();
}

class _MetricSelectionSheetState extends State<MetricSelectionSheet> {
  late List<String> _localActiveMetricIds;

  @override
  void initState() {
    super.initState();
    if (widget.telemetry != null) {
      _localActiveMetricIds = List<String>.from(widget.telemetry!.activeDashboardMetricIds);
      widget.telemetry!.addListener(_handleTelemetryUpdate);
    } else {
      _localActiveMetricIds = List<String>.from(widget.activeMetricIds ?? <String>[]);
    }
  }

  @override
  void dispose() {
    widget.telemetry?.removeListener(_handleTelemetryUpdate);
    super.dispose();
  }

  void _handleTelemetryUpdate() {
    if (mounted && widget.telemetry != null) {
      setState(() {
        _localActiveMetricIds = List<String>.from(widget.telemetry!.activeDashboardMetricIds);
      });
    }
  }

  void _handleToggle(String metricId) {
    if (widget.telemetry != null) {
      widget.telemetry!.toggleMetric(metricId);
    } else {
      setState(() {
        if (_localActiveMetricIds.contains(metricId)) {
          if (_localActiveMetricIds.length > 1) {
            _localActiveMetricIds.remove(metricId);
          }
        } else {
          _localActiveMetricIds.add(metricId);
        }
      });
      widget.onToggle?.call(metricId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Set<String> effectiveSupportedIds = widget.telemetry != null
        ? widget.telemetry!.supportedMetricIds
        : (widget.supportedMetricIds ?? <String>{});

    final List<String> currentActiveIds = widget.telemetry != null
        ? widget.telemetry!.activeDashboardMetricIds
        : _localActiveMetricIds;

    // Filter the master catalog to only metrics supported/discovered on this motorcycle
    final List<TelemetryMetric> availableMetrics = TelemetryMetric.allMetrics
        .where((TelemetryMetric metric) => effectiveSupportedIds.contains(metric.id))
        .toList();

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 36.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: GitHubTheme.borderDefault,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),
            const SizedBox(height: 14.0),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(
                      Icons.format_list_bulleted_rounded,
                      color: GitHubTheme.accent,
                      size: 22.0,
                    ),
                    SizedBox(width: 8.0),
                    Text(
                      'Live Telemetry Channels',
                      style: TextStyle(
                        fontFamily: GitHubTheme.fontCanela,
                        fontSize: 18.0,
                        fontWeight: FontWeight.w600,
                        color: GitHubTheme.fgDefault,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                  decoration: BoxDecoration(
                    color: GitHubTheme.canvasInset,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: GitHubTheme.borderMuted),
                  ),
                  child: Text(
                    '${availableMetrics.length} Found',
                    style: const TextStyle(
                      fontFamily: GitHubTheme.fontGoogleSansCode,
                      fontSize: 11.0,
                      fontWeight: FontWeight.w600,
                      color: GitHubTheme.accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6.0),
            const Text(
              'Mark channels discovered on the motorcycle to show them on the dashboard.',
              style: TextStyle(
                fontFamily: GitHubTheme.fontGoogleSans,
                fontSize: 12.0,
                color: GitHubTheme.fgMuted,
              ),
            ),
            const SizedBox(height: 12.0),
            const Divider(color: GitHubTheme.borderMuted),
            const SizedBox(height: 6.0),

            if (availableMetrics.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                child: Column(
                  children: const [
                    Icon(
                      Icons.search_off_rounded,
                      size: 36.0,
                      color: GitHubTheme.fgSubtle,
                    ),
                    SizedBox(height: 10.0),
                    Text(
                      'No Discovered Telemetry Channels',
                      style: TextStyle(
                        fontFamily: GitHubTheme.fontGoogleSans,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w600,
                        color: GitHubTheme.fgDefault,
                      ),
                    ),
                    SizedBox(height: 6.0),
                    Text(
                      'Connect to the motorcycle OBD2 scanner to discover channels available from the ECU.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: GitHubTheme.fontGoogleSans,
                        fontSize: 12.0,
                        color: GitHubTheme.fgMuted,
                      ),
                    ),
                  ],
                ),
              )
            else
              // Channel List
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: availableMetrics.length,
                  separatorBuilder: (BuildContext separatorContext, int index) =>
                      const Divider(color: GitHubTheme.borderMuted, height: 1.0),
                  itemBuilder: (BuildContext itemContext, int index) {
                    final TelemetryMetric metric = availableMetrics[index];
                    final bool isMarked = currentActiveIds.contains(metric.id);

                    return CheckboxListTile(
                      value: isMarked,
                      activeColor: GitHubTheme.accent,
                      checkColor: Colors.black,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                      title: Row(
                        children: [
                          Text(
                            metric.name,
                            style: TextStyle(
                              fontFamily: GitHubTheme.fontGoogleSans,
                              fontSize: 14.0,
                              fontWeight: isMarked ? FontWeight.w600 : FontWeight.w400,
                              color: isMarked ? GitHubTheme.fgDefault : GitHubTheme.fgMuted,
                            ),
                          ),
                          if (metric.unit.isNotEmpty) ...[
                            const SizedBox(width: 8.0),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: GitHubTheme.canvasInset,
                                borderRadius: BorderRadius.circular(4.0),
                                border: Border.all(color: GitHubTheme.borderMuted),
                              ),
                              child: Text(
                                metric.unit,
                                style: const TextStyle(
                                  fontFamily: GitHubTheme.fontGoogleSansCode,
                                  fontSize: 9.5,
                                  color: GitHubTheme.fgSubtle,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        metric.obdPid,
                        style: const TextStyle(
                          fontFamily: GitHubTheme.fontGoogleSansCode,
                          fontSize: 10.0,
                          color: GitHubTheme.fgSubtle,
                        ),
                      ),
                      onChanged: (bool? checked) {
                        _handleToggle(metric.id);
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 12.0),

            // Done Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GitHubTheme.accentEmphasis,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontFamily: GitHubTheme.fontGoogleSans,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
