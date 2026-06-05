import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/protocol/messages.dart';
import '../core/security/encryption.dart';
import '../core/websocket/ws_server.dart';

// Agent device ID (stable)
final agentDeviceIdProvider = Provider<String>((ref) {
  // Generated once and persisted
  return 'agent-device-1';
});

// Pairing info
class PairingState {
  final String deviceId;
  final String pairingToken;
  final String pin;
  final bool isPaired;

  PairingState({
    required this.deviceId,
    required this.pairingToken,
    required this.pin,
    required this.isPaired,
  });

  PairingState copyWith({bool? isPaired}) => PairingState(
    deviceId: deviceId,
    pairingToken: pairingToken,
    pin: pin,
    isPaired: isPaired ?? this.isPaired,
  );
}

final pairingStateProvider = StateNotifierProvider<PairingNotifier, PairingState>(
  (ref) => PairingNotifier(),
);

class PairingNotifier extends StateNotifier<PairingState> {
  PairingNotifier()
    : super(PairingState(
        deviceId: 'agent-${DateTime.now().millisecondsSinceEpoch}',
        pairingToken: EncryptionService.generatePairingToken(),
        pin: EncryptionService.generatePin(),
        isPaired: false,
      ));

  void regenerate() {
    state = PairingState(
      deviceId: state.deviceId,
      pairingToken: EncryptionService.generatePairingToken(),
      pin: EncryptionService.generatePin(),
      isPaired: false,
    );
  }

  void markPaired() => state = state.copyWith(isPaired: true);
}

// Platform method channel for native Android services
const _channel = MethodChannel('com.linkhub/agent');

class AgentServiceNotifier extends StateNotifier<AgentServiceState> {
  AgentServiceNotifier() : super(AgentServiceState.initial());

  Future<void> startForegroundService() async {
    try {
      await _channel.invokeMethod('startForegroundService');
      state = state.copyWith(foregroundRunning: true);
    } catch (_) {
      state = state.copyWith(foregroundRunning: true); // Fallback for non-Android
    }
  }

  Future<void> stopForegroundService() async {
    try {
      await _channel.invokeMethod('stopForegroundService');
    } catch (_) {}
    state = state.copyWith(foregroundRunning: false);
  }

  void update(AgentServiceState s) => state = s;
}

class AgentServiceState {
  final bool foregroundRunning;
  final bool notificationListenerEnabled;
  final bool accessibilityEnabled;

  AgentServiceState({
    required this.foregroundRunning,
    required this.notificationListenerEnabled,
    required this.accessibilityEnabled,
  });

  factory AgentServiceState.initial() => AgentServiceState(
    foregroundRunning: false,
    notificationListenerEnabled: false,
    accessibilityEnabled: false,
  );

  AgentServiceState copyWith({
    bool? foregroundRunning,
    bool? notificationListenerEnabled,
    bool? accessibilityEnabled,
  }) => AgentServiceState(
    foregroundRunning: foregroundRunning ?? this.foregroundRunning,
    notificationListenerEnabled:
        notificationListenerEnabled ?? this.notificationListenerEnabled,
    accessibilityEnabled: accessibilityEnabled ?? this.accessibilityEnabled,
  );
}

final agentServiceProvider =
    StateNotifierProvider<AgentServiceNotifier, AgentServiceState>(
  (_) => AgentServiceNotifier(),
);

// Message handler — processes commands from tablet
class CommandHandler {
  final Ref _ref;
  StreamSubscription? _sub;

  CommandHandler(this._ref) {
    final server = _ref.read(wsServerProvider.notifier);
    _sub = server.messageStream.listen(_handle);
  }

  void _handle(PhoneHubMessage msg) {
    switch (msg.type) {
      case MessageType.notificationAction:
        _handleNotifAction(msg);
      case MessageType.callAction:
        _handleCallAction(msg);
      case MessageType.smsSend:
        _sendSms(msg);
      case MessageType.clipboardSync:
        _setClipboard(msg);
      default:
        break;
    }
  }

  void _handleNotifAction(PhoneHubMessage msg) {
    _channel.invokeMethod('notificationAction', {
      'id': msg.payload['id'],
      'action': msg.payload['action'],
      'text': msg.payload['text'],
    });
  }

  void _handleCallAction(PhoneHubMessage msg) {
    _channel.invokeMethod('callAction', {
      'id': msg.payload['id'],
      'action': msg.payload['action'],
    });
  }

  void _sendSms(PhoneHubMessage msg) {
    _channel.invokeMethod('sendSms', {
      'to': msg.payload['to'],
      'body': msg.payload['body'],
    });
  }

  Future<void> _setClipboard(PhoneHubMessage msg) async {
    final text = msg.payload['text'] as String?;
    if (text != null) {
      await Clipboard.setData(ClipboardData(text: text));
    }
  }

  void dispose() => _sub?.cancel();
}

final commandHandlerProvider = Provider<CommandHandler>((ref) {
  final handler = CommandHandler(ref);
  ref.onDispose(handler.dispose);
  return handler;
});
