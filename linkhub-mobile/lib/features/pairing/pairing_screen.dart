import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../../app/providers.dart';
import '../../core/websocket/ws_server.dart';

class PairingSheet extends ConsumerWidget {
  const PairingSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pairing = ref.watch(pairingStateProvider);
    final serverRunning = ref.watch(wsServerProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      builder: (_, controller) => Scaffold(
        body: ListView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Pair with Tablet',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Scan the QR code or enter the PIN on the LinkHub tablet app.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            if (!serverRunning)
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Start the WebSocket server first.'),
                      ),
                      TextButton(
                        onPressed: () =>
                            ref.read(wsServerProvider.notifier).start(),
                        child: const Text('Start'),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // QR Code
              Center(
                child: FutureBuilder<String>(
                  future: _buildQrData(pairing),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const CircularProgressIndicator();
                    }
                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: snap.data!,
                            version: QrVersions.auto,
                            size: 200,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
              ),

              const Divider(),
              const SizedBox(height: 8),

              // PIN display
              Center(
                child: Column(
                  children: [
                    Text(
                      'PIN Code',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatPin(pairing.pin),
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontFamily: 'monospace',
                              letterSpacing: 8,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter this PIN on the tablet app',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(pairingStateProvider.notifier).regenerate(),
                icon: const Icon(Icons.refresh),
                label: const Text('Generate New Code'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<String> _buildQrData(PairingState pairing) async {
    final ip = await NetworkInfo().getWifiIP() ?? '0.0.0.0';
    return jsonEncode({
      'type': 'linkhub_pair',
      'id': pairing.deviceId,
      'ip': ip,
      'port': 8765,
      'token': pairing.pairingToken,
    });
  }

  String _formatPin(String pin) {
    if (pin.length == 6) return '${pin.substring(0, 3)}-${pin.substring(3)}';
    return pin;
  }
}
