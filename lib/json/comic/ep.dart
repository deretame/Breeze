// To parse this JSON data, do
//
//     final ep = epFromJson(jsonString);

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'ep.freezed.dart';
part 'ep.g.dart';

Ep epFromJson(String str) => Ep.fromJson(json.decode(str));

String epToJson(Ep data) => json.encode(data.toJson());

@freezed
class Ep with _$Ep {
  const factory Ep({
    @JsonKey(name: "pages") required Pages pages,
    @JsonKey(name: "ep") required EpClass ep,
  }) = _Ep;

  factory Ep.fromJson(Map<String, dynamic> json) => _$EpFromJson(json);
}

@freezed
class EpClass with _$EpClass {
  const factory EpClass({
    @JsonKey(name: "_id") required String id,
    @JsonKey(name: "title") required String title,
  }) = _EpClass;

  factory EpClass.fromJson(Map<String, dynamic> json) =>
      _$EpClassFromJson(json);
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
