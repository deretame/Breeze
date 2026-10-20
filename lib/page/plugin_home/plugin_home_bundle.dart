import 'package:zephyr/page/comic_list/models/comic_list_scene.dart';
import 'package:zephyr/util/json/json_value.dart';

/// 插件首页 / 云端收藏 bundle 的单个 tab。
///
/// 线格式复用现有规约，不写新渲染器：
/// - `scene` 走 [ComicListScene]，由 ComicList 现成渲染管线消费；
/// - `page` 为 FunctionPageContract 的 scheme + data，走 DiscoverSchemeRenderer；
/// - `header.actions` 为插件 action 列表，Dart 统一经由 DiscoverRouter 路由。
class PluginHomeTab {
  const PluginHomeTab({
    required this.id,
    required this.title,
    this.scene,
    this.pageScheme = const <String, dynamic>{},
    this.pageData = const <String, dynamic>{},
    this.headerActions = const <Map<String, dynamic>>[],
  });

  final String id;
  final String title;
  final ComicListScene? scene;
  final Map<String, dynamic> pageScheme;
  final Map<String, dynamic> pageData;
  final List<Map<String, dynamic>> headerActions;

  bool get isScene => scene != null;
  bool get isPage => scene == null;

  factory PluginHomeTab.fromMap(Map<String, dynamic> map, String pluginId) {
    final id =
        map['id']?.toString().trim() ?? map['key']?.toString().trim() ?? '';
    final title = map['title']?.toString().trim() ?? '';

    ComicListScene? scene;
    final sceneMap = asJsonMap(map['scene']);
    if (sceneMap.isNotEmpty) {
      final normalized = Map<String, dynamic>.from(sceneMap);
      if ((normalized['source']?.toString() ?? '').trim().isEmpty) {
        normalized['source'] = pluginId;
      }
      scene = ComicListScene.fromMap(normalized);
    }

    final pageMap = asJsonMap(map['page']);
    final headerMap = asJsonMap(map['header']);
    // bika 新 bundle 的 header 包了层 {id,title,action}：取内层 action 供路由消费。
    final rawActions = asJsonListOfMaps(
      headerMap['actions'] ?? map['actions'],
    ).toList();
    final headerActions = rawActions.map((item) {
      final inner = asJsonMap(item['action']);
      return inner.isNotEmpty ? inner : item;
    }).toList();

    return PluginHomeTab(
      id: id,
      title: title,
      scene: scene,
      pageScheme: asJsonMap(pageMap['scheme']),
      pageData: asJsonMap(pageMap['data']),
      headerActions: headerActions,
    );
  }
}

/// `getPluginHomePagesBundle / getPluginCloudFavoritePagesBundle` 返回体。
///
/// envelope 结构：`{source, scheme, data: {pages/tabs: [...]}, extern}`，
/// data 下兼容 `pages` 与 `tabs` 两种键。
class PluginHomeBundle {
  const PluginHomeBundle({required this.pluginId, required this.tabs});

  final String pluginId;
  final List<PluginHomeTab> tabs;

  bool get isEmpty => tabs.isEmpty;

  factory PluginHomeBundle.fromResponse(
    Map<String, dynamic> response,
    String pluginId,
  ) {
    final data = asJsonMap(response['data']);
    var rawTabs = asJsonList(data['pages']);
    if (rawTabs.isEmpty) {
      rawTabs = asJsonList(data['tabs']);
    }
    final tabs = <PluginHomeTab>[];
    for (var i = 0; i < rawTabs.length; i++) {
      final tabMap = asJsonMap(rawTabs[i]);
      if (tabMap.isEmpty) {
        continue;
      }
      final tab = PluginHomeTab.fromMap(tabMap, pluginId);
      tabs.add(
        tab.id.isEmpty
            ? PluginHomeTab(
                id: 'tab_$i',
                title: tab.title,
                scene: tab.scene,
                pageScheme: tab.pageScheme,
                pageData: tab.pageData,
                headerActions: tab.headerActions,
              )
            : tab,
      );
    }
    return PluginHomeBundle(pluginId: pluginId, tabs: tabs);
  }
}
