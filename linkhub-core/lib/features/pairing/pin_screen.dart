import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/protocol/messages.dart';
import '../../app/providers.dart';
import '../../core/websocket/ws_client.dart';

class PinScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? deviceInfo;
  const PinScreen({super.key, this.deviceInfo});

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  final _ipController = TextEditingController();
  final _pinController = TextEditingController();
  final _nameController = TextEditingController(text: 'My Phone');
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.deviceInfo != null) {
      _ipController.text = widget.deviceInfo!['ip'] as String? ?? '';
      _nameController.text = widget.deviceInfo!['name'] as String? ?? 'My Phone';
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    _pinController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (_ipController.text.isEmpty || _pinController.text.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // In a real implementation, this would verify the PIN with the phone agent
      // and exchange a proper pairing token.
      // For MVP, we use PIN as the pairing token seed.
      final token = base64Encode(
        utf8.encode('${_ipController.text}:${_pinController.text}'),
      );

      final device = PairedDevice(
        id: widget.deviceInfo?['id'] as String? ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        ipAddress: _ipController.text,
        port: widget.deviceInfo?['port'] as int? ?? 8765,
        pairingToken: token,
        pairedAt: DateTime.now(),
      );

      await ref.read(pairedDevicesProvider.notifier).add(device);
      await ref.read(wsClientProvider.notifier).connect(device);

      if (mounted) context.go('/devices');
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Connection failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter PIN')),
      body: Center(
        child: SizedBox(
          width: 360,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Connect with PIN',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter the PIN shown on the Phone Hub Agent app.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Device Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.smartphone),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _ipController,
                  decoration: const InputDecoration(
                    labelText: 'IP Address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.network_wifi),
                    hintText: '192.168.1.xxx',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _pinController,
                  decoration: const InputDecoration(
                    labelText: 'PIN Code (6 digits)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.pin),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  obscureText: true,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loading ? null : _connect,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Connect'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
