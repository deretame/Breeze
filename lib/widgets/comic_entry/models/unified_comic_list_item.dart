import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/json/json_value.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_info.dart';

part 'unified_comic_list_item.freezed.dart';
part 'unified_comic_list_item.g.dart';

@freezed
abstract class UnifiedComicListItem with _$UnifiedComicListItem {
  const factory UnifiedComicListItem({
    @JsonKey(fromJson: stringFromDynamic) required String source,
    @JsonKey(fromJson: stringFromDynamic) required String id,
    @JsonKey(fromJson: stringFromDynamic) required String title,
    @JsonKey(fromJson: stringFromDynamic) required String subtitle,
    @JsonKey(fromJson: boolFromDynamic) required bool finished,
    @JsonKey(fromJson: intFromDynamic) required int likesCount,
    @JsonKey(fromJson: intFromDynamic) required int viewsCount,
    @JsonKey(fromJson: stringFromDynamic) required String updatedAt,
    @JsonKey(fromJson: _coverFromDynamic, toJson: _coverToDynamic)
    required UnifiedComicCover cover,
    @JsonKey(fromJson: _metadataListFromDynamic, toJson: _metadataListToDynamic)
    required List<UnifiedComicMetadata> metadata,
    @JsonKey(fromJson: mapFromDynamic) required Map<String, dynamic> raw,
    @JsonKey(fromJson: mapFromDynamic) required Map<String, dynamic> extern,
  }) = _UnifiedComicListItem;

  const UnifiedComicListItem._();

  factory UnifiedComicListItem.fromJson(Map<String, dynamic> json) =>
      _$UnifiedComicListItemFromJson(json);

  String get from => source.trim();

  List<Object> metadataValues(String type) {
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
      source: source.trim(),
      from: from,
    );
  }
}

@freezed
abstract class UnifiedComicCover with _$UnifiedComicCover {
  const factory UnifiedComicCover({
    @JsonKey(fromJson: stringFromDynamic) required String id,
    @JsonKey(fromJson: stringFromDynamic) required String url,
    @JsonKey(fromJson: stringFromDynamic) required String path,
    @JsonKey(fromJson: mapFromDynamic) required Map<String, dynamic> extern,
  }) = _UnifiedComicCover;

  const UnifiedComicCover._();

  factory UnifiedComicCover.fromJson(Map<String, dynamic> json) =>
      _$UnifiedComicCoverFromJson(json);

  String get cachePath => path.trim();
}

@freezed
abstract class UnifiedComicMetadata with _$UnifiedComicMetadata {
  const factory UnifiedComicMetadata({
    @JsonKey(fromJson: stringFromDynamic) required String type,
    @JsonKey(fromJson: stringFromDynamic) required String name,
    @JsonKey(fromJson: _metadataValueFromDynamic) required List<Object> value,
  }) = _UnifiedComicMetadata;

  const UnifiedComicMetadata._();

  factory UnifiedComicMetadata.fromJson(Map<String, dynamic> json) =>
      _$UnifiedComicMetadataFromJson(json);
}

UnifiedComicCover _coverFromDynamic(dynamic value) {
  final json = asJsonMap(value);
  if (json.isEmpty) {
    throw const FormatException('Invalid UnifiedComicCover payload');
  }
  return UnifiedComicCover.fromJson(json);
}

Map<String, dynamic> _coverToDynamic(UnifiedComicCover cover) => cover.toJson();

List<UnifiedComicMetadata> _metadataListFromDynamic(dynamic value) =>
    asJsonList(
      value,
    ).map((item) => UnifiedComicMetadata.fromJson(asJsonMap(item))).toList();

List<Map<String, dynamic>> _metadataListToDynamic(
  List<UnifiedComicMetadata> metadata,
) => metadata.map((item) => item.toJson()).toList();

List<Object> _metadataValueFromDynamic(dynamic value) =>
    asJsonList(value).map((item) {
      if (item is Map) {
        return (item['name'] ?? item.toString()).toString();
      }
      return item.toString();
    }).toList();
