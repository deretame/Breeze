import 'package:zephyr/util/json/json_value.dart';

/// 新插件详情页数据：`getPluginDetail` 返回体。
/// `describe` 支持 md 渲染。
class PluginDetail {
  const PluginDetail({
    required this.source,
    required this.describe,
    this.creatorName = '',
    this.creatorDescribe = '',
    this.creatorIconUrl = '',
    this.home = '',
  });

  final String source;
  final String describe;
  final String creatorName;
  final String creatorDescribe;
  final String creatorIconUrl;
  final String home;

  factory PluginDetail.fromMap(Map<String, dynamic> map) {
    final data = asJsonMap(map['data']);
    final creator = asJsonMap(data['creator']);
    return PluginDetail(
      source: map['source']?.toString().trim() ?? '',
      describe: data['describe']?.toString().trim() ?? '',
      creatorName: creator['name']?.toString().trim() ?? '',
      creatorDescribe: creator['describe']?.toString().trim() ?? '',
      creatorIconUrl: creator['iconUrl']?.toString().trim() ?? '',
      home: data['home']?.toString().trim() ?? '',
    );
  }

  /// 主页：详情 `home` 为空时回退 getInfo 缓存的 `home`。
  String homeWithFallback(String cachedHome) {
    if (home.isNotEmpty) return home;
    return cachedHome.trim();
  }
}
