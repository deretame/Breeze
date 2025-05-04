// To parse this JSON data, do
//
//     final jmEpInfoJson = jmEpInfoJsonFromJson(jsonString);

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'jm_ep_info_json.freezed.dart';
part 'jm_ep_info_json.g.dart';

JmEpInfoJson jmEpInfoJsonFromJson(String str) =>
    JmEpInfoJson.fromJson(json.decode(str));

String jmEpInfoJsonToJson(JmEpInfoJson data) => json.encode(data.toJson());

@freezed
abstract class JmEpInfoJson with _$JmEpInfoJson {
  const factory JmEpInfoJson({
    @JsonKey(name: "id") required int id,
    @JsonKey(name: "series") required List<Series> series,
    @JsonKey(name: "tags") required String tags,
    @JsonKey(name: "name") required String name,
    @JsonKey(name: "images") required List<String> images,
    @JsonKey(name: "addtime") required String addtime,
    @JsonKey(name: "series_id") required String seriesId,
    @JsonKey(name: "is_favorite") required bool isFavorite,
    @JsonKey(name: "liked") required bool liked,
  }) = _JmEpInfoJson;

  factory JmEpInfoJson.fromJson(Map<String, dynamic> json) =>
      _$JmEpInfoJsonFromJson(json);
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
