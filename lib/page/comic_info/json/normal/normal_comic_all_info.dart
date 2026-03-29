import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'normal_comic_all_info.freezed.dart';
part 'normal_comic_all_info.g.dart';

NormalComicAllInfo normalComicAllInfoFromJson(String str) =>
    NormalComicAllInfo.fromJson(json.decode(str));

String normalComicAllInfoToJson(NormalComicAllInfo data) =>
    json.encode(data.toJson());

@freezed
abstract class NormalComicAllInfo with _$NormalComicAllInfo {
  const factory NormalComicAllInfo({
    @JsonKey(name: 'comicInfo') required ComicInfo comicInfo,
    @JsonKey(name: 'eps') required List<Ep> eps,
    @JsonKey(name: 'recommend') required List<Recommend> recommend,
    @JsonKey(name: 'totalViews') @Default(0) int totalViews,
    @JsonKey(name: 'totalLikes') @Default(0) int totalLikes,
    @JsonKey(name: 'totalComments') @Default(0) int totalComments,
    @JsonKey(name: 'isFavourite') @Default(false) bool isFavourite,
    @JsonKey(name: 'isLiked') @Default(false) bool isLiked,
    @JsonKey(name: 'allowComment') @Default(true) bool allowComment,
    @JsonKey(name: 'allowLike') @Default(true) bool allowLike,
    @JsonKey(name: 'allowFavorite') @Default(true) bool allowFavorite,
    @JsonKey(name: 'allowDownload') @Default(true) bool allowDownload,
    @JsonKey(name: 'extension') @Default({}) Map<String, dynamic> extension,
  }) = _NormalComicAllInfo;

  factory NormalComicAllInfo.fromJson(Map<String, dynamic> json) =>
      _$NormalComicAllInfoFromJson(json);
}

@freezed
abstract class ComicInfoActionItem with _$ComicInfoActionItem {
  const factory ComicInfoActionItem({
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'onTap') @Default({}) Map<String, dynamic> onTap,
    @JsonKey(name: 'extension') @Default({}) Map<String, dynamic> extension,
  }) = _ComicInfoActionItem;

  factory ComicInfoActionItem.fromJson(Map<String, dynamic> json) =>
      _$ComicInfoActionItemFromJson(json);
}

@freezed
abstract class ComicInfoMetadata with _$ComicInfoMetadata {
  const factory ComicInfoMetadata({
    @JsonKey(name: 'type') required String type,
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'value') required List<ComicInfoActionItem> value,
  }) = _ComicInfoMetadata;

  factory ComicInfoMetadata.fromJson(Map<String, dynamic> json) =>
      _$ComicInfoMetadataFromJson(json);
}

@freezed
abstract class ComicImage with _$ComicImage {
  const factory ComicImage({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'url') required String url,
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'extension') @Default({}) Map<String, dynamic> extension,
  }) = _ComicImage;

  factory ComicImage.fromJson(Map<String, dynamic> json) =>
      _$ComicImageFromJson(json);
}

@freezed
abstract class Creator with _$Creator {
  const factory Creator({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'avatar') required ComicImage avatar,
    @JsonKey(name: 'onTap') @Default({}) Map<String, dynamic> onTap,
    @JsonKey(name: 'extension') @Default({}) Map<String, dynamic> extension,
  }) = _Creator;

  factory Creator.fromJson(Map<String, dynamic> json) =>
      _$CreatorFromJson(json);
}

@freezed
abstract class ComicInfo with _$ComicInfo {
  const factory ComicInfo({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'title') required String title,
    @JsonKey(name: 'titleMeta') required List<ComicInfoActionItem> titleMeta,
    @JsonKey(name: 'creator') required Creator creator,
    @JsonKey(name: 'description') required String description,
    @JsonKey(name: 'cover') required ComicImage cover,
    @JsonKey(name: 'metadata') required List<ComicInfoMetadata> metadata,
    @JsonKey(name: 'extension') @Default({}) Map<String, dynamic> extension,
  }) = _ComicInfo;

  factory ComicInfo.fromJson(Map<String, dynamic> json) =>
      _$ComicInfoFromJson(json);
}

@freezed
abstract class Ep with _$Ep {
  const factory Ep({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'order') required int order,
    @JsonKey(name: 'extension') @Default({}) Map<String, dynamic> extension,
  }) = _Ep;

  factory Ep.fromJson(Map<String, dynamic> json) => _$EpFromJson(json);
}

@freezed
abstract class Recommend with _$Recommend {
  const factory Recommend({
    @JsonKey(name: 'source') required String source,
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'title') required String title,
    @JsonKey(name: 'cover') required ComicImage cover,
    @JsonKey(name: 'extension') @Default({}) Map<String, dynamic> extension,
  }) = _Recommend;

  factory Recommend.fromJson(Map<String, dynamic> json) =>
      _$RecommendFromJson(json);
}
