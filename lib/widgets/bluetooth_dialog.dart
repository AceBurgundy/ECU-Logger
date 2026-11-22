// OBD = On-Board Diagnostics
// BLE = Bluetooth Low Energy
// RSSI = Received Signal Strength Indicator
import 'package:flutter/material.dart';
import '../theme/github_theme.dart';
import '../services/ble_service.dart';
import 'toast_overlay.dart';

/// Modal dialog allowing the rider to scan, select, and connect to or disconnect
/// from an OBD-II Bluetooth peripheral adapter, prioritizing detected OBD scanners.
class BluetoothDialog extends StatefulWidget {
  /// Creates a [BluetoothDialog] instance.
  const BluetoothDialog({super.key});

  @override
  State<BluetoothDialog> createState() => _BluetoothDialogState();
}

class _BluetoothDialogState extends State<BluetoothDialog> {
  final BleService _ble = BleService.instance;
  bool _showUnknownDevices = false;

  @override
  void initState() {
    super.initState();
    if (_ble.currentState != BleConnectionState.connected) {
      _ble.startScan();
    }
  }

  Widget _buildDeviceTile({
    required BleDiscoveredDevice deviceItem,
    required BleConnectionState state,
    required bool isHighlighted,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3.0),
      decoration: BoxDecoration(
        color: isHighlighted
            ? GitHubTheme.accentEmphasis.withValues(alpha: 0.12)
            : GitHubTheme.canvasInset,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isHighlighted
              ? GitHubTheme.accent.withValues(alpha: 0.6)
              : GitHubTheme.borderMuted,
          width: isHighlighted ? 1.2 : 0.8,
        ),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
        leading: Container(
          padding: const EdgeInsets.all(6.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isHighlighted
                ? GitHubTheme.accent.withValues(alpha: 0.2)
                : GitHubTheme.canvasSubtle,
          ),
          child: Icon(
            deviceItem.isObd ? Icons.speed_rounded : Icons.bluetooth,
            color: isHighlighted ? GitHubTheme.accent : GitHubTheme.fgMuted,
            size: 18.0,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                deviceItem.name,
                style: TextStyle(
                  fontFamily: GitHubTheme.fontGoogleSans,
                  fontSize: 13.0,
                  fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
                  color: isHighlighted ? GitHubTheme.accent : GitHubTheme.fgDefault,
                ),
              ),
            ),
            if (deviceItem.isObd) ...[
              const SizedBox(width: 6.0),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.5),
                decoration: BoxDecoration(
                  color: GitHubTheme.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(color: GitHubTheme.accent, width: 0.8),
                ),
                child: const Text(
                  'OBD-II',
                  style: TextStyle(
                    fontFamily: GitHubTheme.fontGoogleSansCode,
                    fontSize: 9.0,
                    fontWeight: FontWeight.w700,
                    color: GitHubTheme.accent,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          '${deviceItem.id}  •  ${deviceItem.rssi} dBm',
          style: const TextStyle(
            fontFamily: GitHubTheme.fontGoogleSansCode,
            fontSize: 10.0,
            color: GitHubTheme.fgSubtle,
          ),
        ),
        trailing: state == BleConnectionState.connecting
            ? const SizedBox(
                width: 16.0,
                height: 16.0,
                child: CircularProgressIndicator(strokeWidth: 2.0),
              )
            : const Icon(
                Icons.chevron_right,
                color: GitHubTheme.fgMuted,
                size: 18.0,
              ),
        onTap: state == BleConnectionState.connecting
            ? null
            : () async {
                await _ble.connectToDevice(deviceItem);
                if (!mounted) return;
                ToastService.show(
                  context,
                  'Connected to ${deviceItem.name}! Logging started.',
                  type: ToastType.success,
                );
                Navigator.of(context).pop(true);
              },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: GitHubTheme.canvasSubtle,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: const BorderSide(color: GitHubTheme.borderDefault),
      ),
      child: Container(
        width: 400.0,
        padding: const EdgeInsets.all(20.0),
        child: StreamBuilder<BleConnectionState>(
          stream: _ble.stateStream,
          initialData: _ble.currentState,
          builder: (BuildContext dialogContext, AsyncSnapshot<BleConnectionState> stateSnapshot) {
            final BleConnectionState state = stateSnapshot.data ?? BleConnectionState.disconnected;
            final bool isConnected = state == BleConnectionState.connected;

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
                          size: 22.0,
                        ),
                        const SizedBox(width: 8.0),
                        const Text(
                          'Bluetooth OBD-II',
                          style: TextStyle(
                            fontFamily: GitHubTheme.fontCanela,
                            fontSize: 18.0,
                            fontWeight: FontWeight.w600,
                            color: GitHubTheme.fgDefault,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20.0, color: GitHubTheme.fgMuted),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                const Divider(color: GitHubTheme.borderMuted),
                const SizedBox(height: 8.0),

                // Connected State Banner & Disconnect Action
                if (isConnected) ...[
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: GitHubTheme.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: GitHubTheme.success.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.check_circle, color: GitHubTheme.successFg, size: 20.0),
                        SizedBox(width: 10.0),
                        Expanded(
                          child: Text(
                            'Connected to OBD-II device.\nLogging stream active.',
                            style: TextStyle(
                              fontFamily: GitHubTheme.fontGoogleSans,
                              fontSize: 13.0,
                              color: GitHubTheme.fgDefault,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GitHubTheme.danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                      ),
                      icon: const Icon(Icons.bluetooth_disabled, size: 18.0),
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
                          Navigator.of(context).pop(false);
                        }
                      },
                    ),
                  ),
                ] else ...[
                  // Scanning & Discovered List Header
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
                          fontSize: 12.0,
                          color: GitHubTheme.fgMuted,
                        ),
                      ),
                      if (state == BleConnectionState.scanning)
                        const SizedBox(
                          width: 14.0,
                          height: 14.0,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
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
                              fontSize: 12.0,
                              color: GitHubTheme.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10.0),

                  // Device Stream List
                  StreamBuilder<List<BleDiscoveredDevice>>(
                    stream: _ble.deviceListStream,
                    initialData: _ble.discoveredDevices,
                    builder: (BuildContext listContext,
                        AsyncSnapshot<List<BleDiscoveredDevice>> deviceSnapshot) {
                      final List<BleDiscoveredDevice> allDevices = deviceSnapshot.data ?? [];
                      if (allDevices.isEmpty) {
                        return Container(
                          height: 120.0,
                          alignment: Alignment.center,
                          child: Text(
                            state == BleConnectionState.scanning
                                ? 'Searching for NexLink / OBD-II...'
                                : 'No devices found. Tap refresh.',
                            style: const TextStyle(
                              fontFamily: GitHubTheme.fontGoogleSans,
                              fontSize: 13.0,
                              color: GitHubTheme.fgSubtle,
                            ),
                          ),
                        );
                      }

                      final List<BleDiscoveredDevice> obdDevices =
                          allDevices.where((BleDiscoveredDevice d) => d.isObd).toList();
                      final List<BleDiscoveredDevice> otherNamedDevices = allDevices
                          .where((BleDiscoveredDevice d) =>
                              !d.isObd && d.name.isNotEmpty && d.name != 'Unknown BLE Device')
                          .toList();
                      final List<BleDiscoveredDevice> unknownDevices = allDevices
                          .where((BleDiscoveredDevice d) =>
                              !d.isObd && (d.name.isEmpty || d.name == 'Unknown BLE Device'))
                          .toList();

                      final List<BleDiscoveredDevice> displayedDevices = <BleDiscoveredDevice>[
                        ...obdDevices,
                        ...otherNamedDevices,
                        if (_showUnknownDevices) ...unknownDevices,
                      ];

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 250.0),
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const BouncingScrollPhysics(),
                              itemCount: displayedDevices.length,
                              itemBuilder: (BuildContext itemContext, int index) {
                                final BleDiscoveredDevice deviceItem = displayedDevices[index];
                                return _buildDeviceTile(
                                  deviceItem: deviceItem,
                                  state: state,
                                  isHighlighted: deviceItem.isObd,
                                );
                              },
                            ),
                          ),
                          if (unknownDevices.isNotEmpty) ...[
                            const SizedBox(height: 6.0),
                            InkWell(
                              onTap: () {
                                setState(() => _showUnknownDevices = !_showUnknownDevices);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _showUnknownDevices
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 14.0,
                                      color: GitHubTheme.fgSubtle,
                                    ),
                                    const SizedBox(width: 6.0),
                                    Text(
                                      _showUnknownDevices
                                          ? 'Hide ${unknownDevices.length} unknown BLE devices'
                                          : 'Show ${unknownDevices.length} unnamed devices',
                                      style: const TextStyle(
                                        fontFamily: GitHubTheme.fontGoogleSans,
                                        fontSize: 11.0,
                                        color: GitHubTheme.fgSubtle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
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
