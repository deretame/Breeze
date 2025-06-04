// To parse this JSON data, do
//
//     final keywordsJson = keywordsJsonFromJson(jsonString);

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'keywords_json.freezed.dart';
part 'keywords_json.g.dart';

KeywordsJson keywordsJsonFromJson(String str) =>
    KeywordsJson.fromJson(json.decode(str));

String keywordsJsonToJson(KeywordsJson data) => json.encode(data.toJson());

@freezed
abstract class KeywordsJson with _$KeywordsJson {
  const factory KeywordsJson({
    @JsonKey(name: "code") required int code,
    @JsonKey(name: "message") required String message,
    @JsonKey(name: "data") required Data data,
  }) = _KeywordsJson;

  factory KeywordsJson.fromJson(Map<String, dynamic> json) =>
      _$KeywordsJsonFromJson(json);
}

@freezed
abstract class Data with _$Data {
  const factory Data({
    @JsonKey(name: "keywords") required List<String> keywords,
  }) = _Data;

  factory Data.fromJson(Map<String, dynamic> json) => _$DataFromJson(json);
}
