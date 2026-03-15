import 'package:shared_preferences/shared_preferences.dart';

class DebugUrlSetting {
  static const String _bikaUrlKey = 'debug_bika_url';
  static const String _jmUrlKey = 'debug_jm_url';

  static String _bikaBaseUrl = "";
  static String _jmBaseUrl = '';

  static String get bikaBaseUrl => _bikaBaseUrl;
  static String get jmBaseUrl => _jmBaseUrl;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final bika = prefs.getString(_bikaUrlKey) ?? '';
    final jm = prefs.getString(_jmUrlKey) ?? '';

    _bikaBaseUrl = bika;
    _jmBaseUrl = jm;
  }

  static Future<void> saveBikaBaseUrl(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bikaUrlKey, value);
    _bikaBaseUrl = value;
  }

  static Future<void> saveJmBaseUrl(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_jmUrlKey, value);
    _jmBaseUrl = value;
  }

  static String formatForDisplay(String value, {required String fallback}) {
    return value.isEmpty ? fallback : value;
  }

  static String replaceBikaHost(String url) {
    if (_bikaBaseUrl == "" || url.isEmpty) {
      return url;
    }

    final oldBase = Uri.tryParse("");
    final newBase = Uri.tryParse(_bikaBaseUrl);
    final current = Uri.tryParse(url);

    if (oldBase == null || newBase == null || current == null) {
      return url;
    }

    if (current.host != oldBase.host) {
      return url;
    }

    return current
        .replace(
          scheme: newBase.scheme,
          host: newBase.host,
          port: newBase.hasPort ? newBase.port : null,
        )
        .toString();
  }
}
