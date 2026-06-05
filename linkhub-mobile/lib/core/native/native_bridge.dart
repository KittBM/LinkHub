import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../protocol/messages.dart';
import '../websocket/ws_server.dart';

const _channel = MethodChannel('com.linkhub/agent');

class NativeBridge {
  final WsServerNotifier _server;
  String _deviceId = '';

  NativeBridge(this._server);

  void init(String deviceId) {
    _deviceId = deviceId;
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onNotification':
        _onNotification(call.arguments as String);
      case 'onNotificationRemoved':
        _onNotificationRemoved(call.arguments as String);
      case 'onCallState':
        _onCallState(call.arguments as String);
      case 'onSmsReceived':
        _onSmsReceived(call.arguments as String);
      case 'onClipboardChanged':
        _onClipboardChanged(call.arguments as String);
    }
    return null;
  }

  void _onNotification(String json) {
    final data = jsonDecode(json) as Map<String, dynamic>;
    _server.broadcast(PhoneHubMessage(
      type: MessageType.notificationNew,
      deviceId: _deviceId,
      payload: data,
    ));
  }

  void _onNotificationRemoved(String key) {
    _server.broadcast(PhoneHubMessage(
      type: MessageType.notificationDismiss,
      deviceId: _deviceId,
      payload: {'id': key},
    ));
  }

  void _onCallState(String json) {
    final data = jsonDecode(json) as Map<String, dynamic>;
    final state = data['state'] as String;
    final type = state == 'incoming'
        ? MessageType.callIncoming
        : MessageType.callStateChange;
    _server.broadcast(PhoneHubMessage(
      type: type,
      deviceId: _deviceId,
      payload: data,
    ));
  }

  void _onSmsReceived(String json) {
    final data = jsonDecode(json) as Map<String, dynamic>;
    _server.broadcast(PhoneHubMessage(
      type: MessageType.smsNew,
      deviceId: _deviceId,
      payload: data,
    ));
  }

  void _onClipboardChanged(String text) {
    _server.broadcast(PhoneHubMessage(
      type: MessageType.clipboardSync,
      deviceId: _deviceId,
      payload: {'text': text},
    ));
  }

  Future<void> broadcastDeviceStatus() async {
    try {
      final result = await _channel.invokeMethod<Map>('getDeviceStatus');
      if (result == null) return;
      _server.broadcast(PhoneHubMessage(
        type: MessageType.deviceStatus,
        deviceId: _deviceId,
        payload: Map<String, dynamic>.from(result),
      ));
    } catch (_) {}
  }

  Future<void> sendSmsList() async {
    try {
      final result = await _channel.invokeMethod<List>('getSmsList');
      if (result == null) return;
      _server.broadcast(PhoneHubMessage(
        type: MessageType.smsList,
        deviceId: _deviceId,
        payload: {
          'messages': result.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        },
      ));
    } catch (_) {}
  }
}

final nativeBridgeProvider = Provider<NativeBridge>((ref) {
  final server = ref.read(wsServerProvider.notifier);
  return NativeBridge(server);
});
