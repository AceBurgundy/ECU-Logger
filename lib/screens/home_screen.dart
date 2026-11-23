// ECU = Electronic Control Unit
// FAB = Floating Action Button
// RPM = Revolutions Per Minute
// TPS = Throttle Position Sensor
// MAP = Manifold Absolute Pressure
// VE = Volumetric Efficiency
// ECT = Engine Coolant Temperature
// VVA = Variable Valve Actuation
// BLE = Bluetooth Low Energy
import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/github_theme.dart';
import '../models/dashboard_layout.dart';
import '../models/telemetry_metric.dart';
import '../services/ble_service.dart';
import '../services/telemetry_engine.dart';
import '../services/file_logger_service.dart';
import '../services/dashboard_layout_service.dart';
import '../widgets/log_drawer.dart';
import '../widgets/bluetooth_dialog.dart';
import '../widgets/lock_overlay.dart';
import '../widgets/toast_overlay.dart';
import '../widgets/metric_selection_sheet.dart';
import '../widgets/dashboard_flow_layout.dart';
import '../widgets/saved_layouts_dialog.dart';
import '../widgets/font_size_dialog.dart';

/// Primary dashboard screen providing flush digital readouts, interactive Edit Mode,
/// 2-column reflow layout with corner resizing, typography dialogs, saved layouts carousel,
/// and conditional OBD-II session controls.
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
  final DashboardLayoutService _layoutService = DashboardLayoutService.instance;

  bool _isScreenLocked = false;
  bool _isEditMode = false;
  String? _activeMetricId;
  StreamSubscription<BleConnectionState>? _bleStateSubscription;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _telemetry.addListener(_onStateUpdate);
    _layoutService.addListener(_onStateUpdate);

    _bleStateSubscription = _ble.stateStream.listen((BleConnectionState state) {
      if (mounted) setState(() {});
    });

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );

    _shakeAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );

    _layoutService.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _telemetry.removeListener(_onStateUpdate);
    _layoutService.removeListener(_onStateUpdate);
    _bleStateSubscription?.cancel();
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

  void _onStateUpdate() {
    if (mounted) setState(() {});
  }

  void _enterEditMode() {
    if (_isEditMode || _layoutService.isFreezePreview) return;
    setState(() => _isEditMode = true);
    _layoutService.startEditMode();
    // Do NOT jiggle on Edit Mode entry; jiggle runs only while holding & dragging a card.
    _shakeController.stop();
    _shakeController.reset();
    ToastService.show(
      context,
      'Edit Mode active. Tap a card to resize, or hold & drag to reorder.',
      type: ToastType.info,
    );
  }

  Future<void> _handleCancelEditPrompt() async {
    final bool? shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: GitHubTheme.canvasDefault,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
            side: const BorderSide(color: GitHubTheme.borderDefault),
          ),
          title: const Text(
            'Discard Changes?',
            style: TextStyle(
              fontFamily: GitHubTheme.fontCanela,
              fontSize: 18.0,
              fontWeight: FontWeight.w700,
              color: GitHubTheme.fgDefault,
            ),
          ),
          content: const Text(
            'Any unsaved modifications to the dashboard layout will be discarded.',
            style: TextStyle(
              fontFamily: GitHubTheme.fontGoogleSans,
              fontSize: 14.0,
              color: GitHubTheme.fgMuted,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep Editing', style: TextStyle(color: GitHubTheme.fgSubtle)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GitHubTheme.dangerFg,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Discard', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );

    if (shouldDiscard == true && mounted) {
      _shakeController.stop();
      _layoutService.cancelEditMode();
      setState(() {
        _isEditMode = false;
        _activeMetricId = null;
      });
      // Allow the reverse scale animation in DashboardFlowLayout to play smoothly
      await Future<void>.delayed(const Duration(milliseconds: 300));
      _shakeController.reset();
      if (mounted) {
        ToastService.show(
          context,
          'Layout changes discarded.',
          type: ToastType.info,
        );
      }
    }
  }

  Future<void> _handleSaveEditMode() async {
    _shakeController.stop();
    await _layoutService.saveEditMode();
    setState(() {
      _isEditMode = false;
      _activeMetricId = null;
    });
    // Allow the reverse scale animation in DashboardFlowLayout to play smoothly
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _shakeController.reset();
    if (mounted) {
      ToastService.show(
        context,
        'Cockpit layout saved successfully.',
        type: ToastType.success,
      );
    }
  }

  Future<void> _handleStopObdSession() async {
    _telemetry.addLogLine('[OBD] Disconnect button pressed. Stopping active session...');
    if (_fileLogger.isLogging) {
      await _fileLogger.stopSession();
    }
    await _ble.disconnect();
    if (mounted) {
      ToastService.show(
        context,
        'OBD-II session disconnected.',
        type: ToastType.info,
      );
    }
  }

  Future<void> _handleEditActiveCardFontSizes() async {
    if (_activeMetricId == null) return;
    final CardConfig? card = _layoutService.displayCards
        .where((CardConfig c) => c.metricId == _activeMetricId)
        .firstOrNull;
    final TelemetryMetric? metric = TelemetryMetric.findById(_activeMetricId!);
    if (card == null || metric == null) return;

    final ({double titleSize, double valueSize, double unitSize})? result =
        await FontSizeDialog.show(
      context: context,
      cardTitle: metric.name,
      currentTitleSize: card.titleFontSize ?? 10.5,
      currentValueSize: card.valueFontSize ?? 28.0,
      currentUnitSize: card.unitFontSize ?? 9.5,
    );

    if (result != null && mounted) {
      _layoutService.updateCardConfig(
        card.copyWith(
          titleFontSize: result.titleSize,
          valueFontSize: result.valueSize,
          unitFontSize: result.unitSize,
        ),
      );
    }
  }

  void _showSavedLayoutsDialog() {
    SavedLayoutsDialog.show(
      context: context,
      onPreviewSelected: (DashboardDesign previewDesign) {
        _layoutService.startFreezePreview(previewDesign);
        ToastService.show(
          context,
          'Previewing ${previewDesign.name} in frozen mode. Press Set to apply or Cancel to restore.',
          type: ToastType.info,
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    final TelemetryData data = _telemetry.currentData;
    final bool isConnected = _ble.currentState == BleConnectionState.connected;
    final bool isFreezePreview = _layoutService.isFreezePreview;

    return PopScope(
      canPop: !_isEditMode && !_isScreenLocked && !isFreezePreview,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        if (_isScreenLocked) {
          setState(() => _isScreenLocked = false);
          return;
        }
        if (isFreezePreview) {
          _layoutService.cancelFreezePreview();
          return;
        }
        if (_isEditMode) {
          _handleCancelEditPrompt();
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
                  isFreezePreview
                      ? Icons.lock_clock_rounded
                      : (_isEditMode ? Icons.dashboard_customize_rounded : Icons.speed),
                  size: 20.0,
                  color: isFreezePreview
                      ? GitHubTheme.warningFg
                      : (_isEditMode ? const Color(0xFFCCFF00) : GitHubTheme.accent),
                ),
              ),
              const SizedBox(width: 12.0),
              Flexible(
                child: Text(
                  isFreezePreview
                      ? 'Preview Mode'
                      : (_isEditMode ? 'Edit Dashboard' : 'ECU Logger'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: GitHubTheme.fontCanela,
                    fontSize: 20.0,
                    fontWeight: FontWeight.w700,
                    color: GitHubTheme.fgDefault,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            if (_isEditMode) ...[
              TextButton.icon(
                icon: const Icon(Icons.check, size: 18.0, color: Color(0xFFCCFF00)),
                label: const Text(
                  'Save',
                  style: TextStyle(
                    fontFamily: GitHubTheme.fontGoogleSans,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFCCFF00),
                  ),
                ),
                onPressed: _handleSaveEditMode,
              ),
            ] else if (isFreezePreview) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: GitHubTheme.warningFg.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(color: GitHubTheme.warningFg, width: 0.8),
                ),
                child: const Text(
                  'FROZEN',
                  style: TextStyle(
                    fontFamily: GitHubTheme.fontGoogleSansCode,
                    fontSize: 10.0,
                    fontWeight: FontWeight.w800,
                    color: GitHubTheme.warningFg,
                  ),
                ),
              ),
            ] else ...[
              // Grid Icon (Appears only when >= 2 saved designs exist - P3.T7)
              if (_layoutService.canShowGridIcon)
                IconButton(
                  icon: const Icon(Icons.grid_view_rounded, size: 20.0),
                  tooltip: 'Saved Cockpit Layouts',
                  onPressed: _showSavedLayoutsDialog,
                ),

              // Storage Folder Button
              IconButton(
                icon: const Icon(Icons.folder_outlined, size: 20.0),
                tooltip: 'Choose Log Storage Folder',
                onPressed: _handleFolderPickerTap,
              ),

              // Conditional Red Stop Button (Appears ONLY when actively connected - P2.T2)
              if (isConnected)
                IconButton(
                  icon: const Icon(
                    Icons.stop_circle_outlined,
                    color: GitHubTheme.dangerFg,
                    size: 22.0,
                  ),
                  tooltip: 'Disconnect OBD-II',
                  onPressed: _handleStopObdSession,
                ),

              const SizedBox(width: 8.0),
            ],
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // Frozen preview banner indicator
                if (isFreezePreview)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    color: GitHubTheme.warningFg.withValues(alpha: 0.15),
                    child: const Text(
                      'FROZEN PREVIEW — Tap Set to apply permanently or Cancel to restore',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: GitHubTheme.fontGoogleSans,
                        fontSize: 11.0,
                        fontWeight: FontWeight.w700,
                        color: GitHubTheme.warningFg,
                      ),
                    ),
                  ),

                // Responsive 4-Column Reflow Layout Dashboard (default 2x2 cards)
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: DashboardFlowLayout(
                          cards: _layoutService.displayCards,
                          telemetryData: data,
                          isConnected: isConnected,
                          isEditMode: _isEditMode && !isFreezePreview,
                          shakeAnimation: _shakeAnimation,
                          activeMetricId: _activeMetricId,
                          onActiveMetricChanged: (String? id) {
                            setState(() => _activeMetricId = id);
                          },
                          onDraggingChanged: (bool isDragging) {
                            if (isDragging) {
                              _shakeController.repeat(reverse: true);
                            } else {
                              _shakeController.stop();
                              _shakeController.reset();
                            }
                          },
                          onTriggerEditMode: () {
                            if (!isFreezePreview) _enterEditMode();
                          },
                          onReorderCards: (int oldIndex, int newIndex) {
                            final List<CardConfig> updated = List<CardConfig>.from(_layoutService.displayCards);
                            final CardConfig moved = updated.removeAt(oldIndex);
                            updated.insert(newIndex, moved);
                            _layoutService.updateDraftCards(updated);
                          },
                          onUpdateCard: (CardConfig updatedCard) {
                            _layoutService.updateCardConfig(updatedCard);
                          },
                        ),
                      ),

                      // Floating bottom buttons positioned strictly ABOVE the console tab's top (never covering it)
                      if (!_isScreenLocked)
                        Positioned(
                          right: 16.0,
                          bottom: 16.0,
                          child: _buildBottomActions(
                            isConnected: isConnected,
                            isFreezePreview: isFreezePreview,
                          ),
                        ),
                    ],
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
      ),
    );
  }

  /// Builds the floating action buttons resting strictly above the console drawer.
  Widget _buildBottomActions({
    required bool isConnected,
    required bool isFreezePreview,
  }) {
    if (isFreezePreview) {
      // Freeze Preview Bottom Buttons: icon-only Cancel & Set (P3.T8)
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'freeze_cancel_fab',
            mini: true,
            backgroundColor: GitHubTheme.canvasSubtle,
            shape: const CircleBorder(
              side: BorderSide(color: GitHubTheme.dangerFg, width: 1.5),
            ),
            tooltip: 'Cancel Preview',
            onPressed: () {
              _layoutService.cancelFreezePreview();
              ToastService.show(
                context,
                'Preview cancelled. Restored previous layout.',
                type: ToastType.info,
              );
            },
            child: const Icon(Icons.close_rounded, color: GitHubTheme.dangerFg, size: 20.0),
          ),
          const SizedBox(width: 12.0),
          FloatingActionButton(
            heroTag: 'freeze_set_fab',
            backgroundColor: GitHubTheme.successFg,
            shape: const CircleBorder(),
            tooltip: 'Set Layout',
            onPressed: () async {
              await _layoutService.applyFreezePreview();
              if (mounted) {
                ToastService.show(
                  context,
                  'Cockpit layout permanently applied.',
                  type: ToastType.success,
                );
              }
            },
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 24.0),
          ),
        ],
      );
    }

    if (_isEditMode) {
      // Edit Mode Bottom Buttons: Cancel (x), Active Card Edit (format_size), and Save (check)
      final bool hasActiveCard = _activeMetricId != null;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'edit_cancel_fab',
            mini: true,
            backgroundColor: GitHubTheme.canvasSubtle,
            shape: const CircleBorder(
              side: BorderSide(color: GitHubTheme.dangerFg, width: 1.5),
            ),
            tooltip: 'Cancel Edits',
            onPressed: _handleCancelEditPrompt,
            child: const Icon(Icons.close_rounded, color: GitHubTheme.dangerFg, size: 20.0),
          ),
          const SizedBox(width: 12.0),
          FloatingActionButton(
            heroTag: 'edit_active_card_fab',
            mini: true,
            backgroundColor: hasActiveCard ? const Color(0xFFCCFF00) : GitHubTheme.canvasSubtle,
            shape: CircleBorder(
              side: BorderSide(
                color: hasActiveCard ? const Color(0xFFCCFF00) : GitHubTheme.borderMuted,
                width: 1.5,
              ),
            ),
            tooltip: hasActiveCard ? 'Customize Font Sizes' : 'Select a Card to Customize',
            onPressed: hasActiveCard ? _handleEditActiveCardFontSizes : null,
            child: Icon(
              Icons.format_size_rounded,
              color: hasActiveCard ? Colors.black : GitHubTheme.fgSubtle,
              size: 20.0,
            ),
          ),
          const SizedBox(width: 12.0),
          FloatingActionButton(
            heroTag: 'edit_save_fab',
            backgroundColor: const Color(0xFFCCFF00),
            shape: const CircleBorder(),
            tooltip: 'Save Layout',
            onPressed: _handleSaveEditMode,
            child: const Icon(Icons.check_rounded, color: Colors.black, size: 24.0),
          ),
        ],
      );
    }

    // Normal View Mode: 3 Bottom Buttons
    return StreamBuilder<BleConnectionState>(
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

            // Bluetooth FAB
            FloatingActionButton(
              heroTag: 'ble_fab',
              backgroundColor: fabColor,
              shape: const CircleBorder(),
              tooltip: 'Bluetooth Settings',
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
    );
  }
}
