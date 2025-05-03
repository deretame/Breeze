// To parse this JSON data, do
//
//     final comicInfo = comicInfoFromJson(jsonString);

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'comic_info.freezed.dart';
part 'comic_info.g.dart';

ComicInfo comicInfoFromJson(String str) => ComicInfo.fromJson(json.decode(str));

String comicInfoToJson(ComicInfo data) => json.encode(data.toJson());

@freezed
abstract class ComicInfo with _$ComicInfo {
  const factory ComicInfo({
    @JsonKey(name: "code") required int code,
    @JsonKey(name: "message") required String message,
    @JsonKey(name: "data") required Data data,
  }) = _ComicInfo;

  factory ComicInfo.fromJson(Map<String, dynamic> json) =>
      _$ComicInfoFromJson(json);
}

@freezed
abstract class Data with _$Data {
  const factory Data({@JsonKey(name: "comic") required Comic comic}) = _Data;

  factory Data.fromJson(Map<String, dynamic> json) => _$DataFromJson(json);
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
    @JsonKey(name: "title") required String title,
    @JsonKey(name: "avatar") required Thumb avatar,
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
