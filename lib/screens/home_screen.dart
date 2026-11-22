// ECU = Electronic Control Unit
// FAB = Floating Action Button
// RPM = Revolutions Per Minute
// TPS = Throttle Position Sensor
// MAP = Manifold Absolute Pressure
// VE = Volumetric Efficiency
// ECT = Engine Coolant Temperature
// VVA = Variable Valve Actuation
// BLE = Bluetooth Low Energy
import 'package:flutter/material.dart';
import '../theme/github_theme.dart';
import '../models/telemetry_metric.dart';
import '../services/ble_service.dart';
import '../services/telemetry_engine.dart';
import '../services/file_logger_service.dart';
import '../widgets/metric_card.dart';
import '../widgets/log_drawer.dart';
import '../widgets/bluetooth_dialog.dart';
import '../widgets/lock_overlay.dart';
import '../widgets/toast_overlay.dart';
import '../widgets/metric_selection_sheet.dart';

/// Primary dashboard screen providing the Option 3 layout with dynamic digital readout cards,
/// card wobble edit mode, telemetry channel selector, collapsible console log drawer,
/// pocket touch lock overlay, and status-colored FABs.
class HomeScreen extends StatefulWidget {
  /// Creates the [HomeScreen] widget.
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final BleService _ble = BleService.instance;
  final TelemetryEngine _telemetry = TelemetryEngine.instance;
  final FileLoggerService _fileLogger = FileLoggerService.instance;

  bool _isScreenLocked = false;
  bool _isEditMode = false;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _telemetry.addListener(_onTelemetryUpdate);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );

    _shakeAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _telemetry.removeListener(_onTelemetryUpdate);
    _shakeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Auto-save and flush on app backgrounding or pausing
      _fileLogger.flush();
      _fileLogger.saveRemapMatrix(_telemetry.remapMatrix);
      _telemetry.addLogLine('[SYSTEM] App paused in background. Flushed logs to storage.');
    }
  }

  void _onTelemetryUpdate() {
    if (mounted) setState(() {});
  }

  void _enterEditMode() {
    if (_isEditMode) return;
    setState(() => _isEditMode = true);
    _shakeController.repeat(reverse: true);
    ToastService.show(
      context,
      'Edit Mode active. Drag cards to rearrange or drag to bottom to remove.',
      type: ToastType.info,
    );
  }

  void _exitEditMode() {
    if (!_isEditMode) return;
    setState(() => _isEditMode = false);
    _shakeController.stop();
    _shakeController.reset();
  }

  Future<void> _handleFolderPickerTap() async {
    final String? chosenDirectory = await _fileLogger.pickLogDirectory();
    if (mounted && chosenDirectory != null) {
      ToastService.show(
        context,
        'Storage Folder: $chosenDirectory',
        type: ToastType.success,
      );
      if (_ble.currentState == BleConnectionState.connected) {
        await _fileLogger.startSession(explicitDirectoryPath: chosenDirectory);
      }
    }
  }

  Future<void> _ensureFolderConfiguredBeforeLogging() async {
    if (!_fileLogger.hasConfiguredFolder) {
      ToastService.show(
        context,
        'Please select a storage folder for telemetry logs first.',
        type: ToastType.info,
      );
      final String? chosen = await _fileLogger.pickLogDirectory();
      if (chosen != null && _ble.currentState == BleConnectionState.connected) {
        await _fileLogger.startSession(explicitDirectoryPath: chosen);
      }
    } else {
      if (_ble.currentState == BleConnectionState.connected && !_fileLogger.isLogging) {
        await _fileLogger.startSession();
      }
    }
  }

  Color _getBleFabColor(BleConnectionState state) {
    switch (state) {
      case BleConnectionState.connected:
        return GitHubTheme.successFg;
      case BleConnectionState.scanning:
      case BleConnectionState.connecting:
        return GitHubTheme.warningFg;
      case BleConnectionState.error:
        return GitHubTheme.dangerFg;
      case BleConnectionState.disconnected:
        return GitHubTheme.fgSubtle;
    }
  }

  void _showBluetoothDialog() {
    showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => const BluetoothDialog(),
    ).then((bool? didConnect) {
      if (didConnect == true || _ble.currentState == BleConnectionState.connected) {
        _ensureFolderConfiguredBeforeLogging();
      }
    });
  }

  void _showMetricSelectionSheet() {
    MetricSelectionSheet.show(
      context: context,
      telemetry: _telemetry,
    );
  }

  Widget _buildCardItem({
    required String metricId,
    required int index,
    required TelemetryData data,
    required bool isConnected,
  }) {
    final TelemetryMetric? metric = TelemetryMetric.findById(metricId);
    if (metric == null) return const SizedBox.shrink();

    final String displayValue = metric.valueFormatter(data, isConnected);
    final bool highlighted = metric.isHighlight(data, isConnected);

    final Widget cardWidget = MetricCard(
      label: metric.shortLabel,
      value: displayValue,
      unit: metric.unit,
      accentColor: metric.accentColor,
      isHighlight: highlighted,
      onLongPress: _enterEditMode,
    );

    if (!_isEditMode) {
      return cardWidget;
    }

    // Edit Mode: apply downscale and shaking animation with drag-and-drop
    final Widget animatedCard = AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (BuildContext cardContext, Widget? child) {
        final double sign = (index % 2 == 0) ? 1.0 : -1.0;
        final double rotationAngle = sign * 0.024 * _shakeAnimation.value;
        final double translationY = (index % 3 == 0 ? 1.0 : -1.0) * 1.5 * _shakeAnimation.value;

        return Transform.scale(
          scale: 0.90,
          child: Transform.translate(
            offset: Offset(0.0, translationY),
            child: Transform.rotate(
              angle: rotationAngle,
              child: child,
            ),
          ),
        );
      },
      child: cardWidget,
    );

    return DragTarget<String>(
      onWillAcceptWithDetails: (DragTargetDetails<String> details) => details.data != metricId,
      onAcceptWithDetails: (DragTargetDetails<String> details) {
        final int oldIndex = _telemetry.activeDashboardMetricIds.indexOf(details.data);
        if (oldIndex != -1) {
          _telemetry.reorderDashboardMetrics(oldIndex, index);
        }
      },
      builder: (BuildContext dropContext, List<String?> candidateData, List<dynamic> rejectedData) {
        return Draggable<String>(
          data: metricId,
          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: 160.0,
              height: 110.0,
              child: Transform.scale(
                scale: 1.05,
                child: cardWidget,
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: GitHubTheme.accent.withValues(alpha: 0.5),
                  style: BorderStyle.solid,
                  width: 1.5,
                ),
              ),
            ),
          ),
          child: animatedCard,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final TelemetryData data = _telemetry.currentData;
    final bool isConnected = _ble.currentState == BleConnectionState.connected;
    final List<String> activeIds = _telemetry.activeDashboardMetricIds;

    return PopScope(
      canPop: !_isEditMode && !_isScreenLocked,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        if (_isScreenLocked) {
          setState(() => _isScreenLocked = false);
          return;
        }
        if (_isEditMode) {
          _exitEditMode();
        }
      },
      child: Scaffold(
      backgroundColor: GitHubTheme.canvasDefault,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6.0),
              decoration: BoxDecoration(
                color: GitHubTheme.canvasInset,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: GitHubTheme.borderMuted),
              ),
              child: Icon(
                _isEditMode ? Icons.dashboard_customize_rounded : Icons.speed,
                size: 20.0,
                color: _isEditMode ? GitHubTheme.warningFg : GitHubTheme.accent,
              ),
            ),
            const SizedBox(width: 12.0),
            Text(
              _isEditMode ? 'Edit Dashboard' : 'ECU Logger',
              style: const TextStyle(
                fontFamily: GitHubTheme.fontCanela,
                fontSize: 20.0,
                fontWeight: FontWeight.w700,
                color: GitHubTheme.fgDefault,
              ),
            ),
          ],
        ),
        actions: [
          if (_isEditMode)
            TextButton.icon(
              icon: const Icon(Icons.check, size: 18.0, color: GitHubTheme.successFg),
              label: const Text(
                'Done',
                style: TextStyle(
                  fontFamily: GitHubTheme.fontGoogleSans,
                  fontWeight: FontWeight.w700,
                  color: GitHubTheme.successFg,
                ),
              ),
              onPressed: _exitEditMode,
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.folder_outlined, size: 20.0),
              tooltip: 'Choose Log Storage Folder',
              onPressed: _handleFolderPickerTap,
            ),
            const SizedBox(width: 8.0),
          ],
        ],
      ),
      body: Stack(
        children: [
          // Main Option 3 Minimalist Dashboard
          Column(
            children: [
              // Dynamic Digital Readout Cards Grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12.0,
                      crossAxisSpacing: 12.0,
                      childAspectRatio: 1.35,
                    ),
                    physics: const BouncingScrollPhysics(),
                    itemCount: activeIds.length,
                    itemBuilder: (BuildContext gridContext, int index) {
                      return _buildCardItem(
                        metricId: activeIds[index],
                        index: index,
                        data: data,
                        isConnected: isConnected,
                      );
                    },
                  ),
                ),
              ),

              // Edit Mode Bottom Drag Target: Remove Card
              if (_isEditMode)
                DragTarget<String>(
                  onWillAcceptWithDetails: (DragTargetDetails<String> details) => true,
                  onAcceptWithDetails: (DragTargetDetails<String> details) {
                    final TelemetryMetric? targetMetric = TelemetryMetric.findById(details.data);
                    final String name = targetMetric?.name ?? details.data;
                    if (_telemetry.activeDashboardMetricIds.length <= 1) {
                      ToastService.show(
                        context,
                        'Dashboard must have at least one card.',
                        type: ToastType.warning,
                      );
                      return;
                    }
                    _telemetry.removeDashboardMetric(details.data);
                    ToastService.show(
                      context,
                      'Removed $name from dashboard',
                      type: ToastType.info,
                    );
                  },
                  builder: (BuildContext dropContext, List<String?> candidateData, List<dynamic> rejectedData) {
                    final bool isHovered = candidateData.isNotEmpty;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      decoration: BoxDecoration(
                        color: isHovered
                            ? GitHubTheme.danger.withValues(alpha: 0.25)
                            : GitHubTheme.canvasInset,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: isHovered ? GitHubTheme.dangerFg : GitHubTheme.borderDefault,
                          width: isHovered ? 2.0 : 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            color: isHovered ? GitHubTheme.dangerFg : GitHubTheme.fgMuted,
                            size: 22.0,
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            isHovered
                                ? 'Release to Remove'
                                : 'Drag here to remove from dashboard',
                            style: TextStyle(
                              fontFamily: GitHubTheme.fontGoogleSans,
                              fontSize: 13.0,
                              fontWeight: isHovered ? FontWeight.w700 : FontWeight.w500,
                              color: isHovered ? GitHubTheme.dangerFg : GitHubTheme.fgMuted,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              // Bottom Collapsible Monospace Log Drawer
              LogDrawer(
                logs: _telemetry.rollingLogs,
                onClear: () {
                  _telemetry.clearLogs();
                  ToastService.show(context, 'Console log cleared', type: ToastType.info);
                },
              ),
            ],
          ),

          // Translucent Lock Screen Overlay (pocket touch protection)
          if (_isScreenLocked)
            LockOverlay(
              onUnlock: () {
                setState(() => _isScreenLocked = false);
                ToastService.show(
                  context,
                  'Screen unlocked. Dashboard active.',
                  type: ToastType.success,
                );
              },
            ),
        ],
      ),
      floatingActionButton: _isScreenLocked || _isEditMode
          ? null
          : StreamBuilder<BleConnectionState>(
              stream: _ble.stateStream,
              initialData: _ble.currentState,
              builder: (BuildContext fabContext, AsyncSnapshot<BleConnectionState> snapshot) {
                final BleConnectionState state = snapshot.data ?? BleConnectionState.disconnected;
                final Color fabColor = _getBleFabColor(state);

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // List / Channel Selection FAB
                    FloatingActionButton(
                      heroTag: 'metric_list_fab',
                      mini: true,
                      tooltip: 'Available Telemetry Channels',
                      backgroundColor: GitHubTheme.canvasSubtle,
                      shape: const CircleBorder(
                        side: BorderSide(color: GitHubTheme.borderDefault, width: 1.2),
                      ),
                      onPressed: _showMetricSelectionSheet,
                      child: const Icon(
                        Icons.playlist_add_check_rounded,
                        color: GitHubTheme.fgDefault,
                        size: 20.0,
                      ),
                    ),
                    const SizedBox(width: 10.0),

                    // Lock FAB
                    FloatingActionButton(
                      heroTag: 'lock_fab',
                      mini: true,
                      backgroundColor: GitHubTheme.canvasSubtle,
                      shape: const CircleBorder(
                        side: BorderSide(color: GitHubTheme.borderDefault, width: 1.2),
                      ),
                      onPressed: () {
                        setState(() => _isScreenLocked = true);
                        ToastService.show(
                          context,
                          'Pocket Lock activated. Touch protected.',
                          type: ToastType.info,
                        );
                      },
                      child: const Icon(Icons.lock_outline, color: GitHubTheme.fgDefault, size: 20.0),
                    ),
                    const SizedBox(width: 12.0),

                    // Bluetooth FAB (changes color based on status)
                    FloatingActionButton(
                      heroTag: 'ble_fab',
                      backgroundColor: fabColor,
                      shape: const CircleBorder(),
                      onPressed: _showBluetoothDialog,
                      child: Icon(
                        state == BleConnectionState.connected
                            ? Icons.bluetooth_connected
                            : (state == BleConnectionState.scanning
                                ? Icons.bluetooth_searching
                                : Icons.bluetooth),
                        color: state == BleConnectionState.disconnected
                            ? GitHubTheme.canvasDefault
                            : Colors.white,
                      ),
                    ),
                  ],
                );
              },
            ),
      ),
    );
  }
}
