// To parse this JSON data, do
//
//     final jmComicInfoJson = jmComicInfoJsonFromJson(jsonString);

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'jm_comic_info_json.freezed.dart';
part 'jm_comic_info_json.g.dart';

JmComicInfoJson jmComicInfoJsonFromJson(String str) =>
    JmComicInfoJson.fromJson(json.decode(str));

String jmComicInfoJsonToJson(JmComicInfoJson data) =>
    json.encode(data.toJson());

@freezed
abstract class JmComicInfoJson with _$JmComicInfoJson {
  const factory JmComicInfoJson({
    @JsonKey(name: "id") required int id,
    @JsonKey(name: "name") required String name,
    @JsonKey(name: "images") required List<dynamic> images,
    @JsonKey(name: "addtime") required String addtime,
    @JsonKey(name: "description") required String description,
    @JsonKey(name: "total_views") required String totalViews,
    @JsonKey(name: "likes") required String likes,
    @JsonKey(name: "series") required List<Series> series,
    @JsonKey(name: "series_id") required String seriesId,
    @JsonKey(name: "comment_total") required String commentTotal,
    @JsonKey(name: "author") required List<String> author,
    @JsonKey(name: "tags") required List<String> tags,
    @JsonKey(name: "works") required List<String> works,
    @JsonKey(name: "actors") required List<String> actors,
    @JsonKey(name: "related_list") required List<RelatedList> relatedList,
    @JsonKey(name: "liked") required bool liked,
    @JsonKey(name: "is_favorite") required bool isFavorite,
    @JsonKey(name: "is_aids") required bool isAids,
    @JsonKey(name: "price") required String price,
    @JsonKey(name: "purchased") required String purchased,
  }) = _JmComicInfoJson;

  factory JmComicInfoJson.fromJson(Map<String, dynamic> json) =>
      _$JmComicInfoJsonFromJson(json);
}

@freezed
abstract class RelatedList with _$RelatedList {
  const factory RelatedList({
    @JsonKey(name: "id") required String id,
    @JsonKey(name: "author") required String author,
    @JsonKey(name: "name") required String name,
    @JsonKey(name: "image") required String image,
  }) = _RelatedList;

  factory RelatedList.fromJson(Map<String, dynamic> json) =>
      _$RelatedListFromJson(json);
}

@freezed
abstract class Series with _$Series {
  const factory Series({
    @JsonKey(name: "id") required String id,
    @JsonKey(name: "name") required String name,
    @JsonKey(name: "sort") required String sort,
  }) = _Series;

  factory Series.fromJson(Map<String, dynamic> json) => _$SeriesFromJson(json);
}
