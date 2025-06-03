// To parse this JSON data, do
//
//     final jmSuggestionJson = jmSuggestionJsonFromJson(jsonString);

import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:convert';

part 'jm_suggestion_json.freezed.dart';
part 'jm_suggestion_json.g.dart';

List<JmSuggestionJson> jmSuggestionJsonFromJson(String str) =>
    List<JmSuggestionJson>.from(
      json.decode(str).map((x) => JmSuggestionJson.fromJson(x)),
    );

String jmSuggestionJsonToJson(List<JmSuggestionJson> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

@freezed
abstract class JmSuggestionJson with _$JmSuggestionJson {
  const factory JmSuggestionJson({
    @JsonKey(name: "id") required String id,
    @JsonKey(name: "author") required String author,
    @JsonKey(name: "name") required dynamic name,
    @JsonKey(name: "image") required String image,
    @JsonKey(name: "category") required Category category,
    @JsonKey(name: "category_sub") required CategorySub categorySub,
    @JsonKey(name: "liked") required bool liked,
    @JsonKey(name: "is_favorite") required bool isFavorite,
    @JsonKey(name: "update_at") required int updateAt,
  }) = _JmSuggestionJson;

  factory JmSuggestionJson.fromJson(Map<String, dynamic> json) =>
      _$JmSuggestionJsonFromJson(json);
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
