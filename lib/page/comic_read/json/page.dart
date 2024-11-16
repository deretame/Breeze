// To parse this JSON data, do
//
//     final page = pageFromJson(jsonString);

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'page.freezed.dart';
part 'page.g.dart';

Page pageFromJson(String str) => Page.fromJson(json.decode(str));

String pageToJson(Page data) => json.encode(data.toJson());

@freezed
class Page with _$Page {
  const factory Page({
    @JsonKey(name: "code") required int code,
    @JsonKey(name: "message") required String message,
    @JsonKey(name: "data") required Data data,
  }) = _Page;

  factory Page.fromJson(Map<String, dynamic> json) => _$PageFromJson(json);
}

@freezed
class Data with _$Data {
  const factory Data({
    @JsonKey(name: "pages") required Pages pages,
    @JsonKey(name: "ep") required Ep ep,
  }) = _Data;

  factory Data.fromJson(Map<String, dynamic> json) => _$DataFromJson(json);
}

@freezed
class Ep with _$Ep {
  const factory Ep({
    @JsonKey(name: "_id") required String id,
    @JsonKey(name: "title") required String title,
  }) = _Ep;

  factory Ep.fromJson(Map<String, dynamic> json) => _$EpFromJson(json);
}

@freezed
class Pages with _$Pages {
  const factory Pages({
    @JsonKey(name: "docs") required List<Doc> docs,
    @JsonKey(name: "total") required int total,
    @JsonKey(name: "limit") required int limit,
    @JsonKey(name: "page") required int page,
    @JsonKey(name: "pages") required int pages,
  }) = _Pages;

  factory Pages.fromJson(Map<String, dynamic> json) => _$PagesFromJson(json);
}

@freezed
class Doc with _$Doc {
  const factory Doc({
    @JsonKey(name: "_id") required String id,
    @JsonKey(name: "media") required Media media,
    @JsonKey(name: "id") required String docId,
  }) = _Doc;

  factory Doc.fromJson(Map<String, dynamic> json) => _$DocFromJson(json);
}

@freezed
class Media with _$Media {
  const factory Media({
    @JsonKey(name: "originalName") required String originalName,
    @JsonKey(name: "path") required String path,
    @JsonKey(name: "fileServer") required String fileServer,
  }) = _Media;

  factory Media.fromJson(Map<String, dynamic> json) => _$MediaFromJson(json);
}
