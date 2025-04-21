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
  pictureType: json['pictureType'] as String,
  from: json['from'] as String,
);

Map<String, dynamic> _$ComicSimplifyEntryInfoToJson(
  _ComicSimplifyEntryInfo instance,
) => <String, dynamic>{
  'title': instance.title,
  'id': instance.id,
  'fileServer': instance.fileServer,
  'path': instance.path,
  'pictureType': instance.pictureType,
  'from': instance.from,
};
