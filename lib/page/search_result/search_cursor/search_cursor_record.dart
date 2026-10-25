/// 搜索游标记录与插件支持表。
///
/// 游标以锚点为唯一性单位：同一关键词可以挂多个游标（不同漫画），
/// 对同一 (pluginId, keyword, sortBy, anchorComicId) 重新添加时覆盖。
///
/// 定位算法假设“最新优先”排序近似按排序键降序、且排序键出现在
/// 响应条目里。各插件排序参数与键字段不同（JM: extern sortBy=1 +
/// update_at Unix 秒；Bika: extern sortBy=1 + updated_at ISO 8601），
/// 统一收敛在 [searchCursorPlugins] 支持表里。
library;

class SearchCursorRecord {
  const SearchCursorRecord({
    required this.pluginId,
    required this.keyword,
    required this.sortBy,
    required this.anchorComicId,
    required this.anchorUpdateAt,
    required this.anchorPage,
    required this.createdAt,
    this.anchorTitle = '',
    this.extern = const <String, dynamic>{},
  });

  /// 插件 id。
  final String pluginId;

  /// 搜索关键词（trim 后）。
  final String keyword;

  /// 排序方式（应用层 SearchStates.sortBy，需等于该插件“最新优先”的值）。
  final int sortBy;

  /// 锚点漫画 id。
  final String anchorComicId;

  /// 锚点漫画标题（列表展示用，区分同关键词的多个游标）。
  final String anchorTitle;

  /// 锚点漫画记录游标时的排序键归一化值（Unix 秒）。
  final int anchorUpdateAt;

  /// 记录游标时锚点所在的页码（仅作定位初始参考）。
  final int anchorPage;

  /// 记录时间（毫秒时间戳）。
  final int createdAt;

  /// 记录游标时的完整搜索 extern（含 sortBy、分类筛选等）。
  /// 探测与跳转必须复现同一 extern，否则结果集不一致、定位失效。
  final Map<String, dynamic> extern;

  Map<String, dynamic> toJson() => {
    'pluginId': pluginId,
    'keyword': keyword,
    'sortBy': sortBy,
    'anchorComicId': anchorComicId,
    'anchorTitle': anchorTitle,
    'anchorUpdateAt': anchorUpdateAt,
    'anchorPage': anchorPage,
    'createdAt': createdAt,
    'extern': extern,
  };

  static SearchCursorRecord? fromJson(dynamic value) {
    if (value is! Map) return null;
    final map = Map<String, dynamic>.from(value);
    final pluginId = map['pluginId']?.toString() ?? '';
    final keyword = map['keyword']?.toString().trim() ?? '';
    final anchorComicId = map['anchorComicId']?.toString() ?? '';
    if (pluginId.isEmpty || keyword.isEmpty || anchorComicId.isEmpty) {
      return null;
    }
    final externRaw = map['extern'];
    return SearchCursorRecord(
      pluginId: pluginId,
      keyword: keyword,
      sortBy: int.tryParse(map['sortBy']?.toString() ?? '') ?? 1,
      anchorComicId: anchorComicId,
      anchorTitle: map['anchorTitle']?.toString() ?? '',
      anchorUpdateAt:
          int.tryParse(map['anchorUpdateAt']?.toString() ?? '') ?? 0,
      anchorPage: int.tryParse(map['anchorPage']?.toString() ?? '') ?? 1,
      createdAt: int.tryParse(map['createdAt']?.toString() ?? '') ?? 0,
      extern: externRaw is Map
          ? externRaw.map((key, item) => MapEntry(key.toString(), item))
          : const <String, dynamic>{},
    );
  }
}

/// 禁漫插件 UUID（与 rust/src/qjs/mod.rs 中 JM_PLUGIN_UUID 一致）。
const String jmComicPluginUuid = 'bf99008d-010b-4f17-ac7c-61a9b57dc3d9';

/// 哔咔插件 UUID（与 rust/src/qjs/mod.rs 中 BIKA_PLUGIN_UUID 一致）。
const String bikaComicPluginUuid = '0a0e5858-a467-4702-994a-79e608a4589d';

/// 单个插件的游标支持描述。
class SearchCursorPluginSupport {
  const SearchCursorPluginSupport({
    required this.pluginId,
    required this.newestSortBy,
    required this.sortKeyOf,
  });

  /// 插件 id。
  final String pluginId;

  /// 该插件高级搜索 scheme 中“最新优先”排序对应的 sortBy 值。
  final int newestSortBy;

  /// 从搜索条目 raw 提取排序键，归一化为 Unix 秒（缺失为 0，视为最旧）。
  final int Function(Map<String, dynamic> raw) sortKeyOf;
}

int _jmSortKey(Map<String, dynamic> raw) {
  return int.tryParse(raw['update_at']?.toString() ?? '') ?? 0;
}

int _bikaSortKey(Map<String, dynamic> raw) {
  final text = raw['updated_at']?.toString() ?? '';
  final dateTime = DateTime.tryParse(text);
  return dateTime == null ? 0 : dateTime.millisecondsSinceEpoch ~/ 1000;
}

/// 支持游标的插件表。新增插件在此登记即可。
final Map<String, SearchCursorPluginSupport> searchCursorPlugins = {
  jmComicPluginUuid: SearchCursorPluginSupport(
    pluginId: jmComicPluginUuid,
    newestSortBy: 1,
    sortKeyOf: _jmSortKey,
  ),
  bikaComicPluginUuid: SearchCursorPluginSupport(
    pluginId: bikaComicPluginUuid,
    newestSortBy: 1,
    sortKeyOf: _bikaSortKey,
  ),
};

/// 兼容旧引用：JM 的“最新优先”排序值。
const int searchCursorSupportedSortBy = 1;

/// 是否为纯关键词搜索的 extern（不含 url/mode/creatorId 等特殊入口，
/// 这些入口的结果列表不是关键词序，游标无意义）。
bool isPlainKeywordExtern(Map<String, dynamic> extern) {
  for (final key in const ['url', 'mode', 'creatorId']) {
    final value = extern[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) return false;
  }
  return true;
}

/// 游标定位默认探测预算（最多发起的搜索请求数）。
const int defaultSearchCursorProbeBudget = 8;

/// 游标定位探测预算上限。
const int maxSearchCursorProbeBudget = 10;

/// 游标定位相邻探测请求的最小间隔。
const Duration searchCursorProbeInterval = Duration(milliseconds: 500);
