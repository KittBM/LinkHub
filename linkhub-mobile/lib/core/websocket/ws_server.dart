import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../protocol/messages.dart';
import '../security/encryption.dart';

class ClientSession {
  final String id;
  final WebSocketChannel channel;
  String? deviceId;
  Uint8List? encryptionKey;
  bool authenticated = false;

  ClientSession({required this.id, required this.channel});
}

class WsServerNotifier extends StateNotifier<bool> {
  WsServerNotifier() : super(false);

  final _enc = EncryptionService();
  final Map<String, ClientSession> _clients = {};
  final _messageController = StreamController<PhoneHubMessage>.broadcast();
  Stream<PhoneHubMessage> get messageStream => _messageController.stream;

  dynamic _server;
  String? _pairingToken;

  void setPairingToken(String token) => _pairingToken = token;

  Future<void> start({int port = 8765}) async {
    final handler = webSocketHandler((WebSocketChannel channel, String? protocol) {
      final session = ClientSession(
        id: const Uuid().v4(),
        channel: channel,
      );
      _clients[session.id] = session;

      channel.stream.listen(
        (data) => _onData(session, data as String),
        onDone: () => _clients.remove(session.id),
        onError: (_) => _clients.remove(session.id),
      );
    });

    _server = await shelf_io.serve(handler, '0.0.0.0', port);
    state = true;
  }

  void _onData(ClientSession session, String rawData) {
    try {
      String jsonStr = rawData;
      if (session.encryptionKey != null && !rawData.startsWith('{')) {
        jsonStr = _enc.decrypt(rawData, session.encryptionKey!);
      }
      final msg = PhoneHubMessage.fromJson(jsonDecode(jsonStr));

      // Handle pairing handshake
      if (msg.type == MessageType.pairRequest) {
        _handlePairRequest(session, msg);
        return;
      }

      if (!session.authenticated) return;
      _messageController.add(msg);
    } catch (_) {}
  }

  void _handlePairRequest(ClientSession session, PhoneHubMessage msg) {
    final token = msg.payload['token'] as String?;
    final deviceId = msg.payload['deviceId'] as String?;
    if (token == null || deviceId == null) return;

    if (_pairingToken != null && token != _pairingToken) {
      _send(session, PhoneHubMessage(
        type: MessageType.pairResponse,
        deviceId: '',
        payload: {'success': false, 'reason': 'Invalid token'},
      ), null);
      return;
    }

    session.deviceId = deviceId;
    session.authenticated = true;
    session.encryptionKey = _enc.deriveKey(token, deviceId);

    _send(session, PhoneHubMessage(
      type: MessageType.pairResponse,
      deviceId: '',
      payload: {'success': true},
    ), null);
  }

  void broadcast(PhoneHubMessage msg) {
    for (final session in _clients.values) {
      if (session.authenticated) {
        _send(session, msg, session.encryptionKey);
      }
    }
  }

  void _send(ClientSession session, PhoneHubMessage msg, Uint8List? key) {
    try {
      final json = msg.toJsonString();
      if (key != null) {
        session.channel.sink.add(_enc.encrypt(json, key));
      } else {
        session.channel.sink.add(json);
      }
    } catch (_) {}
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    state = false;
  }

  @override
  void dispose() {
    stop();
    _messageController.close();
    super.dispose();
  }
}

final wsServerProvider = StateNotifierProvider<WsServerNotifier, bool>(
  (_) => WsServerNotifier(),
);
