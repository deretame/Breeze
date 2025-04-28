// To parse this JSON data, do
//
//     final jmSearchResultJson = jmSearchResultJsonFromJson(jsonString);

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'jm_search_result_json.freezed.dart';
part 'jm_search_result_json.g.dart';

JmSearchResultJson jmSearchResultJsonFromJson(String str) =>
    JmSearchResultJson.fromJson(json.decode(str));

String jmSearchResultJsonToJson(JmSearchResultJson data) =>
    json.encode(data.toJson());

@freezed
abstract class JmSearchResultJson with _$JmSearchResultJson {
  const factory JmSearchResultJson({
    @JsonKey(name: "search_query") String? searchQuery,
    @JsonKey(name: "total") String? total,
    @JsonKey(name: "content") List<Content>? content,
  }) = _JmSearchResultJson;

  factory JmSearchResultJson.fromJson(Map<String, dynamic> json) =>
      _$JmSearchResultJsonFromJson(json);
}

@freezed
abstract class Content with _$Content {
  const factory Content({
    @JsonKey(name: "id") String? id,
    @JsonKey(name: "author") String? author,
    @JsonKey(name: "description") dynamic description,
    @JsonKey(name: "name") String? name,
    @JsonKey(name: "image") String? image,
    @JsonKey(name: "category") Category? category,
    @JsonKey(name: "category_sub") CategorySub? categorySub,
    @JsonKey(name: "liked") bool? liked,
    @JsonKey(name: "is_favorite") bool? isFavorite,
    @JsonKey(name: "update_at") int? updateAt,
  }) = _Content;

  factory Content.fromJson(Map<String, dynamic> json) =>
      _$ContentFromJson(json);
}

@freezed
abstract class Category with _$Category {
  const factory Category({
    @JsonKey(name: "id") String? id,
    @JsonKey(name: "title") String? title,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
}

@freezed
abstract class CategorySub with _$CategorySub {
  const factory CategorySub({
    @JsonKey(name: "id") String? id,
    @JsonKey(name: "title") String? title,
  }) = _CategorySub;

  factory CategorySub.fromJson(Map<String, dynamic> json) =>
      _$CategorySubFromJson(json);
}
