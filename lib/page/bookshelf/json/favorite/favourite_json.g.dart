// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favourite_json.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FavouriteJson _$FavouriteJsonFromJson(Map<String, dynamic> json) =>
    _FavouriteJson(
      code: (json['code'] as num).toInt(),
      message: json['message'] as String,
      data: Data.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FavouriteJsonToJson(_FavouriteJson instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'data': instance.data,
    };

_Data _$DataFromJson(Map<String, dynamic> json) =>
    _Data(comics: Comics.fromJson(json['comics'] as Map<String, dynamic>));

Map<String, dynamic> _$DataToJson(_Data instance) => <String, dynamic>{
  'comics': instance.comics,
};

_Comics _$ComicsFromJson(Map<String, dynamic> json) => _Comics(
  pages: (json['pages'] as num).toInt(),
  total: (json['total'] as num).toInt(),
  docs:
      (json['docs'] as List<dynamic>)
          .map((e) => Doc.fromJson(e as Map<String, dynamic>))
          .toList(),
  page: (json['page'] as num).toInt(),
  limit: (json['limit'] as num).toInt(),
);

Map<String, dynamic> _$ComicsToJson(_Comics instance) => <String, dynamic>{
  'pages': instance.pages,
  'total': instance.total,
  'docs': instance.docs,
  'page': instance.page,
  'limit': instance.limit,
};

_Doc _$DocFromJson(Map<String, dynamic> json) => _Doc(
  id: json['_id'] as String,
  title: json['title'] as String,
  author: json['author'] as String,
  totalViews: (json['totalViews'] as num).toInt(),
  totalLikes: (json['totalLikes'] as num).toInt(),
  pagesCount: (json['pagesCount'] as num).toInt(),
  epsCount: (json['epsCount'] as num).toInt(),
  finished: json['finished'] as bool,
  categories:
      (json['categories'] as List<dynamic>).map((e) => e as String).toList(),
  thumb: Thumb.fromJson(json['thumb'] as Map<String, dynamic>),
  likesCount: (json['likesCount'] as num).toInt(),
);

Map<String, dynamic> _$DocToJson(_Doc instance) => <String, dynamic>{
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
  'likesCount': instance.likesCount,
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
