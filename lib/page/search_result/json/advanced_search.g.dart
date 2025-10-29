// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'advanced_search.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AdvancedSearch _$AdvancedSearchFromJson(Map<String, dynamic> json) =>
    _AdvancedSearch(
      code: (json['code'] as num).toInt(),
      message: json['message'] as String,
      data: Data.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AdvancedSearchToJson(_AdvancedSearch instance) =>
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
  total: (json['total'] as num).toInt(),
  page: (json['page'] as num).toInt(),
  pages: (json['pages'] as num).toInt(),
  docs: (json['docs'] as List<dynamic>)
      .map((e) => Doc.fromJson(e as Map<String, dynamic>))
      .toList(),
  limit: (json['limit'] as num).toInt(),
);

Map<String, dynamic> _$ComicsToJson(_Comics instance) => <String, dynamic>{
  'total': instance.total,
  'page': instance.page,
  'pages': instance.pages,
  'docs': instance.docs,
  'limit': instance.limit,
};

_Doc _$DocFromJson(Map<String, dynamic> json) => _Doc(
  updatedAt: DateTime.parse(json['updated_at'] as String),
  thumb: Thumb.fromJson(json['thumb'] as Map<String, dynamic>),
  author: json['author'] as String,
  description: json['description'] as String,
  chineseTeam: json['chineseTeam'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  finished: json['finished'] as bool,
  categories: (json['categories'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  title: json['title'] as String,
  tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
  id: json['_id'] as String,
  likesCount: (json['likesCount'] as num).toInt(),
);

Map<String, dynamic> _$DocToJson(_Doc instance) => <String, dynamic>{
  'updated_at': instance.updatedAt.toIso8601String(),
  'thumb': instance.thumb,
  'author': instance.author,
  'description': instance.description,
  'chineseTeam': instance.chineseTeam,
  'created_at': instance.createdAt.toIso8601String(),
  'finished': instance.finished,
  'categories': instance.categories,
  'title': instance.title,
  'tags': instance.tags,
  '_id': instance.id,
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
