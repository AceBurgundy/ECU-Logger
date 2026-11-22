// ECU = Electronic Control Unit
// FAB = Floating Action Button
// RPM = Revolutions Per Minute
// TPS = Throttle Position Sensor
// MAP = Manifold Absolute Pressure
// VE = Volumetric Efficiency
// ECT = Engine Coolant Temperature
// VVA = Variable Valve Actuation
import 'package:flutter/material.dart';
import '../theme/github_theme.dart';
import '../services/ble_service.dart';
import '../services/telemetry_engine.dart';
import '../services/file_logger_service.dart';
import '../widgets/metric_card.dart';
import '../widgets/log_drawer.dart';
import '../widgets/bluetooth_dialog.dart';
import '../widgets/lock_overlay.dart';
import '../widgets/toast_overlay.dart';

/// Primary dashboard screen providing the Option 3 layout with 6 digital readout cards,
/// collapsible console log drawer, pocket touch lock overlay, and status-colored FABs.
class HomeScreen extends StatefulWidget {
  /// Creates the [HomeScreen] widget.
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final BleService _ble = BleService.instance;
  final TelemetryEngine _telemetry = TelemetryEngine.instance;
  final FileLoggerService _fileLogger = FileLoggerService.instance;

  bool _isScreenLocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _telemetry.addListener(_onTelemetryUpdate);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _telemetry.removeListener(_onTelemetryUpdate);
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
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => const BluetoothDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TelemetryData data = _telemetry.currentData;

    return Scaffold(
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
              child: const Icon(Icons.speed, size: 20.0, color: GitHubTheme.accent),
            ),
            const SizedBox(width: 12.0),
            const Text(
              'ECU Logger',
              style: TextStyle(
                fontFamily: GitHubTheme.fontCanela,
                fontSize: 20.0,
                fontWeight: FontWeight.w700,
                color: GitHubTheme.fgDefault,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_outlined, size: 20.0),
            tooltip: 'Log Storage Path',
            onPressed: () {
              final String path = _fileLogger.logDirectoryPath ?? 'App Documents / ecu_logs';
              ToastService.show(
                context,
                'Storage Path: $path',
                type: ToastType.info,
              );
            },
          ),
          const SizedBox(width: 8.0),
        ],
      ),
      body: Stack(
        children: [
          // Main Option 3 Minimalist Dashboard
          Column(
            children: [
              // 6 Clean Digital Readouts
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12.0,
                    crossAxisSpacing: 12.0,
                    childAspectRatio: 1.35,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // 1. RPM
                      MetricCard(
                        label: 'Engine Speed',
                        value: data.rpm.toStringAsFixed(0),
                        unit: 'RPM',
                        accentColor: data.rpm >= 7400.0 ? GitHubTheme.warningFg : GitHubTheme.accent,
                        isHighlight: data.rpm >= 7400.0,
                      ),

                      // 2. TPS %
                      MetricCard(
                        label: 'Throttle (TPS)',
                        value: data.tps.toStringAsFixed(1),
                        unit: '%',
                        accentColor: GitHubTheme.accent,
                      ),

                      // 3. MAP kPa
                      MetricCard(
                        label: 'Manifold Pressure',
                        value: data.mapKpa.toStringAsFixed(1),
                        unit: 'kPa',
                        accentColor: GitHubTheme.accent,
                      ),

                      // 4. VE %
                      MetricCard(
                        label: 'Volumetric Eff.',
                        value: data.veCorrected > 0.0
                            ? data.veCorrected.toStringAsFixed(1)
                            : data.veDensity.toStringAsFixed(1),
                        unit: '%',
                        accentColor: GitHubTheme.successFg,
                        isHighlight: true,
                      ),

                      // 5. ECT °C
                      MetricCard(
                        label: 'Coolant Temp',
                        value: data.ectC.toStringAsFixed(1),
                        unit: '°C',
                        accentColor: data.ectC >= 100.0
                            ? GitHubTheme.dangerFg
                            : (data.ectC >= 60.0 ? GitHubTheme.successFg : GitHubTheme.fgMuted),
                      ),

                      // 6. VVA Status
                      MetricCard(
                        label: 'VVA Cam Status',
                        value: data.isVvaActive ? 'ACTIVE' : 'INACTIVE',
                        unit: data.isVvaActive ? 'HIGH-CAM' : 'LOW-CAM',
                        accentColor: data.isVvaActive ? GitHubTheme.warningFg : GitHubTheme.fgMuted,
                        isHighlight: data.isVvaActive,
                      ),
                    ],
                  ),
                ),
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
      floatingActionButton: _isScreenLocked
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
    );
  }
}
