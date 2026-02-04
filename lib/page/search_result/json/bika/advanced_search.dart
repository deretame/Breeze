// To parse this JSON data, do
//
//     final advancedSearch = advancedSearchFromJson(jsonString);

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'advanced_search.freezed.dart';
part 'advanced_search.g.dart';

AdvancedSearch advancedSearchFromJson(String str) =>
    AdvancedSearch.fromJson(json.decode(str));

String advancedSearchToJson(AdvancedSearch data) => json.encode(data.toJson());

@freezed
abstract class AdvancedSearch with _$AdvancedSearch {
  const factory AdvancedSearch({
    @JsonKey(name: "code") required int code,
    @JsonKey(name: "message") required String message,
    @JsonKey(name: "data") required Data data,
  }) = _AdvancedSearch;

  factory AdvancedSearch.fromJson(Map<String, dynamic> json) =>
      _$AdvancedSearchFromJson(json);
}

@freezed
abstract class Data with _$Data {
  const factory Data({@JsonKey(name: "comics") required Comics comics}) = _Data;

  factory Data.fromJson(Map<String, dynamic> json) => _$DataFromJson(json);
}

@freezed
abstract class Comics with _$Comics {
  const factory Comics({
    @JsonKey(name: "total") required int total,
    @JsonKey(name: "page") required int page,
    @JsonKey(name: "pages") required int pages,
    @JsonKey(name: "docs") required List<Doc> docs,
    @JsonKey(name: "limit") required int limit,
  }) = _Comics;

  factory Comics.fromJson(Map<String, dynamic> json) => _$ComicsFromJson(json);
}

@freezed
abstract class Doc with _$Doc {
  const factory Doc({
    @JsonKey(name: "updated_at") required DateTime updatedAt,
    @JsonKey(name: "thumb") required Thumb thumb,
    @JsonKey(name: "author") required String author,
    @JsonKey(name: "description") required String description,
    @JsonKey(name: "chineseTeam") required String chineseTeam,
    @JsonKey(name: "created_at") required DateTime createdAt,
    @JsonKey(name: "finished") required bool finished,
    @JsonKey(name: "categories") required List<String> categories,
    @JsonKey(name: "title") required String title,
    @JsonKey(name: "tags") required List<String> tags,
    @JsonKey(name: "_id") required String id,
    @JsonKey(name: "likesCount") required int likesCount,
  }) = _Doc;

  factory Doc.fromJson(Map<String, dynamic> json) => _$DocFromJson(json);
}

@freezed
abstract class Thumb with _$Thumb {
  const factory Thumb({
    @JsonKey(name: "originalName") required String originalName,
    @JsonKey(name: "path") required String path,
    @JsonKey(name: "fileServer") required String fileServer,
  }) = _Thumb;

  factory Thumb.fromJson(Map<String, dynamic> json) => _$ThumbFromJson(json);
}
