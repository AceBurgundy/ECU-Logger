import 'package:flutter/material.dart';
import '../theme/github_theme.dart';
import '../services/ble_service.dart';
import 'toast_overlay.dart';

class BluetoothDialog extends StatefulWidget {
  const BluetoothDialog({super.key});

  @override
  State<BluetoothDialog> createState() => _BluetoothDialogState();
}

class _BluetoothDialogState extends State<BluetoothDialog> {
  final BleService _ble = BleService.instance;

  @override
  void initState() {
    super.initState();
    if (_ble.currentState != BleConnectionState.connected) {
      _ble.startScan();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: GitHubTheme.canvasSubtle,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: GitHubTheme.borderDefault),
      ),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<BleConnectionState>(
          stream: _ble.stateStream,
          initialData: _ble.currentState,
          builder: (context, stateSnap) {
            final state = stateSnap.data ?? BleConnectionState.disconnected;
            final isConnected = state == BleConnectionState.connected;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.bluetooth,
                          color: isConnected
                              ? GitHubTheme.successFg
                              : (state == BleConnectionState.scanning
                                  ? GitHubTheme.warningFg
                                  : GitHubTheme.fgMuted),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Bluetooth OBD-II',
                          style: TextStyle(
                            fontFamily: GitHubTheme.fontCanela,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: GitHubTheme.fgDefault,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: GitHubTheme.fgMuted),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: GitHubTheme.borderMuted),
                const SizedBox(height: 8),

                // Connected State Banner & Disconnect Action
                if (isConnected) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: GitHubTheme.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: GitHubTheme.success.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.check_circle, color: GitHubTheme.successFg, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Connected to OBD-II device.\nLogging stream active.',
                            style: TextStyle(
                              fontFamily: GitHubTheme.fontGoogleSans,
                              fontSize: 13,
                              color: GitHubTheme.fgDefault,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GitHubTheme.danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.bluetooth_disabled, size: 18),
                      label: const Text(
                        'Disconnect Device',
                        style: TextStyle(
                          fontFamily: GitHubTheme.fontGoogleSans,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () async {
                        await _ble.disconnect();
                        if (context.mounted) {
                          ToastService.show(
                            context,
                            'Disconnected from OBD-II adapter',
                            type: ToastType.info,
                          );
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),
                ] else ...[
                  // Scanning & Discovered List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        state == BleConnectionState.scanning
                            ? 'Scanning for devices...'
                            : (state == BleConnectionState.connecting
                                ? 'Connecting to adapter...'
                                : 'Select OBD-II Peripheral'),
                        style: const TextStyle(
                          fontFamily: GitHubTheme.fontGoogleSans,
                          fontSize: 12,
                          color: GitHubTheme.fgMuted,
                        ),
                      ),
                      if (state == BleConnectionState.scanning)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(GitHubTheme.warningFg),
                          ),
                        )
                      else
                        InkWell(
                          onTap: () => _ble.startScan(),
                          child: const Text(
                            'Refresh',
                            style: TextStyle(
                              fontFamily: GitHubTheme.fontGoogleSans,
                              fontSize: 12,
                              color: GitHubTheme.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Device Stream List
                  StreamBuilder<List<BleDiscoveredDevice>>(
                    stream: _ble.deviceListStream,
                    initialData: _ble.discoveredDevices,
                    builder: (context, devSnap) {
                      final devices = devSnap.data ?? [];
                      if (devices.isEmpty) {
                        return Container(
                          height: 120,
                          alignment: Alignment.center,
                          child: Text(
                            state == BleConnectionState.scanning
                                ? 'Searching for NexLink / OBD-II...'
                                : 'No devices found. Tap refresh.',
                            style: const TextStyle(
                              fontFamily: GitHubTheme.fontGoogleSans,
                              fontSize: 13,
                              color: GitHubTheme.fgSubtle,
                            ),
                          ),
                        );
                      }

                      return ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: devices.length,
                          separatorBuilder: (_, __) => const Divider(
                            color: GitHubTheme.borderMuted,
                            height: 1,
                          ),
                          itemBuilder: (context, index) {
                            final dev = devices[index];
                            final isNexLink = dev.id.contains('8C:DE:52:DF:42:C3') ||
                                dev.name.toLowerCase().contains('nexas') ||
                                dev.name.toLowerCase().contains('nexlink');

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              leading: Icon(
                                Icons.settings_input_antenna,
                                color: isNexLink ? GitHubTheme.accent : GitHubTheme.fgMuted,
                                size: 20,
                              ),
                              title: Text(
                                dev.name,
                                style: TextStyle(
                                  fontFamily: GitHubTheme.fontGoogleSans,
                                  fontSize: 13,
                                  fontWeight: isNexLink ? FontWeight.w600 : FontWeight.w400,
                                  color: isNexLink ? GitHubTheme.accent : GitHubTheme.fgDefault,
                                ),
                              ),
                              subtitle: Text(
                                '${dev.id}  (${dev.rssi} dBm)',
                                style: const TextStyle(
                                  fontFamily: GitHubTheme.fontGoogleSansCode,
                                  fontSize: 10,
                                  color: GitHubTheme.fgSubtle,
                                ),
                              ),
                              trailing: state == BleConnectionState.connecting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(
                                      Icons.chevron_right,
                                      color: GitHubTheme.fgMuted,
                                      size: 18,
                                    ),
                              onTap: state == BleConnectionState.connecting
                                  ? null
                                  : () async {
                                      await _ble.connectToDevice(dev);
                                      if (context.mounted) {
                                        ToastService.show(
                                          context,
                                          'Connected to ${dev.name}! Logging started.',
                                          type: ToastType.success,
                                        );
                                        Navigator.of(context).pop();
                                      }
                                    },
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
