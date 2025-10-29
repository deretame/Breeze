// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommend_json.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RecommendJson _$RecommendJsonFromJson(Map<String, dynamic> json) =>
    _RecommendJson(
      code: (json['code'] as num).toInt(),
      message: json['message'] as String,
      data: Data.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RecommendJsonToJson(_RecommendJson instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'data': instance.data,
    };

_Data _$DataFromJson(Map<String, dynamic> json) => _Data(
  comics: (json['comics'] as List<dynamic>)
      .map((e) => Comic.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DataToJson(_Data instance) => <String, dynamic>{
  'comics': instance.comics,
};

_Comic _$ComicFromJson(Map<String, dynamic> json) => _Comic(
  id: json['_id'] as String,
  title: json['title'] as String,
  thumb: Thumb.fromJson(json['thumb'] as Map<String, dynamic>),
  author: json['author'] as String,
  categories: (json['categories'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  finished: json['finished'] as bool,
  epsCount: (json['epsCount'] as num).toInt(),
  pagesCount: (json['pagesCount'] as num).toInt(),
  likesCount: (json['likesCount'] as num).toInt(),
);

Map<String, dynamic> _$ComicToJson(_Comic instance) => <String, dynamic>{
  '_id': instance.id,
  'title': instance.title,
  'thumb': instance.thumb,
  'author': instance.author,
  'categories': instance.categories,
  'finished': instance.finished,
  'epsCount': instance.epsCount,
  'pagesCount': instance.pagesCount,
  'likesCount': instance.likesCount,
};

_Thumb _$ThumbFromJson(Map<String, dynamic> json) => _Thumb(
  originalName: json['originalName'] as String,
  path: json['path'] as String,
  fileServer: json['fileServer'] as String,
);

Map<String, dynamic> _$ThumbToJson(_Thumb instance) => <String, dynamic>{
  'originalName': instance.originalName,
  'path': instance.path,
  'fileServer': instance.fileServer,
};
