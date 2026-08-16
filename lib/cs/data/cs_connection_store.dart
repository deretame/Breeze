import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zephyr/cs/domain/cs_connection_settings.dart';

class CsConnectionStore {
  const CsConnectionStore({this.key = _defaultKey});

  static const _defaultKey = 'breeze.cs.connection-settings.v1';
  static const _accessTokenSuffix = '.access-token';

  final String key;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<CsConnectionSettings> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(key);
    if (raw == null || raw.trim().isEmpty) {
      return const CsConnectionSettings();
    }
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return const CsConnectionSettings();
      final settings = CsConnectionSettings.fromJson(
        Map<String, dynamic>.from(json),
      );
      final accessToken = await _readAccessToken();
      return settings.copyWith(accessToken: accessToken);
    } on Object {
      return const CsConnectionSettings();
    }
  }

  Future<void> save(CsConnectionSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(key, jsonEncode(settings.toJson()));
    if (settings.accessToken case final token? when token.trim().isNotEmpty) {
      await _secureStorage.write(key: _accessTokenKey, value: token.trim());
    } else {
      await _secureStorage.delete(key: _accessTokenKey);
    }
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(key);
    await _secureStorage.delete(key: _accessTokenKey);
  }

  String get _accessTokenKey => '$key$_accessTokenSuffix';

  Future<String?> _readAccessToken() async {
    try {
      return await _secureStorage.read(key: _accessTokenKey);
    } on Object {
      return null;
    }
  }
}
