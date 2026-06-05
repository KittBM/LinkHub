import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/protocol/messages.dart';
import '../core/storage/hive_storage.dart';
import '../core/websocket/ws_client.dart';

// Paired devices
final pairedDevicesProvider = StateNotifierProvider<PairedDevicesNotifier, List<PairedDevice>>(
  (ref) => PairedDevicesNotifier(),
);

class PairedDevicesNotifier extends StateNotifier<List<PairedDevice>> {
  PairedDevicesNotifier() : super(HiveStorage.getPairedDevices());

  Future<void> add(PairedDevice device) async {
    await HiveStorage.savePairedDevice(device);
    state = HiveStorage.getPairedDevices();
  }

  Future<void> remove(String deviceId) async {
    await HiveStorage.removePairedDevice(deviceId);
    state = HiveStorage.getPairedDevices();
  }
}

// Connected device states (live info)
final deviceStatusProvider = StateNotifierProvider<DeviceStatusNotifier, Map<String, DeviceInfo>>(
  (ref) {
    final notifier = DeviceStatusNotifier();
    // Listen to messages
    final ws = ref.read(wsClientProvider.notifier);
    notifier._sub = ws.messageStream.listen((msg) {
      if (msg.type == MessageType.deviceStatus) {
        final info = DeviceInfo.fromJson({...msg.payload, 'id': msg.deviceId});
        notifier.update(info);
      }
    });
    return notifier;
  },
);

class DeviceStatusNotifier extends StateNotifier<Map<String, DeviceInfo>> {
  DeviceStatusNotifier() : super({});
  StreamSubscription? _sub;

  void update(DeviceInfo info) {
    state = {...state, info.id: info};
  }

  void markDisconnected(String deviceId) {
    final existing = state[deviceId];
    if (existing != null) {
      state = {...state, deviceId: existing.copyWith(isConnected: false)};
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// Notifications
final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<NotificationItem>>(
  (ref) {
    final notifier = NotificationsNotifier();
    final ws = ref.read(wsClientProvider.notifier);
    notifier._sub = ws.messageStream.listen((msg) {
      if (msg.type == MessageType.notificationNew) {
        final n = NotificationItem.fromJson({...msg.payload, 'deviceId': msg.deviceId});
        notifier.add(n);
      } else if (msg.type == MessageType.notificationDismiss) {
        notifier.dismiss(msg.payload['id'] as String);
      }
    });
    return notifier;
  },
);

class NotificationsNotifier extends StateNotifier<List<NotificationItem>> {
  NotificationsNotifier() : super(HiveStorage.getNotifications());
  StreamSubscription? _sub;

  void add(NotificationItem n) {
    HiveStorage.saveNotification(n);
    state = [n, ...state.where((e) => e.id != n.id)];
  }

  void markRead(String id) {
    state = state.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
  }

  void dismiss(String id) {
    state = state.where((n) => n.id != id).toList();
  }

  Future<void> clearAll() async {
    await HiveStorage.clearNotifications();
    state = [];
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// Calls
final activeCallProvider = StateNotifierProvider<ActiveCallNotifier, CallInfo?>(
  (ref) {
    final notifier = ActiveCallNotifier();
    final ws = ref.read(wsClientProvider.notifier);
    notifier._sub = ws.messageStream.listen((msg) {
      if (msg.type == MessageType.callIncoming) {
        notifier.setCall(CallInfo.fromJson({...msg.payload, 'deviceId': msg.deviceId}));
      } else if (msg.type == MessageType.callStateChange) {
        notifier.updateState(
          msg.payload['id'] as String? ?? '',
          CallState.values.firstWhere(
            (e) => e.name == msg.payload['state'],
            orElse: () => CallState.ended,
          ),
        );
      }
    });
    return notifier;
  },
);

class ActiveCallNotifier extends StateNotifier<CallInfo?> {
  ActiveCallNotifier() : super(null);
  StreamSubscription? _sub;

  void setCall(CallInfo call) => state = call;

  void updateState(String id, CallState s) {
    if (state?.id == id) {
      if (s == CallState.ended || s == CallState.rejected) {
        state = null;
      } else {
        state = state!.copyWith(state: s);
      }
    }
  }

  void clear() => state = null;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// SMS
final smsProvider = StateNotifierProvider<SmsNotifier, List<SmsMessage>>(
  (ref) {
    final notifier = SmsNotifier();
    final ws = ref.read(wsClientProvider.notifier);
    notifier._sub = ws.messageStream.listen((msg) {
      if (msg.type == MessageType.smsList) {
        final list = (msg.payload['messages'] as List<dynamic>?)
                ?.map((e) => SmsMessage.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        notifier.setAll(list);
      } else if (msg.type == MessageType.smsNew) {
        notifier.add(SmsMessage.fromJson({...msg.payload, 'deviceId': msg.deviceId}));
      }
    });
    return notifier;
  },
);

class SmsNotifier extends StateNotifier<List<SmsMessage>> {
  SmsNotifier() : super(HiveStorage.getSmsMessages());
  StreamSubscription? _sub;

  void setAll(List<SmsMessage> list) {
    for (final sms in list) {
      HiveStorage.saveSms(sms);
    }
    state = HiveStorage.getSmsMessages();
  }

  void add(SmsMessage sms) {
    HiveStorage.saveSms(sms);
    state = [sms, ...state.where((e) => e.id != sms.id)];
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// Clipboard
final clipboardSyncProvider = StateNotifierProvider<ClipboardSyncNotifier, String>(
  (ref) {
    final notifier = ClipboardSyncNotifier();
    final ws = ref.read(wsClientProvider.notifier);
    notifier._sub = ws.messageStream.listen((msg) {
      if (msg.type == MessageType.clipboardSync) {
        notifier.set(msg.payload['text'] as String? ?? '');
      }
    });
    return notifier;
  },
);

class ClipboardSyncNotifier extends StateNotifier<String> {
  ClipboardSyncNotifier() : super('');
  StreamSubscription? _sub;

  void set(String text) => state = text;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// Selected device tab
final selectedDeviceProvider = StateProvider<String?>((ref) => null);
