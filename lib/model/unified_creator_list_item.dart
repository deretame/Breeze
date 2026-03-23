import 'package:zephyr/type/enum.dart';

class UnifiedCreatorListItem {
  const UnifiedCreatorListItem({
    required this.source,
    required this.id,
    required this.name,
    required this.subtitle,
    required this.avatar,
    required this.stats,
    required this.raw,
    required this.extra,
  });

  final String source;
  final String id;
  final String name;
  final String subtitle;
  final UnifiedCreatorAvatar avatar;
  final List<String> stats;
  final Map<String, dynamic> raw;
  final Map<String, dynamic> extra;

  factory UnifiedCreatorListItem.fromJson(Map<String, dynamic> json) {
    return UnifiedCreatorListItem(
      source: json['source']?.toString() ?? '',
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      avatar: UnifiedCreatorAvatar.fromJson(_asMap(json['avatar'])),
      stats: _asList(json['stats']).map((item) => item.toString()).toList(),
      raw: _asMap(json['raw']),
      extra: _asMap(json['extra']),
    );
  }

  From get from {
    return switch (source) {
      'bika' => From.bika,
      'jm' => From.jm,
      _ => From.unknown,
    };
  }

  String get searchUrl => extra['searchUrl']?.toString() ?? '';
}

class UnifiedCreatorAvatar {
  const UnifiedCreatorAvatar({required this.url, required this.path});

  final String url;
  final String path;

  factory UnifiedCreatorAvatar.fromJson(Map<String, dynamic> json) {
    return UnifiedCreatorAvatar(
      url: json['url']?.toString() ?? '',
      path: json['path']?.toString() ?? '',
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.fromEntries(
      value.entries.map((entry) => MapEntry(entry.key.toString(), entry.value)),
    );
  }
  return const <String, dynamic>{};
}

List<dynamic> _asList(dynamic value) {
  if (value is List) {
    return value;
  }
  return const <dynamic>[];
}
