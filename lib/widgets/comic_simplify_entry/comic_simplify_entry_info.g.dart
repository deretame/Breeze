// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comic_simplify_entry_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ComicSimplifyEntryInfo _$ComicSimplifyEntryInfoFromJson(
  Map<String, dynamic> json,
) => _ComicSimplifyEntryInfo(
  title: json['title'] as String,
  id: json['id'] as String,
  fileServer: json['fileServer'] as String,
  path: json['path'] as String,
  pictureType: $enumDecode(_$PictureTypeEnumMap, json['pictureType']),
  source: json['source'] as String? ?? '',
  from: json['from'] as String,
  author: json['author'] as String? ?? '',
  metadata:
      (json['metadata'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$ComicSimplifyEntryInfoToJson(
  _ComicSimplifyEntryInfo instance,
) => <String, dynamic>{
  'title': instance.title,
  'id': instance.id,
  'fileServer': instance.fileServer,
  'path': instance.path,
  'pictureType': _$PictureTypeEnumMap[instance.pictureType]!,
  'source': instance.source,
  'from': instance.from,
  'author': instance.author,
  'metadata': instance.metadata,
};

const _$PictureTypeEnumMap = {
  PictureType.comic: 'comic',
  PictureType.cover: 'cover',
  PictureType.creator: 'creator',
  PictureType.favourite: 'favourite',
  PictureType.user: 'user',
  PictureType.category: 'category',
  PictureType.avatar: 'avatar',
  PictureType.page: 'page',
  PictureType.unknown: 'unknown',
};
