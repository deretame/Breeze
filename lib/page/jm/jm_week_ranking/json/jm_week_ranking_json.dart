// To parse this JSON data, do
//
//     final jmWeekRankingJson = jmWeekRankingJsonFromJson(jsonString);

import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:convert';

part 'jm_week_ranking_json.freezed.dart';
part 'jm_week_ranking_json.g.dart';

List<JmWeekRankingJson> jmWeekRankingJsonFromJson(String str) =>
    List<JmWeekRankingJson>.from(
      json.decode(str).map((x) => JmWeekRankingJson.fromJson(x)),
    );

String jmWeekRankingJsonToJson(List<JmWeekRankingJson> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

@freezed
abstract class JmWeekRankingJson with _$JmWeekRankingJson {
  const factory JmWeekRankingJson({
    @JsonKey(name: "id") required dynamic id,
    @JsonKey(name: "title") required String title,
    @JsonKey(name: "slug") required String slug,
    @JsonKey(name: "type") required String type,
    @JsonKey(name: "filter_val") required dynamic filterVal,
    @JsonKey(name: "content") required List<Content> content,
  }) = _JmWeekRankingJson;

  factory JmWeekRankingJson.fromJson(Map<String, dynamic> json) =>
      _$JmWeekRankingJsonFromJson(json);
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
