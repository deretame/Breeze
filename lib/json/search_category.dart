// To parse this JSON data, do
//
//     final searchCategory = searchCategoryFromJson(jsonString);

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_category.freezed.dart';
part 'search_category.g.dart';

SearchCategory searchCategoryFromJson(String str) =>
    SearchCategory.fromJson(json.decode(str));

String searchCategoryToJson(SearchCategory data) => json.encode(data.toJson());

@freezed
class SearchCategory with _$SearchCategory {
  const factory SearchCategory({
    @JsonKey(name: "categories") required List<Category> categories,
  }) = _SearchCategory;

  factory SearchCategory.fromJson(Map<String, dynamic> json) =>
      _$SearchCategoryFromJson(json);
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
