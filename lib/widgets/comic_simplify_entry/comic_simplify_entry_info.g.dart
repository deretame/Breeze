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
  from: $enumDecode(_$FromEnumMap, json['from']),
);

Map<String, dynamic> _$ComicSimplifyEntryInfoToJson(
  _ComicSimplifyEntryInfo instance,
) => <String, dynamic>{
  'title': instance.title,
  'id': instance.id,
  'fileServer': instance.fileServer,
  'path': instance.path,
  'pictureType': _$PictureTypeEnumMap[instance.pictureType]!,
  'from': _$FromEnumMap[instance.from]!,
};

const _$PictureTypeEnumMap = {
  PictureType.comic: 'comic',
  PictureType.cover: 'cover',
  PictureType.creator: 'creator',
  PictureType.favourite: 'favourite',
  PictureType.user: 'user',
  PictureType.category: 'category',
  PictureType.avatar: 'avatar',
  PictureType.unknown: 'unknown',
};

const _$FromEnumMap = {
  From.bika: 'bika',
  From.jm: 'jm',
  From.unknown: 'unknown',
};
