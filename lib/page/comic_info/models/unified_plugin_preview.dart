import 'package:zephyr/util/json/json_value.dart';

class UnifiedPluginPreviewPaging {
  const UnifiedPluginPreviewPaging({
    required this.page,
    required this.pages,
    required this.total,
    required this.hasReachedMax,
  });

  final int page;
  final int pages;
  final int total;
  final bool hasReachedMax;

  factory UnifiedPluginPreviewPaging.fromMap(Map<String, dynamic> map) {
    return UnifiedPluginPreviewPaging(
      page: _toInt(map['page'], 1),
      pages: _toInt(map['pages'], 1),
      total: _toInt(map['total'], 0),
      hasReachedMax: map['hasReachedMax'] == true,
    );
  }
}

class UnifiedPluginPreviewItem {
  const UnifiedPluginPreviewItem({
    required this.id,
    required this.name,
    required this.path,
    required this.url,
    required this.extern,
  });

  final String id;
  final String name;
  final String path;
  final String url;
  final Map<String, dynamic> extern;

  factory UnifiedPluginPreviewItem.fromMap(Map<String, dynamic> map) {
    final thumbnail = asJsonMap(map['thumbnail']);
    final image = asJsonMap(map['image']);
    final source = thumbnail.isNotEmpty
        ? thumbnail
        : image.isNotEmpty
        ? image
        : map;
    return UnifiedPluginPreviewItem(
      id: map['id']?.toString() ?? '',
      name:
          map['name']?.toString() ??
          source['name']?.toString() ??
          map['originalName']?.toString() ??
          '',
      path: source['path']?.toString() ?? '',
      url: source['url']?.toString() ?? source['fileServer']?.toString() ?? '',
      extern: asJsonMap(map['extern']),
    );
  }
}

class UnifiedPluginPreviewResponse {
  const UnifiedPluginPreviewResponse({
    required this.source,
    required this.comicId,
    required this.extern,
    required this.scheme,
    required this.paging,
    required this.items,
  });

  final String source;
  final String comicId;
  final Map<String, dynamic> extern;
  final Map<String, dynamic> scheme;
  final UnifiedPluginPreviewPaging paging;
  final List<UnifiedPluginPreviewItem> items;

  factory UnifiedPluginPreviewResponse.fromMap(Map<String, dynamic> map) {
    final data = asJsonMap(map['data']);
    final preview = data.isNotEmpty ? asJsonMap(data['preview']) : const {};
    final body = preview.isNotEmpty
        ? preview
        : data.isNotEmpty
        ? data
        : map;
    final items = asJsonList(
      body['items'],
    ).map((item) => UnifiedPluginPreviewItem.fromMap(asJsonMap(item))).toList();

    return UnifiedPluginPreviewResponse(
      source: map['source']?.toString() ?? '',
      comicId: map['comicId']?.toString() ?? '',
      extern: asJsonMap(map['extern']),
      scheme: asJsonMap(map['scheme']),
      paging: UnifiedPluginPreviewPaging.fromMap(asJsonMap(body['paging'])),
      items: items,
    );
  }
}

int _toInt(dynamic value, int fallback) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
