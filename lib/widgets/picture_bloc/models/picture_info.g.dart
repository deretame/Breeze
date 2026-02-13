// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'picture_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PictureInfo _$PictureInfoFromJson(Map<String, dynamic> json) => _PictureInfo(
  from: $enumDecodeNullable(_$FromEnumMap, json['from']) ?? From.bika,
  url: json['url'] as String? ?? '',
  path: json['path'] as String? ?? '',
  cartoonId: json['cartoonId'] as String? ?? '',
  chapterId: json['chapterId'] as String? ?? '',
  pictureType:
      $enumDecodeNullable(_$PictureTypeEnumMap, json['pictureType']) ??
      PictureType.comic,
);

Map<String, dynamic> _$PictureInfoToJson(_PictureInfo instance) =>
    <String, dynamic>{
      'from': _$FromEnumMap[instance.from]!,
      'url': instance.url,
      'path': instance.path,
      'cartoonId': instance.cartoonId,
      'chapterId': instance.chapterId,
      'pictureType': _$PictureTypeEnumMap[instance.pictureType]!,
    };

const _$FromEnumMap = {
  From.bika: 'bika',
  From.jm: 'jm',
  From.unknown: 'unknown',
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
