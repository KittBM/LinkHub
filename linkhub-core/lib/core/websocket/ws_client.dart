import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../protocol/messages.dart';
import '../security/encryption.dart';

enum WsConnectionState { disconnected, connecting, connected, error }

class DeviceConnection {
  final PairedDevice device;
  WsConnectionState state;
  WebSocketChannel? channel;
  StreamSubscription? subscription;
  Uint8List? encryptionKey;
  int reconnectAttempts = 0;
  Timer? reconnectTimer;

  DeviceConnection({required this.device, this.state = WsConnectionState.disconnected});
}

class WsClientNotifier extends StateNotifier<Map<String, DeviceConnection>> {
  WsClientNotifier() : super({});

  final _messageController = StreamController<PhoneHubMessage>.broadcast();
  Stream<PhoneHubMessage> get messageStream => _messageController.stream;

  final _enc = EncryptionService();

  Future<void> connect(PairedDevice device) async {
    final conn = DeviceConnection(device: device);
    state = {...state, device.id: conn};

    _doConnect(conn);
  }

  void _doConnect(DeviceConnection conn) {
    conn.state = WsConnectionState.connecting;
    state = {...state, conn.device.id: conn};

    try {
      final uri = Uri.parse('ws://${conn.device.ipAddress}:${conn.device.port}');
      conn.channel = WebSocketChannel.connect(uri);
      conn.encryptionKey = _enc.deriveKey(
        conn.device.pairingToken,
        conn.device.id,
      );

      conn.subscription = conn.channel!.stream.listen(
        (data) => _onData(conn, data as String),
        onError: (_) => _onDisconnect(conn),
        onDone: () => _onDisconnect(conn),
      );

      // Send ping to verify connection
      sendMessage(
        PhoneHubMessage(
          type: MessageType.ping,
          deviceId: conn.device.id,
          payload: {},
        ),
        conn.device.id,
      );

      conn.state = WsConnectionState.connected;
      conn.reconnectAttempts = 0;
      state = {...state, conn.device.id: conn};
    } catch (_) {
      _onDisconnect(conn);
    }
  }

  void _onData(DeviceConnection conn, String rawData) {
    try {
      String jsonStr = rawData;
      if (conn.encryptionKey != null && !rawData.startsWith('{')) {
        jsonStr = _enc.decrypt(rawData, conn.encryptionKey!);
      }
      final msg = PhoneHubMessage.fromJson(jsonDecode(jsonStr));
      _messageController.add(msg);
    } catch (_) {}
  }

  void _onDisconnect(DeviceConnection conn) {
    conn.state = WsConnectionState.disconnected;
    conn.subscription?.cancel();
    conn.channel = null;
    state = {...state, conn.device.id: conn};
    _scheduleReconnect(conn);
  }

  void _scheduleReconnect(DeviceConnection conn) {
    if (conn.reconnectAttempts >= 10) return;
    final delay = Duration(seconds: 2 * (conn.reconnectAttempts + 1));
    conn.reconnectTimer?.cancel();
    conn.reconnectTimer = Timer(delay, () {
      conn.reconnectAttempts++;
      _doConnect(conn);
    });
  }

  void sendMessage(PhoneHubMessage msg, String deviceId) {
    final conn = state[deviceId];
    if (conn == null || conn.channel == null) return;
    try {
      final json = msg.toJsonString();
      if (conn.encryptionKey != null) {
        conn.channel!.sink.add(_enc.encrypt(json, conn.encryptionKey!));
      } else {
        conn.channel!.sink.add(json);
      }
    } catch (_) {}
  }

  void disconnect(String deviceId) {
    final conn = state[deviceId];
    if (conn == null) return;
    conn.reconnectTimer?.cancel();
    conn.subscription?.cancel();
    conn.channel?.sink.close();
    conn.state = WsConnectionState.disconnected;
    state = {...state, deviceId: conn};
  }

  @override
  void dispose() {
    for (final conn in state.values) {
      conn.reconnectTimer?.cancel();
      conn.subscription?.cancel();
      conn.channel?.sink.close();
    }
    _messageController.close();
    super.dispose();
  }
}

final wsClientProvider =
    StateNotifierProvider<WsClientNotifier, Map<String, DeviceConnection>>(
  (_) => WsClientNotifier(),
);
