import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:zephyr/cs/domain/cs_connection_settings.dart';

class CsConnectionStore {
  const CsConnectionStore({this.key = _defaultKey});

  static const _defaultKey = 'breeze.cs.connection-settings.v1';

  final String key;

  Future<CsConnectionSettings> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(key);
    if (raw == null || raw.trim().isEmpty) {
      return const CsConnectionSettings();
    }
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return const CsConnectionSettings();
      return CsConnectionSettings.fromJson(Map<String, dynamic>.from(json));
    } on Object {
      return const CsConnectionSettings();
    }
  }

  Future<void> save(CsConnectionSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(key, jsonEncode(settings.toJson()));
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(key);
  }
}
