import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _discoveredDevicesProvider =
    StateProvider<List<Map<String, dynamic>>>((ref) => []);

class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key});

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  bool _scanning = false;
  RawDatagramSocket? _udpSocket;
  Timer? _scanTimer;

  @override
  void dispose() {
    _udpSocket?.close();
    _scanTimer?.cancel();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() => _scanning = true);
    ref.read(_discoveredDevicesProvider.notifier).state = [];

    try {
      _udpSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
        reuseAddress: true,
      );
      _udpSocket!.broadcastEnabled = true;

      _udpSocket!.listen((event) {
        if (event == RawSocketEvent.read) {
          final dg = _udpSocket!.receive();
          if (dg != null) {
            try {
              final data =
                  jsonDecode(utf8.decode(dg.data)) as Map<String, dynamic>;
              if (data['type'] == 'linkhub_agent') {
                final current = ref.read(_discoveredDevicesProvider);
                if (!current.any((d) => d['id'] == data['id'])) {
                  ref.read(_discoveredDevicesProvider.notifier).state = [
                    ...current,
                    {...data, 'ip': dg.address.address},
                  ];
                }
              }
            } catch (_) {}
          }
        }
      });

      final broadcast = utf8.encode(
        jsonEncode({'type': 'linkhub_discover', 'version': '1'}),
      );
      _udpSocket!.send(broadcast, InternetAddress('255.255.255.255'), 8766);

      _scanTimer = Timer(const Duration(seconds: 5), () {
        setState(() => _scanning = false);
        _udpSocket?.close();
      });
    } catch (_) {
      setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final discovered = ref.watch(_discoveredDevicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Device'),
        leading: BackButton(onPressed: () => context.go('/devices')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pair a Phone',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Make sure the Phone Hub Agent app is running on your phone '
              'and connected to the same Wi-Fi network.',
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: _scanning ? null : _startScan,
                  icon: _scanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: Text(_scanning ? 'Scanning...' : 'Scan Network'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => context.push('/pairing/qr'),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan QR Code'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => context.push('/pairing/pin'),
                  icon: const Icon(Icons.pin),
                  label: const Text('Enter PIN'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (discovered.isNotEmpty) ...[
              Text(
                'Discovered Devices',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...discovered.map(
                (d) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.smartphone),
                    title: Text(d['name'] as String? ?? 'Unknown Device'),
                    subtitle: Text(d['ip'] as String? ?? ''),
                    trailing: FilledButton(
                      onPressed: () =>
                          context.go('/pairing/pin', extra: d),
                      child: const Text('Connect'),
                    ),
                  ),
                ),
              ),
            ] else if (!_scanning) ...[
              const Center(
                child: Column(
                  children: [
                    SizedBox(height: 40),
                    Icon(Icons.phonelink_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No devices found. Tap Scan Network to search.'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
