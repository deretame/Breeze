// To parse this JSON data, do
//
//     final searchPage = searchPageFromJson(jsonString);

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_page.freezed.dart';
part 'search_page.g.dart';

SearchPage searchPageFromJson(String str) =>
    SearchPage.fromJson(json.decode(str));

String searchPageToJson(SearchPage data) => json.encode(data.toJson());

@freezed
class SearchPage with _$SearchPage {
  const factory SearchPage({
    @JsonKey(name: "code") required int code,
    @JsonKey(name: "message") required String message,
    @JsonKey(name: "data") required Data data,
  }) = _SearchPage;

  factory SearchPage.fromJson(Map<String, dynamic> json) =>
      _$SearchPageFromJson(json);
}

@freezed
class Data with _$Data {
  const factory Data({
    @JsonKey(name: "categories") required List<Category> categories,
  }) = _Data;

  factory Data.fromJson(Map<String, dynamic> json) => _$DataFromJson(json);
}

@freezed
class Category with _$Category {
  const factory Category({
    @JsonKey(name: "title") required String title,
    @JsonKey(name: "thumb") required Thumb thumb,
    @JsonKey(name: "isWeb") bool? isWeb,
    @JsonKey(name: "active") bool? active,
    @JsonKey(name: "link") String? link,
    @JsonKey(name: "_id") String? id,
    @JsonKey(name: "description") String? description,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
}

@freezed
class Thumb with _$Thumb {
  const factory Thumb({
    @JsonKey(name: "originalName") required String originalName,
    @JsonKey(name: "path") required String path,
    @JsonKey(name: "fileServer") required String fileServer,
  }) = _Thumb;

  factory Thumb.fromJson(Map<String, dynamic> json) => _$ThumbFromJson(json);
}
