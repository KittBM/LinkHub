import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../../app/providers.dart';
import '../../core/websocket/ws_server.dart';
import '../pairing/pairing_screen.dart';

final _ipAddressProvider = FutureProvider<String>((ref) async {
  try {
    return await NetworkInfo().getWifiIP() ?? 'Unknown';
  } catch (_) {
    return 'Unknown';
  }
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverRunning = ref.watch(wsServerProvider);
    final serviceState = ref.watch(agentServiceProvider);
    final ipAsync = ref.watch(_ipAddressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LinkHub Mobile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            tooltip: 'Show Pairing Code',
            onPressed: () => _showPairingSheet(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Server status card
          _StatusCard(
            icon: serverRunning ? Icons.cloud_done : Icons.cloud_off,
            iconColor: serverRunning ? Colors.green : Colors.grey,
            title: 'WebSocket Server',
            subtitle: serverRunning
                ? 'Listening on port 8765'
                : 'Not running',
            trailing: Switch(
              value: serverRunning,
              onChanged: (v) => v
                  ? ref.read(wsServerProvider.notifier).start()
                  : ref.read(wsServerProvider.notifier).stop(),
            ),
          ),
          const SizedBox(height: 12),

          // IP address
          ipAsync.when(
            data: (ip) => _StatusCard(
              icon: Icons.wifi,
              iconColor: Colors.blue,
              title: 'IP Address',
              subtitle: ip,
              trailing: IconButton(
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: ip));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('IP copied')),
                  );
                },
              ),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, st) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),

          // Foreground service
          _StatusCard(
            icon: serviceState.foregroundRunning
                ? Icons.play_circle
                : Icons.pause_circle,
            iconColor: serviceState.foregroundRunning
                ? Colors.green
                : Colors.grey,
            title: 'Background Service',
            subtitle: serviceState.foregroundRunning
                ? 'Running in background'
                : 'Tap to start',
            trailing: Switch(
              value: serviceState.foregroundRunning,
              onChanged: (v) => v
                  ? ref
                      .read(agentServiceProvider.notifier)
                      .startForegroundService()
                  : ref.read(agentServiceProvider.notifier).stopForegroundService(),
            ),
          ),
          const SizedBox(height: 12),

          // Notification Listener permission
          _PermissionCard(
            icon: Icons.notifications,
            title: 'Notification Access',
            description:
                'Required to mirror notifications to the tablet.',
            enabled: serviceState.notificationListenerEnabled,
            onSetup: () => const MethodChannel('com.linkhub/agent')
                .invokeMethod('openNotificationListenerSettings'),
          ),
          const SizedBox(height: 12),

          // SMS & Calls
          _InfoCard(
            title: 'Setup Complete?',
            items: const [
              '1. Start the Background Service',
              '2. Grant Notification Access',
              '3. Pair with the tablet using QR or PIN',
              '4. Keep this app running',
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPairingSheet(context, ref),
        icon: const Icon(Icons.qr_code),
        label: const Text('Pair with Tablet'),
      ),
    );
  }

  void _showPairingSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const PairingSheet(),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _StatusCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: iconColor, size: 28),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing,
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool enabled;
  final VoidCallback onSetup;

  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.enabled,
    required this.onSetup,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              color: enabled ? Colors.green : Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (!enabled)
              TextButton(
                onPressed: onSetup,
                child: const Text('Enable'),
              )
            else
              const Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<String> items;

  const _InfoCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(item),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
