// To parse this JSON data, do
//
//     final normalComicAllInfo = normalComicAllInfoFromJson(jsonString);

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
    @JsonKey(name: "comicInfo") required ComicInfo comicInfo,
    @JsonKey(name: "eps") required List<Ep> eps,
    @JsonKey(name: "recommend") required List<Recommend> recommend,
  }) = _NormalComicAllInfo;

  factory NormalComicAllInfo.fromJson(Map<String, dynamic> json) =>
      _$NormalComicAllInfoFromJson(json);
}

@freezed
abstract class ComicInfo with _$ComicInfo {
  const factory ComicInfo({
    @JsonKey(name: "id") required String id,
    @JsonKey(name: "creator") required Creator creator,
    @JsonKey(name: "title") required String title,
    @JsonKey(name: "description") required String description,
    @JsonKey(name: "cover") required Cover cover,
    @JsonKey(name: "categories") required List<String> categories,
    @JsonKey(name: "tags") required List<String> tags,
    @JsonKey(name: "author") required List<String> author,
    @JsonKey(name: "works") required List<String> works,
    @JsonKey(name: "actors") required List<String> actors,
    @JsonKey(name: "chineseTeam") required List<String> chineseTeam,
    @JsonKey(name: "pagesCount") required int pagesCount,
    @JsonKey(name: "epsCount") required int epsCount,
    @JsonKey(name: "updated_at") required DateTime updatedAt,
    @JsonKey(name: "allowComment") required bool allowComment,
    @JsonKey(name: "totalViews") required int totalViews,
    @JsonKey(name: "totalLikes") required int totalLikes,
    @JsonKey(name: "totalComments") required int totalComments,
    @JsonKey(name: "isFavourite") required bool isFavourite,
    @JsonKey(name: "isLiked") required bool isLiked,
  }) = _ComicInfo;

  factory ComicInfo.fromJson(Map<String, dynamic> json) =>
      _$ComicInfoFromJson(json);
}

@freezed
abstract class Cover with _$Cover {
  const factory Cover({
    @JsonKey(name: "url") required String url,
    @JsonKey(name: "path") required String path,
    @JsonKey(name: "name") required String name,
  }) = _Cover;

  factory Cover.fromJson(Map<String, dynamic> json) => _$CoverFromJson(json);
}

@freezed
abstract class Creator with _$Creator {
  const factory Creator({
    @JsonKey(name: "id") required String id,
    @JsonKey(name: "name") required String name,
    @JsonKey(name: "avatar") required Cover avatar,
  }) = _Creator;

  factory Creator.fromJson(Map<String, dynamic> json) =>
      _$CreatorFromJson(json);
}

@freezed
abstract class Ep with _$Ep {
  const factory Ep({
    @JsonKey(name: "id") required String id,
    @JsonKey(name: "name") required String name,
    @JsonKey(name: "order") required int order,
  }) = _Ep;

  factory Ep.fromJson(Map<String, dynamic> json) => _$EpFromJson(json);
}

@freezed
abstract class Recommend with _$Recommend {
  const factory Recommend({
    @JsonKey(name: "id") required String id,
    @JsonKey(name: "title") required String title,
    @JsonKey(name: "cover") required Cover cover,
  }) = _Recommend;

  factory Recommend.fromJson(Map<String, dynamic> json) =>
      _$RecommendFromJson(json);
}
