// To parse this JSON data, do
//
//     final recommendJson = recommendJsonFromJson(jsonString);

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'recommend_json.freezed.dart';
part 'recommend_json.g.dart';

RecommendJson recommendJsonFromJson(String str) =>
    RecommendJson.fromJson(json.decode(str));

String recommendJsonToJson(RecommendJson data) => json.encode(data.toJson());

@freezed
class RecommendJson with _$RecommendJson {
  const factory RecommendJson({
    @JsonKey(name: "code") required int code,
    @JsonKey(name: "message") required String message,
    @JsonKey(name: "data") required Data data,
  }) = _RecommendJson;

  factory RecommendJson.fromJson(Map<String, dynamic> json) =>
      _$RecommendJsonFromJson(json);
}

@freezed
class Data with _$Data {
  const factory Data({@JsonKey(name: "comics") required List<Comic> comics}) =
      _Data;

  factory Data.fromJson(Map<String, dynamic> json) => _$DataFromJson(json);
}

@freezed
class Comic with _$Comic {
  const factory Comic({
    @JsonKey(name: "_id") required String id,
    @JsonKey(name: "title") required String title,
    @JsonKey(name: "thumb") required Thumb thumb,
    @JsonKey(name: "author") required String author,
    @JsonKey(name: "categories") required List<String> categories,
    @JsonKey(name: "finished") required bool finished,
    @JsonKey(name: "epsCount") required int epsCount,
    @JsonKey(name: "pagesCount") required int pagesCount,
    @JsonKey(name: "likesCount") required int likesCount,
  }) = _Comic;

  factory Comic.fromJson(Map<String, dynamic> json) => _$ComicFromJson(json);
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
