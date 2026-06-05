import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../app/providers.dart';
import '../../core/protocol/messages.dart';
import '../../core/websocket/ws_client.dart';

final _filterDeviceProvider = StateProvider<String?>((ref) => null);

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(notificationsProvider);
    final filterDevice = ref.watch(_filterDeviceProvider);
    final pairedDevices = ref.watch(pairedDevicesProvider);

    final filtered = filterDevice == null
        ? all
        : all.where((n) => n.deviceId == filterDevice).toList();

    return Column(
      children: [
        _NotifHeader(
          pairedDevices: pairedDevices,
          filterDevice: filterDevice,
          onFilterChanged: (v) =>
              ref.read(_filterDeviceProvider.notifier).state = v,
          onClearAll: () => ref.read(notificationsProvider.notifier).clearAll(),
          unreadCount: filtered.where((n) => !n.isRead).length,
        ),
        const Divider(height: 1),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No notifications'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => _NotifTile(
                    notification: filtered[i],
                    onDismiss: () => _dismiss(ref, filtered[i]),
                    onMarkRead: () => _markRead(ref, filtered[i]),
                    onReply: (text) => _reply(ref, filtered[i], text),
                  ),
                ),
        ),
      ],
    );
  }

  void _dismiss(WidgetRef ref, NotificationItem n) {
    ref.read(notificationsProvider.notifier).dismiss(n.id);
    final ws = ref.read(wsClientProvider.notifier);
    ws.sendMessage(
      PhoneHubMessage(
        type: MessageType.notificationAction,
        deviceId: n.deviceId,
        payload: {'id': n.id, 'action': 'dismiss'},
      ),
      n.deviceId,
    );
  }

  void _markRead(WidgetRef ref, NotificationItem n) {
    ref.read(notificationsProvider.notifier).markRead(n.id);
    final ws = ref.read(wsClientProvider.notifier);
    ws.sendMessage(
      PhoneHubMessage(
        type: MessageType.notificationAction,
        deviceId: n.deviceId,
        payload: {'id': n.id, 'action': 'markRead'},
      ),
      n.deviceId,
    );
  }

  void _reply(WidgetRef ref, NotificationItem n, String text) {
    final ws = ref.read(wsClientProvider.notifier);
    ws.sendMessage(
      PhoneHubMessage(
        type: MessageType.notificationAction,
        deviceId: n.deviceId,
        payload: {'id': n.id, 'action': 'reply', 'text': text},
      ),
      n.deviceId,
    );
    ref.read(notificationsProvider.notifier).markRead(n.id);
  }
}

class _NotifHeader extends StatelessWidget {
  final List<PairedDevice> pairedDevices;
  final String? filterDevice;
  final ValueChanged<String?> onFilterChanged;
  final VoidCallback onClearAll;
  final int unreadCount;

  const _NotifHeader({
    required this.pairedDevices,
    required this.filterDevice,
    required this.onFilterChanged,
    required this.onClearAll,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Text(
            'Notifications',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (unreadCount > 0) ...[
            const SizedBox(width: 8),
            Chip(
              label: Text('$unreadCount unread'),
              visualDensity: VisualDensity.compact,
            ),
          ],
          const Spacer(),
          if (pairedDevices.length > 1)
            DropdownButton<String?>(
              value: filterDevice,
              hint: const Text('All devices'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All devices')),
                ...pairedDevices.map(
                  (d) => DropdownMenuItem(value: d.id, child: Text(d.name)),
                ),
              ],
              onChanged: onFilterChanged,
            ),
          const SizedBox(width: 8),
          TextButton(onPressed: onClearAll, child: const Text('Clear All')),
        ],
      ),
    );
  }
}

class _NotifTile extends StatefulWidget {
  final NotificationItem notification;
  final VoidCallback onDismiss;
  final VoidCallback onMarkRead;
  final ValueChanged<String> onReply;

  const _NotifTile({
    required this.notification,
    required this.onDismiss,
    required this.onMarkRead,
    required this.onReply,
  });

  @override
  State<_NotifTile> createState() => _NotifTileState();
}

class _NotifTileState extends State<_NotifTile> {
  bool _showReply = false;
  final _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    final appIcon = _appIcon(n.packageName);

    return Dismissible(
      key: Key(n.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => widget.onDismiss(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        color: n.isRead ? null : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey.shade200,
                child: Icon(appIcon, size: 20),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      n.appName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  Text(
                    _formatTime(n.timestamp),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (n.title.isNotEmpty)
                    Text(n.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(n.message, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'read') widget.onMarkRead();
                  if (v == 'dismiss') widget.onDismiss();
                  if (v == 'reply') setState(() => _showReply = !_showReply);
                },
                itemBuilder: (_) => [
                  if (!n.isRead)
                    const PopupMenuItem(value: 'read', child: Text('Mark as Read')),
                  if (n.canReply)
                    const PopupMenuItem(value: 'reply', child: Text('Reply')),
                  const PopupMenuItem(value: 'dismiss', child: Text('Dismiss')),
                ],
              ),
            ),
            if (_showReply)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        decoration: const InputDecoration(
                          hintText: 'Type a reply...',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (text) {
                          if (text.isNotEmpty) {
                            widget.onReply(text);
                            _replyController.clear();
                            setState(() => _showReply = false);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: () {
                        if (_replyController.text.isNotEmpty) {
                          widget.onReply(_replyController.text);
                          _replyController.clear();
                          setState(() => _showReply = false);
                        }
                      },
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _appIcon(String packageName) {
    if (packageName.contains('whatsapp')) return Icons.chat;
    if (packageName.contains('line')) return Icons.chat_bubble;
    if (packageName.contains('gmail') || packageName.contains('email')) return Icons.email;
    if (packageName.contains('sms') || packageName.contains('mms')) return Icons.sms;
    if (packageName.contains('messenger')) return Icons.messenger;
    return Icons.notifications;
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day) return DateFormat('HH:mm').format(dt);
    return DateFormat('MMM d').format(dt);
  }
}
