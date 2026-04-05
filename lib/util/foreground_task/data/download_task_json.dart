// To parse this JSON data, do
//
//     final downloadTaskJson = downloadTaskJsonFromJson(jsonString);

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'download_task_json.freezed.dart';
part 'download_task_json.g.dart';

DownloadTaskJson downloadTaskJsonFromJson(String str) =>
    DownloadTaskJson.fromJson(json.decode(str));

String downloadTaskJsonToJson(DownloadTaskJson data) =>
    json.encode(data.toJson());

@Freezed(makeCollectionsUnmodifiable: false)
abstract class DownloadTaskJson with _$DownloadTaskJson {
  @JsonSerializable(explicitToJson: true)
  const factory DownloadTaskJson({
    required String from,
    required String comicId,
    required String comicName,
    required List<String> selectedChapters,
    required bool slowDownload,
  }) = _DownloadTaskJson;

  factory DownloadTaskJson.fromJson(Map<String, dynamic> json) =>
      _$DownloadTaskJsonFromJson(json);
}
