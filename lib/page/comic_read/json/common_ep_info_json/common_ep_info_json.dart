// To parse this JSON data, do
//
//     final commonEpInfoJson = commonEpInfoJsonFromJson(jsonString);

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'common_ep_info_json.freezed.dart';
part 'common_ep_info_json.g.dart';

CommonEpInfoJson commonEpInfoJsonFromJson(String str) =>
    CommonEpInfoJson.fromJson(json.decode(str));

String commonEpInfoJsonToJson(CommonEpInfoJson data) =>
    json.encode(data.toJson());

@freezed
abstract class CommonEpInfoJson with _$CommonEpInfoJson {
  const factory CommonEpInfoJson({
    @JsonKey(name: "epId") required String epId,
    @JsonKey(name: "epName") required String epName,
    @JsonKey(name: "series") required List<Series> series,
    @JsonKey(name: "docs") required List<Doc> docs,
  }) = _CommonEpInfoJson;

  factory CommonEpInfoJson.fromJson(Map<String, dynamic> json) =>
      _$CommonEpInfoJsonFromJson(json);
}

@freezed
abstract class Doc with _$Doc {
  const factory Doc({
    @JsonKey(name: "originalName") required String originalName,
    @JsonKey(name: "path") required String path,
    @JsonKey(name: "fileServer") required String fileServer,
    @JsonKey(name: "id") required String id,
  }) = _Doc;

  factory Doc.fromJson(Map<String, dynamic> json) => _$DocFromJson(json);
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
