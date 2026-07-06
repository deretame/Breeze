// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unified_comic_list_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UnifiedComicListItem _$UnifiedComicListItemFromJson(
  Map<String, dynamic> json,
) => _UnifiedComicListItem(
  source: stringFromDynamic(json['source']),
  id: stringFromDynamic(json['id']),
  title: stringFromDynamic(json['title']),
  subtitle: stringFromDynamic(json['subtitle']),
  finished: boolFromDynamic(json['finished']),
  likesCount: intFromDynamic(json['likesCount']),
  viewsCount: intFromDynamic(json['viewsCount']),
  updatedAt: stringFromDynamic(json['updatedAt']),
  cover: _coverFromDynamic(json['cover']),
  metadata: _metadataListFromDynamic(json['metadata']),
  raw: mapFromDynamic(json['raw']),
  extern: mapFromDynamic(json['extern']),
);

Map<String, dynamic> _$UnifiedComicListItemToJson(
  _UnifiedComicListItem instance,
) => <String, dynamic>{
  'source': instance.source,
  'id': instance.id,
  'title': instance.title,
  'subtitle': instance.subtitle,
  'finished': instance.finished,
  'likesCount': instance.likesCount,
  'viewsCount': instance.viewsCount,
  'updatedAt': instance.updatedAt,
  'cover': _coverToDynamic(instance.cover),
  'metadata': _metadataListToDynamic(instance.metadata),
  'raw': instance.raw,
  'extern': instance.extern,
};

_UnifiedComicCover _$UnifiedComicCoverFromJson(Map<String, dynamic> json) =>
    _UnifiedComicCover(
      id: stringFromDynamic(json['id']),
      url: stringFromDynamic(json['url']),
      path: stringFromDynamic(json['path']),
      extern: mapFromDynamic(json['extern']),
    );

Map<String, dynamic> _$UnifiedComicCoverToJson(_UnifiedComicCover instance) =>
    <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'path': instance.path,
      'extern': instance.extern,
    };

_UnifiedComicMetadata _$UnifiedComicMetadataFromJson(
  Map<String, dynamic> json,
) => _UnifiedComicMetadata(
  type: stringFromDynamic(json['type']),
  name: stringFromDynamic(json['name']),
  value: _metadataValueFromDynamic(json['value']),
);

Map<String, dynamic> _$UnifiedComicMetadataToJson(
  _UnifiedComicMetadata instance,
) => <String, dynamic>{
  'type': instance.type,
  'name': instance.name,
  'value': instance.value,
};
