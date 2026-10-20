import 'package:shared_preferences/shared_preferences.dart';

/// 第一页 / 第二页各自独立的本机插件选中记忆，不进 ObjectBox。
class PluginHomeMemory {
  PluginHomeMemory._();

  static const String homePluginKey = 'homePluginId';
  static const String cloudFavoritePluginKey = 'cloudFavoritePluginId';

  static String? _cachedHomePluginId;
  static String? _cachedCloudFavoritePluginId;
  static bool _loaded = false;

  static Future<void> _ensureLoaded() async {
    if (_loaded) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    _cachedHomePluginId = prefs.getString(homePluginKey);
    _cachedCloudFavoritePluginId = prefs.getString(cloudFavoritePluginKey);
    _loaded = true;
  }

  static Future<String?> readHomePluginId() async {
    await _ensureLoaded();
    return _cachedHomePluginId;
  }

  static Future<String?> readCloudFavoritePluginId() async {
    await _ensureLoaded();
    return _cachedCloudFavoritePluginId;
  }

  static Future<void> writeHomePluginId(String pluginId) async {
    _cachedHomePluginId = pluginId;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(homePluginKey, pluginId);
  }

  static Future<void> writeCloudFavoritePluginId(String pluginId) async {
    _cachedCloudFavoritePluginId = pluginId;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(cloudFavoritePluginKey, pluginId);
  }
}
