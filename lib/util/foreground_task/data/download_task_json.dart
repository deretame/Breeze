// To parse this JSON data, do
//
//     final downloadTaskJson = downloadTaskJsonFromJson(jsonString);

import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:convert';

part 'download_task_json.freezed.dart';
part 'download_task_json.g.dart';

DownloadTaskJson downloadTaskJsonFromJson(String str) =>
    DownloadTaskJson.fromJson(json.decode(str));

String downloadTaskJsonToJson(DownloadTaskJson data) =>
    json.encode(data.toJson());

@freezed
abstract class DownloadTaskJson with _$DownloadTaskJson {
  const factory DownloadTaskJson({
    required String from,
    required String comicId,
    required String comicName,
    required BikaInfo bikaInfo,
    required List<String> selectedChapters,
    required bool slowDownload,
    required String globalProxy,
  }) = _DownloadTaskJson;

  factory DownloadTaskJson.fromJson(Map<String, dynamic> json) =>
      _$DownloadTaskJsonFromJson(json);
}

@freezed
abstract class BikaInfo with _$BikaInfo {
  const factory BikaInfo({
    required String authorization,
    required String proxy,
  }) = _BikaInfo;

  factory BikaInfo.fromJson(Map<String, dynamic> json) =>
      _$BikaInfoFromJson(json);
}
