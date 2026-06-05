import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../app/providers.dart';
import '../../core/protocol/messages.dart';
import '../../core/websocket/ws_client.dart';

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pairedDevices = ref.watch(pairedDevicesProvider);
    final connectionStates = ref.watch(wsClientProvider);
    final deviceStatuses = ref.watch(deviceStatusProvider);

    if (pairedDevices.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.phonelink_off, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No devices paired',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('Tap the + button to add your first phone.'),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/pairing'),
              icon: const Icon(Icons.add),
              label: const Text('Add Device'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Devices',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              FilledButton.icon(
                onPressed: () => context.push('/pairing'),
                icon: const Icon(Icons.add),
                label: const Text('Add Device'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pairedDevices.length,
            itemBuilder: (context, index) {
              final device = pairedDevices[index];
              final connState = connectionStates[device.id]?.state;
              final status = deviceStatuses[device.id];
              return _DeviceCard(
                device: device,
                connectionState: connState,
                status: status,
                onRemove: () => _removeDevice(context, ref, device),
                onReconnect: () => ref
                    .read(wsClientProvider.notifier)
                    .connect(device),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _removeDevice(
    BuildContext context,
    WidgetRef ref,
    PairedDevice device,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Device'),
        content: Text('Remove "${device.name}" from paired devices?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(wsClientProvider.notifier).disconnect(device.id);
      await ref.read(pairedDevicesProvider.notifier).remove(device.id);
    }
  }
}

class _DeviceCard extends StatelessWidget {
  final PairedDevice device;
  final WsConnectionState? connectionState;
  final DeviceInfo? status;
  final VoidCallback onRemove;
  final VoidCallback onReconnect;

  const _DeviceCard({
    required this.device,
    required this.connectionState,
    required this.status,
    required this.onRemove,
    required this.onReconnect,
  });

  @override
  Widget build(BuildContext context) {
    final isConnected = connectionState == WsConnectionState.connected;
    final isConnecting = connectionState == WsConnectionState.connecting;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    const Icon(Icons.smartphone, size: 40),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isConnected
                              ? Colors.green
                              : isConnecting
                              ? Colors.orange
                              : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${device.ipAddress}:${device.port}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                _StatusChip(state: connectionState),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'remove') onRemove();
                    if (v == 'reconnect') onReconnect();
                  },
                  itemBuilder: (_) => [
                    if (!isConnected)
                      const PopupMenuItem(
                        value: 'reconnect',
                        child: ListTile(
                          leading: Icon(Icons.refresh),
                          title: Text('Reconnect'),
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Remove'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (status != null) ...[
              const Divider(height: 24),
              _StatusRow(status: status!),
            ],
            const SizedBox(height: 4),
            Text(
              'Last seen: ${_formatTime(device.pairedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return DateFormat('MMM d, HH:mm').format(dt);
  }
}

class _StatusChip extends StatelessWidget {
  final WsConnectionState? state;
  const _StatusChip({this.state});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      WsConnectionState.connected => ('Connected', Colors.green),
      WsConnectionState.connecting => ('Connecting...', Colors.orange),
      WsConnectionState.error => ('Error', Colors.red),
      _ => ('Offline', Colors.grey),
    };
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _StatusRow extends StatelessWidget {
  final DeviceInfo status;
  const _StatusRow({required this.status});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _InfoChip(
          icon: status.isCharging ? Icons.battery_charging_full : _batteryIcon(status.batteryLevel),
          label: '${status.batteryLevel}%',
          color: _batteryColor(status.batteryLevel),
        ),
        _InfoChip(
          icon: status.wifiConnected ? Icons.wifi : Icons.wifi_off,
          label: status.wifiConnected ? (status.wifiName.isEmpty ? 'Wi-Fi' : status.wifiName) : 'No Wi-Fi',
        ),
        _InfoChip(
          icon: Icons.signal_cellular_alt,
          label: '${status.signalStrength}%',
        ),
        _InfoChip(
          icon: Icons.storage,
          label: '${_formatBytes(status.storageUsed)} / ${_formatBytes(status.storageTotal)}',
        ),
      ],
    );
  }

  IconData _batteryIcon(int level) {
    if (level >= 90) return Icons.battery_full;
    if (level >= 60) return Icons.battery_5_bar;
    if (level >= 40) return Icons.battery_3_bar;
    if (level >= 20) return Icons.battery_2_bar;
    return Icons.battery_1_bar;
  }

  Color _batteryColor(int level) {
    if (level >= 50) return Colors.green;
    if (level >= 20) return Colors.orange;
    return Colors.red;
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(0)}MB';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
