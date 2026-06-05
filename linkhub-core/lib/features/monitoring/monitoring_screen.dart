import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/protocol/messages.dart';

class MonitoringScreen extends ConsumerWidget {
  const MonitoringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pairedDevices = ref.watch(pairedDevicesProvider);
    final statuses = ref.watch(deviceStatusProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Text(
            'Device Monitoring',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        if (pairedDevices.isEmpty)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.monitor_heart, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No devices paired'),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
                childAspectRatio: 1.1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: pairedDevices.length,
              itemBuilder: (context, i) {
                final device = pairedDevices[i];
                final status = statuses[device.id];
                return _DeviceMonitorCard(
                  device: device,
                  status: status,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _DeviceMonitorCard extends StatelessWidget {
  final PairedDevice device;
  final DeviceInfo? status;

  const _DeviceMonitorCard({required this.device, required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.smartphone),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    device.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: s != null ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            if (s == null)
              const Expanded(
                child: Center(
                  child: Text('No data — device offline'),
                ),
              )
            else ...[
              _StatRow(
                icon: s.isCharging
                    ? Icons.battery_charging_full
                    : _batteryIcon(s.batteryLevel),
                iconColor: _batteryColor(s.batteryLevel),
                label: 'Battery',
                value: '${s.batteryLevel}%${s.isCharging ? " (Charging)" : ""}',
                progress: s.batteryLevel / 100,
                progressColor: _batteryColor(s.batteryLevel),
              ),
              const SizedBox(height: 12),
              _StatRow(
                icon: s.wifiConnected ? Icons.wifi : Icons.wifi_off,
                iconColor: s.wifiConnected ? Colors.blue : Colors.grey,
                label: 'Wi-Fi',
                value: s.wifiConnected
                    ? (s.wifiName.isEmpty ? 'Connected' : s.wifiName)
                    : 'Disconnected',
              ),
              const SizedBox(height: 12),
              _StatRow(
                icon: Icons.signal_cellular_alt,
                label: 'Signal',
                value: '${s.signalStrength}%',
                progress: s.signalStrength / 100,
                progressColor: Colors.blue,
              ),
              const SizedBox(height: 12),
              _StatRow(
                icon: Icons.storage,
                label: 'Storage',
                value:
                    '${_fmtBytes(s.storageUsed)} / ${_fmtBytes(s.storageTotal)}',
                progress: s.storageTotal > 0
                    ? s.storageUsed / s.storageTotal
                    : 0,
                progressColor: _storageColor(
                  s.storageTotal > 0 ? s.storageUsed / s.storageTotal : 0,
                ),
              ),
            ],
          ],
        ),
      ),
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

  Color _storageColor(double ratio) {
    if (ratio < 0.7) return Colors.blue;
    if (ratio < 0.9) return Colors.orange;
    return Colors.red;
  }

  String _fmtBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String value;
  final double? progress;
  final Color? progressColor;

  const _StatRow({
    required this.icon,
    this.iconColor,
    required this.label,
    required this.value,
    this.progress,
    this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const Spacer(),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
        if (progress != null) ...[
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress!.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(progressColor),
              minHeight: 6,
            ),
          ),
        ],
      ],
    );
  }
}
