import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_info.dart';
import 'package:zephyr/type/enum.dart';

class UnifiedComicListItem {
  const UnifiedComicListItem({
    required this.source,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.finished,
    required this.likesCount,
    required this.viewsCount,
    required this.updatedAt,
    required this.cover,
    required this.metadata,
    required this.raw,
    required this.extern,
  });

  final String source;
  final String id;
  final String title;
  final String subtitle;
  final bool finished;
  final int likesCount;
  final int viewsCount;
  final String updatedAt;
  final UnifiedComicCover cover;
  final List<UnifiedComicMetadata> metadata;
  final Map<String, dynamic> raw;
  final Map<String, dynamic> extern;

  factory UnifiedComicListItem.fromJson(Map<String, dynamic> json) {
    if (json['cover'] is! Map || json['metadata'] is! List) {
      throw const FormatException('Invalid UnifiedComicListItem payload');
    }
    return UnifiedComicListItem(
      source: json['source']?.toString() ?? '',
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      finished: json['finished'] == true,
      likesCount: _toInt(json['likesCount']),
      viewsCount: _toInt(json['viewsCount']),
      updatedAt: json['updatedAt']?.toString() ?? '',
      cover: UnifiedComicCover.fromJson(_asMap(json['cover'])),
      metadata: _asList(
        json['metadata'],
      ).map((item) => UnifiedComicMetadata.fromJson(_asMap(item))).toList(),
      raw: _asMap(json['raw']),
      extern: _asMap(json['extern']),
    );
  }

  Map<String, dynamic> toJson() => {
    'source': source,
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'finished': finished,
    'likesCount': likesCount,
    'viewsCount': viewsCount,
    'updatedAt': updatedAt,
    'cover': cover.toJson(),
    'metadata': metadata.map((item) => item.toJson()).toList(),
    'raw': raw,
    'extern': extern,
  };

  String get from {
    return (source).trim();
  }

  List<String> metadataValues(String type) {
    for (final item in metadata) {
      if (item.type == type) {
        return item.value;
      }
    }
    return const <String>[];
  }

  String get primaryText {
    if (subtitle.trim().isNotEmpty) {
      return subtitle.trim();
    }

    final author = metadataValues('author').join(' / ').trim();
    if (author.isNotEmpty) {
      return author;
    }

    return '';
  }

  String get secondaryText {
    final lines = <String>[];
    for (final item in metadata) {
      if (item.value.isEmpty || item.type == 'author') {
        continue;
      }
      final value = item.value.join(' / ').trim();
      if (value.isEmpty) {
        continue;
      }
      final label = item.name.trim().isEmpty ? item.type : item.name.trim();
      lines.add('$label: $value');
      if (lines.length >= 2) {
        break;
      }
    }
    return lines.join('  ');
  }

  String get updatedAtText => updatedAt.trim();

  ComicSimplifyEntryInfo toSimplifyEntryInfo({
    PictureType pictureType = PictureType.cover,
  }) {
    return ComicSimplifyEntryInfo(
      title: title,
      id: id,
      fileServer: cover.url,
      path: cover.cachePath,
      pictureType: pictureType,
      source: (source).trim(),
      from: from,
    );
  }
}

class UnifiedComicCover {
  const UnifiedComicCover({
    required this.id,
    required this.url,
    required this.extern,
  });

  final String id;
  final String url;
  final Map<String, dynamic> extern;

  factory UnifiedComicCover.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) {
      throw const FormatException('Invalid UnifiedComicCover payload');
    }
    return UnifiedComicCover(
      id: json['id']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      extern: _asMap(json['extern']),
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'url': url, 'extern': extern};

  String get cachePath {
    return extern['path']?.toString().trim() ?? '';
  }
}

class UnifiedComicMetadata {
  const UnifiedComicMetadata({
    required this.type,
    required this.name,
    required this.value,
  });

  final String type;
  final String name;
  final List<String> value;

  factory UnifiedComicMetadata.fromJson(Map<String, dynamic> json) {
    return UnifiedComicMetadata(
      type: json['type']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      value: _asList(json['value']).map((item) => item.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {'type': type, 'name': name, 'value': value};
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

int _toInt(dynamic value) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
