// To parse this JSON data, do
//
//     final downloadInfoJson = downloadInfoJsonFromJson(jsonString);

import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:convert';

part 'download_info_json.freezed.dart';
part 'download_info_json.g.dart';

DownloadInfoJson downloadInfoJsonFromJson(String str) =>
    DownloadInfoJson.fromJson(json.decode(str));

String downloadInfoJsonToJson(DownloadInfoJson data) =>
    json.encode(data.toJson());

@freezed
abstract class DownloadInfoJson with _$DownloadInfoJson {
  const factory DownloadInfoJson({
    @JsonKey(name: "id") required int id,
    @JsonKey(name: "name") required String name,
    @JsonKey(name: "images") required List<dynamic> images,
    @JsonKey(name: "addtime") required String addtime,
    @JsonKey(name: "description") required String description,
    @JsonKey(name: "total_views") required String totalViews,
    @JsonKey(name: "likes") required String likes,
    @JsonKey(name: "series") required List<DownloadInfoJsonSeries> series,
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
  }) = _DownloadInfoJson;

  factory DownloadInfoJson.fromJson(Map<String, dynamic> json) =>
      _$DownloadInfoJsonFromJson(json);
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
abstract class DownloadInfoJsonSeries with _$DownloadInfoJsonSeries {
  const factory DownloadInfoJsonSeries({
    @JsonKey(name: "id") required String id,
    @JsonKey(name: "name") required String name,
    @JsonKey(name: "sort") required String sort,
    @JsonKey(name: "info") required Info info,
  }) = _DownloadInfoJsonSeries;

  factory DownloadInfoJsonSeries.fromJson(Map<String, dynamic> json) =>
      _$DownloadInfoJsonSeriesFromJson(json);
}

@freezed
abstract class Info with _$Info {
  const factory Info({
    @JsonKey(name: "id") required int id,
    @JsonKey(name: "series") required List<InfoSeries> series,
    @JsonKey(name: "tags") required String tags,
    @JsonKey(name: "name") required String name,
    @JsonKey(name: "images") required List<String> images,
    @JsonKey(name: "addtime") required String addtime,
    @JsonKey(name: "series_id") required String seriesId,
    @JsonKey(name: "is_favorite") required bool isFavorite,
    @JsonKey(name: "liked") required bool liked,
  }) = _Info;

  factory Info.fromJson(Map<String, dynamic> json) => _$InfoFromJson(json);
}

@freezed
abstract class InfoSeries with _$InfoSeries {
  const factory InfoSeries({
    @JsonKey(name: "id") required String id,
    @JsonKey(name: "name") required String name,
    @JsonKey(name: "sort") required String sort,
  }) = _InfoSeries;

  factory InfoSeries.fromJson(Map<String, dynamic> json) =>
      _$InfoSeriesFromJson(json);
}
