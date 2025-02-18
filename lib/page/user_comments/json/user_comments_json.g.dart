// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_comments_json.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserCommentsJsonImpl _$$UserCommentsJsonImplFromJson(
  Map<String, dynamic> json,
) => _$UserCommentsJsonImpl(
  code: (json['code'] as num).toInt(),
  message: json['message'] as String,
  data: Data.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$$UserCommentsJsonImplToJson(
  _$UserCommentsJsonImpl instance,
) => <String, dynamic>{
  'code': instance.code,
  'message': instance.message,
  'data': instance.data,
};

_$DataImpl _$$DataImplFromJson(Map<String, dynamic> json) => _$DataImpl(
  comments: Comments.fromJson(json['comments'] as Map<String, dynamic>),
);

Map<String, dynamic> _$$DataImplToJson(_$DataImpl instance) =>
    <String, dynamic>{'comments': instance.comments};

_$CommentsImpl _$$CommentsImplFromJson(Map<String, dynamic> json) =>
    _$CommentsImpl(
      docs:
          (json['docs'] as List<dynamic>)
              .map((e) => Doc.fromJson(e as Map<String, dynamic>))
              .toList(),
      total: (json['total'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      page: json['page'] as String,
      pages: (json['pages'] as num).toInt(),
    );

Map<String, dynamic> _$$CommentsImplToJson(_$CommentsImpl instance) =>
    <String, dynamic>{
      'docs': instance.docs,
      'total': instance.total,
      'limit': instance.limit,
      'page': instance.page,
      'pages': instance.pages,
    };

_$DocImpl _$$DocImplFromJson(Map<String, dynamic> json) => _$DocImpl(
  id: json['_id'] as String,
  content: json['content'] as String,
  comic: Comic.fromJson(json['_comic'] as Map<String, dynamic>),
  totalComments: (json['totalComments'] as num).toInt(),
  hide: json['hide'] as bool,
  createdAt: DateTime.parse(json['created_at'] as String),
  docId: json['id'] as String,
  likesCount: (json['likesCount'] as num).toInt(),
  commentsCount: (json['commentsCount'] as num).toInt(),
  isLiked: json['isLiked'] as bool,
);

Map<String, dynamic> _$$DocImplToJson(_$DocImpl instance) => <String, dynamic>{
  '_id': instance.id,
  'content': instance.content,
  '_comic': instance.comic,
  'totalComments': instance.totalComments,
  'hide': instance.hide,
  'created_at': instance.createdAt.toIso8601String(),
  'id': instance.docId,
  'likesCount': instance.likesCount,
  'commentsCount': instance.commentsCount,
  'isLiked': instance.isLiked,
};

_$ComicImpl _$$ComicImplFromJson(Map<String, dynamic> json) =>
    _$ComicImpl(id: json['_id'] as String, title: json['title'] as String);

Map<String, dynamic> _$$ComicImplToJson(_$ComicImpl instance) =>
    <String, dynamic>{'_id': instance.id, 'title': instance.title};
