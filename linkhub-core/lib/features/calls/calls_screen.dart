import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/protocol/messages.dart';
import '../../core/websocket/ws_client.dart';

class CallsScreen extends ConsumerWidget {
  const CallsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final call = ref.watch(activeCallProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Text(
            'Calls',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        if (call != null)
          _ActiveCallCard(call: call)
        else
          const Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone_disabled, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No active call'),
                  SizedBox(height: 8),
                  Text(
                    'Incoming calls from your paired phones will appear here.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ActiveCallCard extends ConsumerStatefulWidget {
  final CallInfo call;
  const _ActiveCallCard({required this.call});

  @override
  ConsumerState<_ActiveCallCard> createState() => _ActiveCallCardState();
}

class _ActiveCallCardState extends ConsumerState<_ActiveCallCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _sendAction(String action) {
    final ws = ref.read(wsClientProvider.notifier);
    ws.sendMessage(
      PhoneHubMessage(
        type: MessageType.callAction,
        deviceId: widget.call.deviceId,
        payload: {'id': widget.call.id, 'action': action},
      ),
      widget.call.deviceId,
    );
    if (action == 'reject' || action == 'end') {
      ref.read(activeCallProvider.notifier).clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final call = widget.call;
    final isIncoming = call.state == CallState.incoming;
    final isActive = call.state == CallState.active;

    return Center(
      child: SizedBox(
        width: 360,
        child: Card(
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isIncoming)
                  Text(
                    'Incoming Call',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.green,
                        ),
                  )
                else if (isActive)
                  Text(
                    'On Call',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.blue,
                        ),
                  ),
                const SizedBox(height: 16),
                ScaleTransition(
                  scale: isIncoming ? _pulseAnim : const AlwaysStoppedAnimation(1),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.blueGrey.shade100,
                    child: Text(
                      _initials(call.callerName),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  call.callerName.isEmpty ? 'Unknown' : call.callerName,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  call.phoneNumber,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const SizedBox(height: 32),
                if (isIncoming)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _CallButton(
                        icon: Icons.call_end,
                        color: Colors.red,
                        label: 'Reject',
                        onTap: () => _sendAction('reject'),
                      ),
                      _CallButton(
                        icon: Icons.call,
                        color: Colors.green,
                        label: 'Accept',
                        onTap: () => _sendAction('accept'),
                      ),
                    ],
                  )
                else if (isActive)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _CallButton(
                        icon: call.isMuted ? Icons.mic_off : Icons.mic,
                        color: call.isMuted ? Colors.orange : Colors.grey,
                        label: call.isMuted ? 'Unmute' : 'Mute',
                        onTap: () => _sendAction(call.isMuted ? 'unmute' : 'mute'),
                      ),
                      _CallButton(
                        icon: Icons.call_end,
                        color: Colors.red,
                        label: 'End',
                        onTap: () => _sendAction('end'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class _CallButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _CallButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }
}
