// To parse this JSON data, do
//
//     final hotList = hotListFromJson(jsonString);

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'hot_list.freezed.dart';
part 'hot_list.g.dart';

HotList hotListFromJson(String str) => HotList.fromJson(json.decode(str));

String hotListToJson(HotList data) => json.encode(data.toJson());

@freezed
class HotList with _$HotList {
  const factory HotList({
    @JsonKey(name: "comics") required List<Comic> comics,
  }) = _HotList;

  factory HotList.fromJson(Map<String, dynamic> json) =>
      _$HotListFromJson(json);
}

@freezed
class Comic with _$Comic {
  const factory Comic({
    @JsonKey(name: "_id") required String id,
    @JsonKey(name: "title") required String title,
    @JsonKey(name: "author") required String author,
    @JsonKey(name: "totalViews") required int totalViews,
    @JsonKey(name: "totalLikes") required int totalLikes,
    @JsonKey(name: "pagesCount") required int pagesCount,
    @JsonKey(name: "epsCount") required int epsCount,
    @JsonKey(name: "finished") required bool finished,
    @JsonKey(name: "categories") required List<String> categories,
    @JsonKey(name: "thumb") required Thumb thumb,
    @JsonKey(name: "viewsCount") required int viewsCount,
    @JsonKey(name: "leaderboardCount") required int leaderboardCount,
  }) = _Comic;

  factory Comic.fromJson(Map<String, dynamic> json) => _$ComicFromJson(json);
}

@freezed
class Thumb with _$Thumb {
  const factory Thumb({
    @JsonKey(name: "fileServer") required String fileServer,
    @JsonKey(name: "path") required String path,
    @JsonKey(name: "originalName") required String originalName,
  }) = _Thumb;

  factory Thumb.fromJson(Map<String, dynamic> json) => _$ThumbFromJson(json);
}
