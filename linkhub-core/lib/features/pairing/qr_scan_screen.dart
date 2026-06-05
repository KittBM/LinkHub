import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/protocol/messages.dart';
import '../../app/providers.dart';
import '../../core/websocket/ws_client.dart';

class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key});

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  bool _processed = false;

  void _onDetect(BarcodeCapture capture) {
    if (_processed) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null) return;

    try {
      final data = jsonDecode(code) as Map<String, dynamic>;
      if (data['type'] == 'linkhub_pair') {
        _processed = true;
        _pair(data);
      }
    } catch (_) {}
  }

  Future<void> _pair(Map<String, dynamic> data) async {
    final device = PairedDevice(
      id: data['id'] as String,
      name: data['name'] as String? ?? 'Phone',
      ipAddress: data['ip'] as String,
      port: data['port'] as int? ?? 8765,
      pairingToken: data['token'] as String,
      pairedAt: DateTime.now(),
    );

    await ref.read(pairedDevicesProvider.notifier).add(device);
    await ref.read(wsClientProvider.notifier).connect(device);

    if (mounted) context.go('/devices');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: Column(
        children: [
          Expanded(child: MobileScanner(onDetect: _onDetect)),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Point the camera at the QR Code shown on the Phone Hub Agent app.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
