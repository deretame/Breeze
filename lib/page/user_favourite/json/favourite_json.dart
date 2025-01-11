// To parse this JSON data, do
//
//     final favouriteJson = favouriteJsonFromJson(jsonString);

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'favourite_json.freezed.dart';
part 'favourite_json.g.dart';

FavouriteJson favouriteJsonFromJson(String str) =>
    FavouriteJson.fromJson(json.decode(str));

String favouriteJsonToJson(FavouriteJson data) => json.encode(data.toJson());

@freezed
class FavouriteJson with _$FavouriteJson {
  const factory FavouriteJson({
    @JsonKey(name: "code") required int code,
    @JsonKey(name: "message") required String message,
    @JsonKey(name: "data") required Data data,
  }) = _FavouriteJson;

  factory FavouriteJson.fromJson(Map<String, dynamic> json) =>
      _$FavouriteJsonFromJson(json);
}

@freezed
class Data with _$Data {
  const factory Data({
    @JsonKey(name: "comics") required Comics comics,
  }) = _Data;

  factory Data.fromJson(Map<String, dynamic> json) => _$DataFromJson(json);
}

@freezed
class Comics with _$Comics {
  const factory Comics({
    @JsonKey(name: "pages") required int pages,
    @JsonKey(name: "total") required int total,
    @JsonKey(name: "docs") required List<Doc> docs,
    @JsonKey(name: "page") required int page,
    @JsonKey(name: "limit") required int limit,
  }) = _Comics;

  factory Comics.fromJson(Map<String, dynamic> json) => _$ComicsFromJson(json);
}

@freezed
class Doc with _$Doc {
  const factory Doc({
    @JsonKey(name: "_id") required String id,
    @JsonKey(name: "title") required String title,
    @JsonKey(name: "author") required String author,
    @JsonKey(name: "totalViews") required int totalViews,
    @JsonKey(name: "totalLikes") required int totalLikes,
    @JsonKey(name: "pagesCount") required int pagesCount,
    @JsonKey(name: "epsCount") required int epsCount,
    @JsonKey(name: "finished") required bool finished,
    @JsonKey(name: "categories") required List<String> categories,
    @JsonKey(name: "thumb") required Thumb thumb,
    @JsonKey(name: "likesCount") required int likesCount,
  }) = _Doc;

  factory Doc.fromJson(Map<String, dynamic> json) => _$DocFromJson(json);
}

@freezed
class Thumb with _$Thumb {
  const factory Thumb({
    @JsonKey(name: "fileServer") required String fileServer,
    @JsonKey(name: "path") required String path,
    @JsonKey(name: "originalName") required String originalName,
  }) = _Thumb;

  factory Thumb.fromJson(Map<String, dynamic> json) => _$ThumbFromJson(json);
}
