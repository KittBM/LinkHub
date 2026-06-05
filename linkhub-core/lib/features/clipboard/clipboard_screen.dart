import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/protocol/messages.dart';
import '../../core/websocket/ws_client.dart';

class ClipboardScreen extends ConsumerStatefulWidget {
  const ClipboardScreen({super.key});

  @override
  ConsumerState<ClipboardScreen> createState() => _ClipboardScreenState();
}

class _ClipboardScreenState extends ConsumerState<ClipboardScreen> {
  final _sendController = TextEditingController();

  @override
  void dispose() {
    _sendController.dispose();
    super.dispose();
  }

  Future<void> _copyToTablet(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied to tablet clipboard')),
      );
    }
  }

  void _sendToPhone(String text) {
    if (text.isEmpty) return;
    final devices = ref.read(pairedDevicesProvider);
    final ws = ref.read(wsClientProvider.notifier);
    for (final device in devices) {
      ws.sendMessage(
        PhoneHubMessage(
          type: MessageType.clipboardSync,
          deviceId: device.id,
          payload: {'text': text},
        ),
        device.id,
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sent to all connected phones')),
      );
    }
    _sendController.clear();
  }

  Future<void> _pasteFromTablet() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _sendController.text = data!.text!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final phoneClipboard = ref.watch(clipboardSyncProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Text(
            'Clipboard Sync',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Phone → Tablet
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.smartphone, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'From Phone',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: phoneClipboard.isEmpty
                                      ? const Center(
                                          child: Text(
                                            'No clipboard content from phone yet.\nCopy text on your phone to sync it here.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(color: Colors.grey),
                                          ),
                                        )
                                      : SingleChildScrollView(
                                          child: SelectableText(
                                            phoneClipboard,
                                            style: const TextStyle(fontSize: 15),
                                          ),
                                        ),
                                ),
                                if (phoneClipboard.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  FilledButton.icon(
                                    onPressed: () =>
                                        _copyToTablet(phoneClipboard),
                                    icon: const Icon(Icons.copy),
                                    label: const Text('Copy to Tablet'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Tablet → Phone
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tablet_android, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Send to Phone',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _sendController,
                                    decoration: const InputDecoration(
                                      hintText: 'Type or paste text to send to phone...',
                                      border: InputBorder.none,
                                    ),
                                    maxLines: null,
                                    expands: true,
                                    textAlignVertical: TextAlignVertical.top,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _pasteFromTablet,
                                        icon: const Icon(Icons.content_paste),
                                        label: const Text('Paste'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: FilledButton.icon(
                                        onPressed: () =>
                                            _sendToPhone(_sendController.text),
                                        icon: const Icon(Icons.send),
                                        label: const Text('Send to Phone'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
