import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class AgentStorage {
  static const _settingsBox = 'agent_settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_settingsBox);
  }

  static Future<void> set(String key, dynamic value) async {
    await Hive.box(_settingsBox).put(key, value);
  }

  static T? get<T>(String key) {
    return Hive.box(_settingsBox).get(key) as T?;
  }

  static Future<void> setJson(String key, Map<String, dynamic> value) async {
    await set(key, jsonEncode(value));
  }

  static Map<String, dynamic>? getJson(String key) {
    final raw = get<String>(key);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}
