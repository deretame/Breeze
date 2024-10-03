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
class Eps with _$Eps {
  const factory Eps({
    @JsonKey(name: "eps") required EpsClass eps,
  }) = _Eps;

  factory Eps.fromJson(Map<String, dynamic> json) => _$EpsFromJson(json);
}

@freezed
class EpsClass with _$EpsClass {
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
class Doc with _$Doc {
  const factory Doc({
    @JsonKey(name: "_id") required String id,
    @JsonKey(name: "title") required String title,
    @JsonKey(name: "order") required int order,
    @JsonKey(name: "updated_at") required DateTime updatedAt,
    @JsonKey(name: "id") required String docId,
  }) = _Doc;

  factory Doc.fromJson(Map<String, dynamic> json) => _$DocFromJson(json);
}
