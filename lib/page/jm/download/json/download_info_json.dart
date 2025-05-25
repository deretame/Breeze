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
    required int id,
    required String name,
    required List<dynamic> images,
    required String addtime,
    required String description,
    required String totalViews,
    required String likes,
    required List<DownloadInfoJsonSeries> series,
    required String seriesId,
    required String commentTotal,
    required List<String> author,
    required List<String> tags,
    required List<String> works,
    required List<String> actors,
    required bool liked,
    required bool isFavorite,
    required bool isAids,
    required String price,
    required String purchased,
  }) = _DownloadInfoJson;

  factory DownloadInfoJson.fromJson(Map<String, dynamic> json) =>
      _$DownloadInfoJsonFromJson(json);
}

@freezed
abstract class DownloadInfoJsonSeries with _$DownloadInfoJsonSeries {
  const factory DownloadInfoJsonSeries({
    required String id,
    required String name,
    required String sort,
    required Info info,
  }) = _DownloadInfoJsonSeries;

  factory DownloadInfoJsonSeries.fromJson(Map<String, dynamic> json) =>
      _$DownloadInfoJsonSeriesFromJson(json);
}

@freezed
abstract class Info with _$Info {
  const factory Info({
    required String epId,
    required String epName,
    required List<InfoSeries> series,
    required List<Doc> docs,
  }) = _Info;

  factory Info.fromJson(Map<String, dynamic> json) => _$InfoFromJson(json);
}

@freezed
abstract class Doc with _$Doc {
  const factory Doc({
    required String originalName,
    required String path,
    required String fileServer,
    required String id,
  }) = _Doc;

  factory Doc.fromJson(Map<String, dynamic> json) => _$DocFromJson(json);
}

@freezed
abstract class InfoSeries with _$InfoSeries {
  const factory InfoSeries({
    required String id,
    required String name,
    required String sort,
  }) = _InfoSeries;

  factory InfoSeries.fromJson(Map<String, dynamic> json) =>
      _$InfoSeriesFromJson(json);
}
