// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'normal_comic_all_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NormalComicAllInfo _$NormalComicAllInfoFromJson(Map<String, dynamic> json) =>
    _NormalComicAllInfo(
      comicInfo: ComicInfo.fromJson(json['comicInfo'] as Map<String, dynamic>),
      eps: (json['eps'] as List<dynamic>)
          .map((e) => Ep.fromJson(e as Map<String, dynamic>))
          .toList(),
      recommend: (json['recommend'] as List<dynamic>)
          .map((e) => Recommend.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$NormalComicAllInfoToJson(_NormalComicAllInfo instance) =>
    <String, dynamic>{
      'comicInfo': instance.comicInfo,
      'eps': instance.eps,
      'recommend': instance.recommend,
    };

_ComicInfo _$ComicInfoFromJson(Map<String, dynamic> json) => _ComicInfo(
  id: json['id'] as String,
  creator: Creator.fromJson(json['creator'] as Map<String, dynamic>),
  title: json['title'] as String,
  description: json['description'] as String,
  cover: Cover.fromJson(json['cover'] as Map<String, dynamic>),
  categories: (json['categories'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
  author: (json['author'] as List<dynamic>).map((e) => e as String).toList(),
  works: (json['works'] as List<dynamic>).map((e) => e as String).toList(),
  actors: (json['actors'] as List<dynamic>).map((e) => e as String).toList(),
  chineseTeam: (json['chineseTeam'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  pagesCount: (json['pagesCount'] as num).toInt(),
  epsCount: (json['epsCount'] as num).toInt(),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  allowComment: json['allowComment'] as bool,
  totalViews: (json['totalViews'] as num).toInt(),
  totalLikes: (json['totalLikes'] as num).toInt(),
  totalComments: (json['totalComments'] as num).toInt(),
  isFavourite: json['isFavourite'] as bool,
  isLiked: json['isLiked'] as bool,
);

Map<String, dynamic> _$ComicInfoToJson(_ComicInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'creator': instance.creator,
      'title': instance.title,
      'description': instance.description,
      'cover': instance.cover,
      'categories': instance.categories,
      'tags': instance.tags,
      'author': instance.author,
      'works': instance.works,
      'actors': instance.actors,
      'chineseTeam': instance.chineseTeam,
      'pagesCount': instance.pagesCount,
      'epsCount': instance.epsCount,
      'updated_at': instance.updatedAt.toIso8601String(),
      'allowComment': instance.allowComment,
      'totalViews': instance.totalViews,
      'totalLikes': instance.totalLikes,
      'totalComments': instance.totalComments,
      'isFavourite': instance.isFavourite,
      'isLiked': instance.isLiked,
    };

_Cover _$CoverFromJson(Map<String, dynamic> json) => _Cover(
  url: json['url'] as String,
  path: json['path'] as String,
  name: json['name'] as String,
);

Map<String, dynamic> _$CoverToJson(_Cover instance) => <String, dynamic>{
  'url': instance.url,
  'path': instance.path,
  'name': instance.name,
};

_Creator _$CreatorFromJson(Map<String, dynamic> json) => _Creator(
  id: json['id'] as String,
  name: json['name'] as String,
  avatar: Cover.fromJson(json['avatar'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CreatorToJson(_Creator instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'avatar': instance.avatar,
};

_Ep _$EpFromJson(Map<String, dynamic> json) => _Ep(
  id: json['id'] as String,
  name: json['name'] as String,
  order: (json['order'] as num).toInt(),
);

Map<String, dynamic> _$EpToJson(_Ep instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'order': instance.order,
};

_Recommend _$RecommendFromJson(Map<String, dynamic> json) => _Recommend(
  id: json['id'] as String,
  title: json['title'] as String,
  cover: Cover.fromJson(json['cover'] as Map<String, dynamic>),
);

Map<String, dynamic> _$RecommendToJson(_Recommend instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'cover': instance.cover,
    };
