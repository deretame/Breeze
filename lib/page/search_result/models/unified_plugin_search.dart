import 'package:zephyr/util/json/json_value.dart';

class UnifiedPluginSearchPaging {
  const UnifiedPluginSearchPaging({
    required this.page,
    required this.pages,
    required this.total,
    required this.hasReachedMax,
  });

  final int page;
  final int pages;
  final int total;
  final bool hasReachedMax;

  factory UnifiedPluginSearchPaging.fromMap(Map<String, dynamic> map) {
    return UnifiedPluginSearchPaging(
      page: _toInt(map['page'], 1),
      pages: _toInt(map['pages'], 1),
      total: _toInt(map['total'], 0),
      hasReachedMax: map['hasReachedMax'] == true,
    );
  }
}

class UnifiedPluginSearchItem {
  const UnifiedPluginSearchItem({
    required this.id,
    required this.title,
    required this.data,
    required this.raw,
  });

  final String id;
  final String title;
  final Map<String, dynamic> data;
  final Map<String, dynamic> raw;

  factory UnifiedPluginSearchItem.fromMap(Map<String, dynamic> map) {
    return UnifiedPluginSearchItem(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      data: asJsonMap(map),
      raw: asJsonMap(map['raw']),
    );
  }
}

class UnifiedPluginSearchResponse {
  const UnifiedPluginSearchResponse({
    required this.source,
    required this.extern,
    required this.paging,
    required this.items,
  });

  final String source;
  final Map<String, dynamic> extern;
  final UnifiedPluginSearchPaging paging;
  final List<UnifiedPluginSearchItem> items;

  factory UnifiedPluginSearchResponse.fromMap(Map<String, dynamic> map) {
    final data = asJsonMap(map['data']);
    final pagingMap = data.isNotEmpty
        ? asJsonMap(data['paging'])
        : asJsonMap(map['paging']);
    final itemsRaw = data.isNotEmpty
        ? asJsonList(data['items'])
        : asJsonList(map['items']);

    final itemList = itemsRaw
        .map((item) => UnifiedPluginSearchItem.fromMap(asJsonMap(item)))
        .toList();

    return UnifiedPluginSearchResponse(
      source: map['source']?.toString() ?? '',
      extern: asJsonMap(map['extern']),
      paging: UnifiedPluginSearchPaging.fromMap(pagingMap),
      items: itemList,
    );
  }
}

int _toInt(dynamic value, int fallback) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
