// To parse this JSON data, do
//
//     final searchResult = searchResultFromJson(jsonString);

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_result.freezed.dart';
part 'search_result.g.dart';

SearchResult searchResultFromJson(String str) =>
    SearchResult.fromJson(json.decode(str));

String searchResultToJson(SearchResult data) => json.encode(data.toJson());

@freezed
class SearchResult with _$SearchResult {
  const factory SearchResult({
    @JsonKey(name: "comics") required Comics comics,
  }) = _SearchResult;

  factory SearchResult.fromJson(Map<String, dynamic> json) =>
      _$SearchResultFromJson(json);
}

@freezed
class Comics with _$Comics {
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
class Doc with _$Doc {
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
    @JsonKey(name: "totalViews") int? totalViews,
    @JsonKey(name: "totalLikes") int? totalLikes,
  }) = _Doc;

  factory Doc.fromJson(Map<String, dynamic> json) => _$DocFromJson(json);
}

@freezed
class Thumb with _$Thumb {
  const factory Thumb({
    @JsonKey(name: "originalName") required String originalName,
    @JsonKey(name: "path") required String path,
    @JsonKey(name: "fileServer") required String fileServer,
  }) = _Thumb;

  factory Thumb.fromJson(Map<String, dynamic> json) => _$ThumbFromJson(json);
}
