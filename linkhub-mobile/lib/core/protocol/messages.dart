import 'dart:convert';

enum MessageType {
  // Pairing
  pairRequest,
  pairResponse,
  pairAck,
  ping,
  pong,
  // Device status
  deviceStatus,
  // Notifications
  notificationNew,
  notificationDismiss,
  notificationAction,
  // Calls
  callIncoming,
  callStateChange,
  callAction,
  // SMS
  smsList,
  smsNew,
  smsSend,
  smsSearch,
  // Clipboard
  clipboardSync,
  // Discovery
  discoveryBroadcast,
  discoveryResponse,
}

class PhoneHubMessage {
  final MessageType type;
  final String deviceId;
  final int timestamp;
  final Map<String, dynamic> payload;

  PhoneHubMessage({
    required this.type,
    required this.deviceId,
    required this.payload,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  factory PhoneHubMessage.fromJson(Map<String, dynamic> json) {
    return PhoneHubMessage(
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.ping,
      ),
      deviceId: json['deviceId'] as String? ?? '',
      timestamp: json['timestamp'] as int? ?? 0,
      payload: json['payload'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'deviceId': deviceId,
    'timestamp': timestamp,
    'payload': payload,
  };

  String toJsonString() => jsonEncode(toJson());
}

class DeviceInfo {
  final String id;
  final String name;
  final int batteryLevel;
  final bool isCharging;
  final bool wifiConnected;
  final String wifiName;
  final int signalStrength;
  final int storageUsed;
  final int storageTotal;
  final String ipAddress;
  final bool isConnected;
  final DateTime lastSeen;

  DeviceInfo({
    required this.id,
    required this.name,
    required this.batteryLevel,
    required this.isCharging,
    required this.wifiConnected,
    required this.wifiName,
    required this.signalStrength,
    required this.storageUsed,
    required this.storageTotal,
    required this.ipAddress,
    required this.isConnected,
    required this.lastSeen,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) => DeviceInfo(
    id: json['id'] as String,
    name: json['name'] as String? ?? 'Unknown Device',
    batteryLevel: json['batteryLevel'] as int? ?? 0,
    isCharging: json['isCharging'] as bool? ?? false,
    wifiConnected: json['wifiConnected'] as bool? ?? false,
    wifiName: json['wifiName'] as String? ?? '',
    signalStrength: json['signalStrength'] as int? ?? 0,
    storageUsed: json['storageUsed'] as int? ?? 0,
    storageTotal: json['storageTotal'] as int? ?? 0,
    ipAddress: json['ipAddress'] as String? ?? '',
    isConnected: json['isConnected'] as bool? ?? false,
    lastSeen: DateTime.fromMillisecondsSinceEpoch(
      json['lastSeen'] as int? ?? 0,
    ),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'batteryLevel': batteryLevel,
    'isCharging': isCharging,
    'wifiConnected': wifiConnected,
    'wifiName': wifiName,
    'signalStrength': signalStrength,
    'storageUsed': storageUsed,
    'storageTotal': storageTotal,
    'ipAddress': ipAddress,
    'isConnected': isConnected,
    'lastSeen': lastSeen.millisecondsSinceEpoch,
  };

  DeviceInfo copyWith({bool? isConnected, DateTime? lastSeen}) => DeviceInfo(
    id: id,
    name: name,
    batteryLevel: batteryLevel,
    isCharging: isCharging,
    wifiConnected: wifiConnected,
    wifiName: wifiName,
    signalStrength: signalStrength,
    storageUsed: storageUsed,
    storageTotal: storageTotal,
    ipAddress: ipAddress,
    isConnected: isConnected ?? this.isConnected,
    lastSeen: lastSeen ?? this.lastSeen,
  );
}

class NotificationItem {
  final String id;
  final String deviceId;
  final String appName;
  final String packageName;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final bool canReply;
  final List<String> actions;

  NotificationItem({
    required this.id,
    required this.deviceId,
    required this.appName,
    required this.packageName,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
    required this.canReply,
    required this.actions,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      NotificationItem(
        id: json['id'] as String,
        deviceId: json['deviceId'] as String? ?? '',
        appName: json['appName'] as String? ?? '',
        packageName: json['packageName'] as String? ?? '',
        title: json['title'] as String? ?? '',
        message: json['message'] as String? ?? '',
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          json['timestamp'] as int? ?? 0,
        ),
        isRead: json['isRead'] as bool? ?? false,
        canReply: json['canReply'] as bool? ?? false,
        actions: (json['actions'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
    id: id,
    deviceId: deviceId,
    appName: appName,
    packageName: packageName,
    title: title,
    message: message,
    timestamp: timestamp,
    isRead: isRead ?? this.isRead,
    canReply: canReply,
    actions: actions,
  );
}

enum CallState { incoming, active, ended, rejected, missed }

class CallInfo {
  final String id;
  final String deviceId;
  final String callerName;
  final String phoneNumber;
  final CallState state;
  final DateTime timestamp;
  final bool isMuted;

  CallInfo({
    required this.id,
    required this.deviceId,
    required this.callerName,
    required this.phoneNumber,
    required this.state,
    required this.timestamp,
    required this.isMuted,
  });

  factory CallInfo.fromJson(Map<String, dynamic> json) => CallInfo(
    id: json['id'] as String,
    deviceId: json['deviceId'] as String? ?? '',
    callerName: json['callerName'] as String? ?? 'Unknown',
    phoneNumber: json['phoneNumber'] as String? ?? '',
    state: CallState.values.firstWhere(
      (e) => e.name == json['state'],
      orElse: () => CallState.incoming,
    ),
    timestamp: DateTime.fromMillisecondsSinceEpoch(
      json['timestamp'] as int? ?? 0,
    ),
    isMuted: json['isMuted'] as bool? ?? false,
  );

  CallInfo copyWith({CallState? state, bool? isMuted}) => CallInfo(
    id: id,
    deviceId: deviceId,
    callerName: callerName,
    phoneNumber: phoneNumber,
    state: state ?? this.state,
    timestamp: timestamp,
    isMuted: isMuted ?? this.isMuted,
  );
}

class SmsMessage {
  final String id;
  final String deviceId;
  final String address;
  final String contactName;
  final String body;
  final bool isIncoming;
  final bool isRead;
  final DateTime timestamp;

  SmsMessage({
    required this.id,
    required this.deviceId,
    required this.address,
    required this.contactName,
    required this.body,
    required this.isIncoming,
    required this.isRead,
    required this.timestamp,
  });

  factory SmsMessage.fromJson(Map<String, dynamic> json) => SmsMessage(
    id: json['id'] as String,
    deviceId: json['deviceId'] as String? ?? '',
    address: json['address'] as String? ?? '',
    contactName: json['contactName'] as String? ?? '',
    body: json['body'] as String? ?? '',
    isIncoming: json['isIncoming'] as bool? ?? true,
    isRead: json['isRead'] as bool? ?? false,
    timestamp: DateTime.fromMillisecondsSinceEpoch(
      json['timestamp'] as int? ?? 0,
    ),
  );
}

class PairedDevice {
  final String id;
  final String name;
  final String ipAddress;
  final int port;
  final String pairingToken;
  final DateTime pairedAt;

  PairedDevice({
    required this.id,
    required this.name,
    required this.ipAddress,
    required this.port,
    required this.pairingToken,
    required this.pairedAt,
  });

  factory PairedDevice.fromJson(Map<String, dynamic> json) => PairedDevice(
    id: json['id'] as String,
    name: json['name'] as String? ?? 'Unknown',
    ipAddress: json['ipAddress'] as String,
    port: json['port'] as int? ?? 8765,
    pairingToken: json['pairingToken'] as String,
    pairedAt: DateTime.fromMillisecondsSinceEpoch(
      json['pairedAt'] as int? ?? 0,
    ),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'ipAddress': ipAddress,
    'port': port,
    'pairingToken': pairingToken,
    'pairedAt': pairedAt.millisecondsSinceEpoch,
  };
}
