// To parse this JSON data, do
//
//     final comicSimplifyEntryInfo = comicSimplifyEntryInfoFromJson(jsonString);

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'comic_simplify_entry_info.freezed.dart';
part 'comic_simplify_entry_info.g.dart';

ComicSimplifyEntryInfo comicSimplifyEntryInfoFromJson(String str) =>
    ComicSimplifyEntryInfo.fromJson(json.decode(str));

String comicSimplifyEntryInfoToJson(ComicSimplifyEntryInfo data) =>
    json.encode(data.toJson());

@freezed
abstract class ComicSimplifyEntryInfo with _$ComicSimplifyEntryInfo {
  const factory ComicSimplifyEntryInfo({
    @JsonKey(name: "title") required String title,
    @JsonKey(name: "id") required String id,
    @JsonKey(name: "fileServer") required String fileServer,
    @JsonKey(name: "path") required String path,
    @JsonKey(name: "pictureType") required String pictureType,
    @JsonKey(name: "from") required String from,
  }) = _ComicSimplifyEntryInfo;

  factory ComicSimplifyEntryInfo.fromJson(Map<String, dynamic> json) =>
      _$ComicSimplifyEntryInfoFromJson(json);
}
