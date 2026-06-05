import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../protocol/messages.dart';

class HiveStorage {
  static const String _pairedDevicesBox = 'paired_devices';
  static const String _notificationsBox = 'notifications';
  static const String _smsBox = 'sms_messages';
  static const String _settingsBox = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_pairedDevicesBox);
    await Hive.openBox(_notificationsBox);
    await Hive.openBox(_smsBox);
    await Hive.openBox(_settingsBox);
  }

  // Paired devices
  static Future<void> savePairedDevice(PairedDevice device) async {
    final box = Hive.box(_pairedDevicesBox);
    await box.put(device.id, jsonEncode(device.toJson()));
  }

  static Future<void> removePairedDevice(String deviceId) async {
    final box = Hive.box(_pairedDevicesBox);
    await box.delete(deviceId);
  }

  static List<PairedDevice> getPairedDevices() {
    final box = Hive.box(_pairedDevicesBox);
    return box.values
        .map((v) => PairedDevice.fromJson(jsonDecode(v as String)))
        .toList();
  }

  // Notifications
  static Future<void> saveNotification(NotificationItem notification) async {
    final box = Hive.box(_notificationsBox);
    final data = {
      'id': notification.id,
      'deviceId': notification.deviceId,
      'appName': notification.appName,
      'packageName': notification.packageName,
      'title': notification.title,
      'message': notification.message,
      'timestamp': notification.timestamp.millisecondsSinceEpoch,
      'isRead': notification.isRead,
      'canReply': notification.canReply,
      'actions': notification.actions,
    };
    await box.put(notification.id, jsonEncode(data));
  }

  static List<NotificationItem> getNotifications() {
    final box = Hive.box(_notificationsBox);
    final items = box.values
        .map((v) => NotificationItem.fromJson(jsonDecode(v as String)))
        .toList();
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  static Future<void> clearNotifications() async {
    await Hive.box(_notificationsBox).clear();
  }

  // SMS
  static Future<void> saveSms(SmsMessage sms) async {
    final box = Hive.box(_smsBox);
    final data = {
      'id': sms.id,
      'deviceId': sms.deviceId,
      'address': sms.address,
      'contactName': sms.contactName,
      'body': sms.body,
      'isIncoming': sms.isIncoming,
      'isRead': sms.isRead,
      'timestamp': sms.timestamp.millisecondsSinceEpoch,
    };
    await box.put(sms.id, jsonEncode(data));
  }

  static List<SmsMessage> getSmsMessages() {
    final box = Hive.box(_smsBox);
    final items = box.values
        .map((v) => SmsMessage.fromJson(jsonDecode(v as String)))
        .toList();
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  // Settings
  static Future<void> setSetting(String key, dynamic value) async {
    await Hive.box(_settingsBox).put(key, value);
  }

  static T? getSetting<T>(String key) {
    return Hive.box(_settingsBox).get(key) as T?;
  }
}
