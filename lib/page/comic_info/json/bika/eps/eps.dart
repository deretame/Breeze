// To parse this JSON data, do
//
//     final eps = epsFromJson(jsonString);

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'eps.freezed.dart';
part 'eps.g.dart';

Eps epsFromJson(String str) => Eps.fromJson(json.decode(str));

String epsToJson(Eps data) => json.encode(data.toJson());

@freezed
abstract class Eps with _$Eps {
  const factory Eps({
    @JsonKey(name: "code") required int code,
    @JsonKey(name: "message") required String message,
    @JsonKey(name: "data") required Data data,
  }) = _Eps;

  factory Eps.fromJson(Map<String, dynamic> json) => _$EpsFromJson(json);
}

@freezed
abstract class Data with _$Data {
  const factory Data({@JsonKey(name: "eps") required EpsClass eps}) = _Data;

  factory Data.fromJson(Map<String, dynamic> json) => _$DataFromJson(json);
}

@freezed
abstract class EpsClass with _$EpsClass {
  const factory EpsClass({
    @JsonKey(name: "docs") required List<Doc> docs,
    @JsonKey(name: "total") required int total,
    @JsonKey(name: "limit") required int limit,
    @JsonKey(name: "page") required int page,
    @JsonKey(name: "pages") required int pages,
  }) = _EpsClass;

  factory EpsClass.fromJson(Map<String, dynamic> json) =>
      _$EpsClassFromJson(json);
}

@freezed
abstract class Doc with _$Doc {
  const factory Doc({
    @JsonKey(name: "_id") required String id,
    @JsonKey(name: "title") required String title,
    @JsonKey(name: "order") required int order,
    @JsonKey(name: "updated_at") required DateTime updatedAt,
    @JsonKey(name: "id") required String docId,
  }) = _Doc;

  factory Doc.fromJson(Map<String, dynamic> json) => _$DocFromJson(json);
}
