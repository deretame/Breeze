// To parse this JSON data, do
//
//     final comicAllInfoJson = comicAllInfoJsonFromJson(jsonString);

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'comic_all_info_json.freezed.dart';
part 'comic_all_info_json.g.dart';

ComicAllInfoJson comicAllInfoJsonFromJson(String str) =>
    ComicAllInfoJson.fromJson(json.decode(str));

String comicAllInfoJsonToJson(ComicAllInfoJson data) =>
    json.encode(data.toJson());

@freezed
abstract class ComicAllInfoJson with _$ComicAllInfoJson {
  const factory ComicAllInfoJson({
    @JsonKey(name: "comic") required Comic comic,
    @JsonKey(name: "eps") required Eps eps,
  }) = _ComicAllInfoJson;

  factory ComicAllInfoJson.fromJson(Map<String, dynamic> json) =>
      _$ComicAllInfoJsonFromJson(json);
}

@freezed
abstract class Comic with _$Comic {
  const factory Comic({
    @JsonKey(name: "_id") required String id,
    @JsonKey(name: "_creator") required Creator creator,
    @JsonKey(name: "title") required String title,
    @JsonKey(name: "description") required String description,
    @JsonKey(name: "thumb") required Thumb thumb,
    @JsonKey(name: "author") required String author,
    @JsonKey(name: "chineseTeam") required String chineseTeam,
    @JsonKey(name: "categories") required List<String> categories,
    @JsonKey(name: "tags") required List<String> tags,
    @JsonKey(name: "pagesCount") required int pagesCount,
    @JsonKey(name: "epsCount") required int epsCount,
    @JsonKey(name: "finished") required bool finished,
    @JsonKey(name: "updated_at") required DateTime updatedAt,
    @JsonKey(name: "created_at") required DateTime createdAt,
    @JsonKey(name: "allowDownload") required bool allowDownload,
    @JsonKey(name: "allowComment") required bool allowComment,
    @JsonKey(name: "totalLikes") required int totalLikes,
    @JsonKey(name: "totalViews") required int totalViews,
    @JsonKey(name: "totalComments") required int totalComments,
    @JsonKey(name: "viewsCount") required int viewsCount,
    @JsonKey(name: "likesCount") required int likesCount,
    @JsonKey(name: "commentsCount") required int commentsCount,
    @JsonKey(name: "isFavourite") required bool isFavourite,
    @JsonKey(name: "isLiked") required bool isLiked,
  }) = _Comic;

  factory Comic.fromJson(Map<String, dynamic> json) => _$ComicFromJson(json);
}

@freezed
abstract class Creator with _$Creator {
  const factory Creator({
    @JsonKey(name: "_id") required String id,
    @JsonKey(name: "gender") required String gender,
    @JsonKey(name: "name") required String name,
    @JsonKey(name: "verified") required bool verified,
    @JsonKey(name: "exp") required int exp,
    @JsonKey(name: "level") required int level,
    @JsonKey(name: "characters") required List<String> characters,
    @JsonKey(name: "role") required String role,
    @JsonKey(name: "avatar") required Thumb avatar,
    @JsonKey(name: "title") required String title,
    @JsonKey(name: "slogan") required String slogan,
  }) = _Creator;

  factory Creator.fromJson(Map<String, dynamic> json) =>
      _$CreatorFromJson(json);
}

@freezed
abstract class Thumb with _$Thumb {
  const factory Thumb({
    @JsonKey(name: "originalName") required String originalName,
    @JsonKey(name: "path") required String path,
    @JsonKey(name: "fileServer") required String fileServer,
  }) = _Thumb;

  factory Thumb.fromJson(Map<String, dynamic> json) => _$ThumbFromJson(json);
}

@freezed
abstract class Eps with _$Eps {
  const factory Eps({@JsonKey(name: "docs") required List<EpsDoc> docs}) = _Eps;

  factory Eps.fromJson(Map<String, dynamic> json) => _$EpsFromJson(json);
}

@freezed
abstract class EpsDoc with _$EpsDoc {
  const factory EpsDoc({
    @JsonKey(name: "_id") required String id,
    @JsonKey(name: "title") required String title,
    @JsonKey(name: "order") required int order,
    @JsonKey(name: "updated_at") required DateTime updatedAt,
    @JsonKey(name: "id") required String docId,
    @JsonKey(name: "pages") required Pages pages,
  }) = _EpsDoc;

  factory EpsDoc.fromJson(Map<String, dynamic> json) => _$EpsDocFromJson(json);
}

@freezed
abstract class Pages with _$Pages {
  const factory Pages({@JsonKey(name: "docs") required List<PagesDoc> docs}) =
      _Pages;

  factory Pages.fromJson(Map<String, dynamic> json) => _$PagesFromJson(json);
}

@freezed
abstract class PagesDoc with _$PagesDoc {
  const factory PagesDoc({
    @JsonKey(name: "_id") required String id,
    @JsonKey(name: "media") required Thumb media,
    @JsonKey(name: "id") required String docId,
  }) = _PagesDoc;

  factory PagesDoc.fromJson(Map<String, dynamic> json) =>
      _$PagesDocFromJson(json);
}
