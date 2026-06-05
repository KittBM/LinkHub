import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../app/providers.dart';
import '../../core/protocol/messages.dart';
import '../../core/websocket/ws_client.dart';

final _smsSearchProvider = StateProvider<String>((ref) => '');
final _selectedThreadProvider = StateProvider<String?>((ref) => null);
final _selectedSmsDeviceProvider = StateProvider<String?>((ref) => null);

class SmsScreen extends ConsumerWidget {
  const SmsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allSms = ref.watch(smsProvider);
    final search = ref.watch(_smsSearchProvider);
    final selectedThread = ref.watch(_selectedThreadProvider);
    final selectedDevice = ref.watch(_selectedSmsDeviceProvider);
    final pairedDevices = ref.watch(pairedDevicesProvider);

    // Group by address
    final Map<String, List<SmsMessage>> threads = {};
    for (final sms in allSms) {
      if (selectedDevice != null && sms.deviceId != selectedDevice) { continue; }
      if (search.isNotEmpty &&
          !sms.address.contains(search) &&
          !sms.contactName.toLowerCase().contains(search.toLowerCase()) &&
          !sms.body.toLowerCase().contains(search.toLowerCase())) { continue; }
      threads.putIfAbsent(sms.address, () => []).add(sms);
    }

    return Row(
      children: [
        // Thread list
        SizedBox(
          width: 280,
          child: Column(
            children: [
              _SmsHeader(
                pairedDevices: pairedDevices,
                selectedDevice: selectedDevice,
                onDeviceChanged: (v) =>
                    ref.read(_selectedSmsDeviceProvider.notifier).state = v,
                onNewSms: () => _showNewSmsDialog(context, ref),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) =>
                      ref.read(_smsSearchProvider.notifier).state = v,
                ),
              ),
              Expanded(
                child: threads.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.sms, size: 48, color: Colors.grey),
                            const SizedBox(height: 8),
                            const Text('No messages'),
                            const SizedBox(height: 8),
                            if (pairedDevices.isNotEmpty)
                              TextButton(
                                onPressed: () => _requestSms(ref),
                                child: const Text('Load SMS'),
                              ),
                          ],
                        ),
                      )
                    : ListView(
                        children: threads.entries.map((e) {
                          final latest = e.value.first;
                          final unread =
                              e.value.where((s) => !s.isRead).length;
                          return ListTile(
                            selected: selectedThread == e.key,
                            leading: CircleAvatar(
                              child: Text(
                                _initials(latest.contactName.isEmpty
                                    ? latest.address
                                    : latest.contactName),
                              ),
                            ),
                            title: Text(
                              latest.contactName.isEmpty
                                  ? latest.address
                                  : latest.contactName,
                              style: TextStyle(
                                fontWeight: unread > 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              latest.body,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatTime(latest.timestamp),
                                  style: const TextStyle(fontSize: 11),
                                ),
                                if (unread > 0)
                                  Badge(label: Text('$unread')),
                              ],
                            ),
                            onTap: () => ref
                                .read(_selectedThreadProvider.notifier)
                                .state = e.key,
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        // Conversation view
        Expanded(
          child: selectedThread == null
              ? const Center(child: Text('Select a conversation'))
              : _ConversationView(
                  address: selectedThread,
                  messages: threads[selectedThread] ?? [],
                  deviceId: (threads[selectedThread]?.first.deviceId) ?? '',
                ),
        ),
      ],
    );
  }

  void _requestSms(WidgetRef ref) {
    final devices = ref.read(pairedDevicesProvider);
    for (final device in devices) {
      ref.read(wsClientProvider.notifier).sendMessage(
        PhoneHubMessage(
          type: MessageType.smsList,
          deviceId: device.id,
          payload: {'action': 'list', 'limit': 200},
        ),
        device.id,
      );
    }
  }

  void _showNewSmsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _NewSmsDialog(ref: ref),
    );
  }

  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day) return DateFormat('HH:mm').format(dt);
    return DateFormat('MMM d').format(dt);
  }
}

class _SmsHeader extends StatelessWidget {
  final List<PairedDevice> pairedDevices;
  final String? selectedDevice;
  final ValueChanged<String?> onDeviceChanged;
  final VoidCallback onNewSms;

  const _SmsHeader({
    required this.pairedDevices,
    required this.selectedDevice,
    required this.onDeviceChanged,
    required this.onNewSms,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 8, 4),
      child: Row(
        children: [
          Text('SMS', style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          if (pairedDevices.length > 1)
            DropdownButton<String?>(
              value: selectedDevice,
              hint: const Text('All'),
              isDense: true,
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ...pairedDevices.map(
                  (d) => DropdownMenuItem(value: d.id, child: Text(d.name)),
                ),
              ],
              onChanged: onDeviceChanged,
            ),
          IconButton(
            icon: const Icon(Icons.edit_square),
            tooltip: 'New Message',
            onPressed: onNewSms,
          ),
        ],
      ),
    );
  }
}

class _ConversationView extends ConsumerStatefulWidget {
  final String address;
  final List<SmsMessage> messages;
  final String deviceId;

  const _ConversationView({
    required this.address,
    required this.messages,
    required this.deviceId,
  });

  @override
  ConsumerState<_ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends ConsumerState<_ConversationView> {
  final _replyController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    ref.read(wsClientProvider.notifier).sendMessage(
      PhoneHubMessage(
        type: MessageType.smsSend,
        deviceId: widget.deviceId,
        payload: {'to': widget.address, 'body': text},
      ),
      widget.deviceId,
    );
    _replyController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.messages.firstOrNull?.contactName ?? widget.address;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              CircleAvatar(child: Text(name[0].toUpperCase())),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    widget.address,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: widget.messages.length,
            itemBuilder: (context, i) {
              final sms = widget.messages[i];
              return _SmsBubble(sms: sms);
            },
          ),
        ),
        // Reply bar
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _replyController,
                  decoration: const InputDecoration(
                    hintText: 'Send a message...',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (_) => _send(),
                  maxLines: 3,
                  minLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _send,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SmsBubble extends StatelessWidget {
  final SmsMessage sms;
  const _SmsBubble({required this.sms});

  @override
  Widget build(BuildContext context) {
    final isIncoming = sms.isIncoming;
    return Align(
      alignment: isIncoming ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.55,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isIncoming
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isIncoming ? 4 : 16),
            bottomRight: Radius.circular(isIncoming ? 16 : 4),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isIncoming ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Text(sms.body),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(sms.timestamp),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewSmsDialog extends StatefulWidget {
  final WidgetRef ref;
  const _NewSmsDialog({required this.ref});

  @override
  State<_NewSmsDialog> createState() => _NewSmsDialogState();
}

class _NewSmsDialogState extends State<_NewSmsDialog> {
  final _toController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void dispose() {
    _toController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _send() {
    final devices = widget.ref.read(pairedDevicesProvider);
    if (devices.isEmpty) return;
    widget.ref.read(wsClientProvider.notifier).sendMessage(
      PhoneHubMessage(
        type: MessageType.smsSend,
        deviceId: devices.first.id,
        payload: {
          'to': _toController.text,
          'body': _bodyController.text,
        },
      ),
      devices.first.id,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Message'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _toController,
            decoration: const InputDecoration(
              labelText: 'To (phone number)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyController,
            decoration: const InputDecoration(
              labelText: 'Message',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _send, child: const Text('Send')),
      ],
    );
  }
}
