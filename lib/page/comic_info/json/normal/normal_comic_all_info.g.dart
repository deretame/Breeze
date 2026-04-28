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
      totalViews: (json['totalViews'] as num?)?.toInt() ?? 0,
      totalLikes: (json['totalLikes'] as num?)?.toInt() ?? 0,
      totalComments: (json['totalComments'] as num?)?.toInt() ?? 0,
      isFavourite: json['isFavourite'] as bool? ?? false,
      isLiked: json['isLiked'] as bool? ?? false,
      allowComments: json['allowComments'] as bool? ?? false,
      allowLike: json['allowLike'] as bool? ?? false,
      allowCollected: json['allowCollected'] as bool? ?? false,
      allowDownload: json['allowDownload'] as bool? ?? true,
      extern: json['extern'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$NormalComicAllInfoToJson(_NormalComicAllInfo instance) =>
    <String, dynamic>{
      'comicInfo': instance.comicInfo,
      'eps': instance.eps,
      'recommend': instance.recommend,
      'totalViews': instance.totalViews,
      'totalLikes': instance.totalLikes,
      'totalComments': instance.totalComments,
      'isFavourite': instance.isFavourite,
      'isLiked': instance.isLiked,
      'allowComments': instance.allowComments,
      'allowLike': instance.allowLike,
      'allowCollected': instance.allowCollected,
      'allowDownload': instance.allowDownload,
      'extern': instance.extern,
    };

_ComicInfoActionItem _$ComicInfoActionItemFromJson(Map<String, dynamic> json) =>
    _ComicInfoActionItem(
      name: json['name'] as String,
      onTap: json['onTap'] as Map<String, dynamic>? ?? const {},
      extern: json['extern'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$ComicInfoActionItemToJson(
  _ComicInfoActionItem instance,
) => <String, dynamic>{
  'name': instance.name,
  'onTap': instance.onTap,
  'extern': instance.extern,
};

_ComicInfoMetadata _$ComicInfoMetadataFromJson(Map<String, dynamic> json) =>
    _ComicInfoMetadata(
      type: json['type'] as String,
      name: json['name'] as String,
      value: (json['value'] as List<dynamic>)
          .map((e) => ComicInfoActionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ComicInfoMetadataToJson(_ComicInfoMetadata instance) =>
    <String, dynamic>{
      'type': instance.type,
      'name': instance.name,
      'value': instance.value,
    };

_ComicImage _$ComicImageFromJson(Map<String, dynamic> json) => _ComicImage(
  id: json['id'] as String,
  url: json['url'] as String,
  name: json['name'] as String,
  path: json['path'] as String? ?? '',
  extern: json['extern'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$ComicImageToJson(_ComicImage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'name': instance.name,
      'path': instance.path,
      'extern': instance.extern,
    };

_Creator _$CreatorFromJson(Map<String, dynamic> json) => _Creator(
  id: json['id'] as String,
  name: json['name'] as String,
  avatar: ComicImage.fromJson(json['avatar'] as Map<String, dynamic>),
  onTap: json['onTap'] as Map<String, dynamic>? ?? const {},
  extern: json['extern'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$CreatorToJson(_Creator instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'avatar': instance.avatar,
  'onTap': instance.onTap,
  'extern': instance.extern,
};

_ComicInfo _$ComicInfoFromJson(Map<String, dynamic> json) => _ComicInfo(
  id: json['id'] as String,
  title: json['title'] as String,
  titleMeta: (json['titleMeta'] as List<dynamic>)
      .map((e) => ComicInfoActionItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  creator: Creator.fromJson(json['creator'] as Map<String, dynamic>),
  description: json['description'] as String,
  cover: ComicImage.fromJson(json['cover'] as Map<String, dynamic>),
  metadata: (json['metadata'] as List<dynamic>)
      .map((e) => ComicInfoMetadata.fromJson(e as Map<String, dynamic>))
      .toList(),
  extern: json['extern'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$ComicInfoToJson(_ComicInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'titleMeta': instance.titleMeta,
      'creator': instance.creator,
      'description': instance.description,
      'cover': instance.cover,
      'metadata': instance.metadata,
      'extern': instance.extern,
    };

_Ep _$EpFromJson(Map<String, dynamic> json) => _Ep(
  id: json['id'] as String,
  name: json['name'] as String,
  order: (json['order'] as num).toInt(),
  extern: json['extern'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$EpToJson(_Ep instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'order': instance.order,
  'extern': instance.extern,
};

_Recommend _$RecommendFromJson(Map<String, dynamic> json) => _Recommend(
  source: json['source'] as String,
  id: json['id'] as String,
  title: json['title'] as String,
  cover: ComicImage.fromJson(json['cover'] as Map<String, dynamic>),
  extern: json['extern'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$RecommendToJson(_Recommend instance) =>
    <String, dynamic>{
      'source': instance.source,
      'id': instance.id,
      'title': instance.title,
      'cover': instance.cover,
      'extern': instance.extern,
    };
