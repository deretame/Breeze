// To parse this JSON data, do
//
//     final jmWeekRankingJson = jmWeekRankingJsonFromJson(jsonString);

import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:convert';

part 'jm_week_ranking_json.freezed.dart';
part 'jm_week_ranking_json.g.dart';

JmWeekRankingJson jmWeekRankingJsonFromJson(String str) =>
    JmWeekRankingJson.fromJson(json.decode(str));

String jmWeekRankingJsonToJson(JmWeekRankingJson data) =>
    json.encode(data.toJson());

@freezed
abstract class JmWeekRankingJson with _$JmWeekRankingJson {
  const factory JmWeekRankingJson({
    @JsonKey(name: "list") required List<ListElement> list,
  }) = _JmWeekRankingJson;

  factory JmWeekRankingJson.fromJson(Map<String, dynamic> json) =>
      _$JmWeekRankingJsonFromJson(json);
}

@freezed
abstract class ListElement with _$ListElement {
  const factory ListElement({
    @JsonKey(name: "id") required String id,
    @JsonKey(name: "author") required String author,
    @JsonKey(name: "description") required dynamic description,
    @JsonKey(name: "name") required String name,
    @JsonKey(name: "image") required String image,
    @JsonKey(name: "category") required Category category,
    @JsonKey(name: "category_sub") required CategorySub categorySub,
    @JsonKey(name: "liked") required bool liked,
    @JsonKey(name: "favorite") required bool favorite,
    @JsonKey(name: "update_at") required String updateAt,
  }) = _ListElement;

  factory ListElement.fromJson(Map<String, dynamic> json) =>
      _$ListElementFromJson(json);
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
    @JsonKey(name: "id") required String id,
    @JsonKey(name: "title") required String? title,
  }) = _CategorySub;

  factory CategorySub.fromJson(Map<String, dynamic> json) =>
      _$CategorySubFromJson(json);
}
