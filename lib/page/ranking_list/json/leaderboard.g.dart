// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leaderboard.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Leaderboard _$LeaderboardFromJson(Map<String, dynamic> json) => _Leaderboard(
  code: (json['code'] as num).toInt(),
  message: json['message'] as String,
  data: Data.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$LeaderboardToJson(_Leaderboard instance) =>
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
  author: json['author'] as String,
  totalViews: (json['totalViews'] as num).toInt(),
  totalLikes: (json['totalLikes'] as num).toInt(),
  pagesCount: (json['pagesCount'] as num).toInt(),
  epsCount: (json['epsCount'] as num).toInt(),
  finished: json['finished'] as bool,
  categories: (json['categories'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  thumb: Thumb.fromJson(json['thumb'] as Map<String, dynamic>),
  viewsCount: (json['viewsCount'] as num).toInt(),
  leaderboardCount: (json['leaderboardCount'] as num).toInt(),
);

Map<String, dynamic> _$ComicToJson(_Comic instance) => <String, dynamic>{
  '_id': instance.id,
  'title': instance.title,
  'author': instance.author,
  'totalViews': instance.totalViews,
  'totalLikes': instance.totalLikes,
  'pagesCount': instance.pagesCount,
  'epsCount': instance.epsCount,
  'finished': instance.finished,
  'categories': instance.categories,
  'thumb': instance.thumb,
  'viewsCount': instance.viewsCount,
  'leaderboardCount': instance.leaderboardCount,
};

_Thumb _$ThumbFromJson(Map<String, dynamic> json) => _Thumb(
  fileServer: json['fileServer'] as String,
  path: json['path'] as String,
  originalName: json['originalName'] as String,
);

Map<String, dynamic> _$ThumbToJson(_Thumb instance) => <String, dynamic>{
  'fileServer': instance.fileServer,
  'path': instance.path,
  'originalName': instance.originalName,
};
