// To parse this JSON data, do
//
//     final jmRankingJson = jmRankingJsonFromJson(jsonString);

import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:convert';

part 'jm_ranking_json.freezed.dart';
part 'jm_ranking_json.g.dart';

JmRankingJson jmRankingJsonFromJson(String str) =>
    JmRankingJson.fromJson(json.decode(str));

String jmRankingJsonToJson(JmRankingJson data) => json.encode(data.toJson());

@freezed
abstract class JmRankingJson with _$JmRankingJson {
  const factory JmRankingJson({
    @JsonKey(name: "search_query") required String searchQuery,
    @JsonKey(name: "total") required String total,
    @JsonKey(name: "content") required List<Content> content,
    @JsonKey(name: "tags") required List<String> tags,
  }) = _JmRankingJson;

  factory JmRankingJson.fromJson(Map<String, dynamic> json) =>
      _$JmRankingJsonFromJson(json);
}

@freezed
abstract class Content with _$Content {
  const factory Content({
    @JsonKey(name: "id") required String id,
    @JsonKey(name: "author") required String author,
    @JsonKey(name: "name") required String name,
    @JsonKey(name: "image") required String image,
    @JsonKey(name: "category") required Category category,
    @JsonKey(name: "category_sub") required CategorySub categorySub,
    @JsonKey(name: "liked") required bool liked,
    @JsonKey(name: "is_favorite") required bool isFavorite,
    @JsonKey(name: "update_at") required int updateAt,
  }) = _Content;

  factory Content.fromJson(Map<String, dynamic> json) =>
      _$ContentFromJson(json);
}

@freezed
abstract class Category with _$Category {
  const factory Category({
    @JsonKey(name: "id") required String id,
    @JsonKey(name: "title") required String title,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
}

@freezed
abstract class CategorySub with _$CategorySub {
  const factory CategorySub({
    @JsonKey(name: "id") required String? id,
    @JsonKey(name: "title") required String? title,
  }) = _CategorySub;

  factory CategorySub.fromJson(Map<String, dynamic> json) =>
      _$CategorySubFromJson(json);
}
