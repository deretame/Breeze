import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:objectbox/objectbox.dart';

part 'model.g.dart';

@Entity()
@JsonSerializable()
class BikaComicHistory {
  @Id()
  int id;

  String comicId;
  String creatorId;
  String creatorGender;
  String creatorName;
  bool creatorVerified;
  int creatorExp;
  int creatorLevel;
  List<String> creatorCharacters;
  String creatorCharactersString;
  String creatorRole;
  String creatorTitle;
  String creatorAvatarOriginalName;
  String creatorAvatarPath;
  String creatorAvatarFileServer;
  String creatorSlogan;
  String title;
  String description;
  String thumbOriginalName;
  String thumbPath;
  String thumbFileServer;
  String author;
  String chineseTeam;
  List<String> categories;
  String categoriesString;
  List<String> tags;
  String tagsString;
  int pagesCount;
  int epsCount;
  bool finished;
  @Property(type: PropertyType.date)
  DateTime updatedAt;
  @Property(type: PropertyType.date)
  DateTime createdAt;
  bool allowDownload;
  bool allowComment;
  int totalLikes;
  int totalViews;
  int totalComments;
  int viewsCount;
  int likesCount;
  int commentsCount;
  bool isFavourite;
  bool isLiked;
  @Property(type: PropertyType.date)
  DateTime history;

  // 下面都是章节的观看历史信息
  int order;
  String epTitle;
  int epPageCount;
  String epId;

  bool deleted;

  BikaComicHistory({
    this.id = 0,
    required this.comicId,
    required this.creatorId,
    required this.creatorGender,
    required this.creatorName,
    required this.creatorVerified,
    required this.creatorExp,
    required this.creatorLevel,
    required this.creatorCharacters,
    required this.creatorCharactersString,
    required this.creatorRole,
    required this.creatorTitle,
    required this.creatorAvatarOriginalName,
    required this.creatorAvatarPath,
    required this.creatorAvatarFileServer,
    required this.creatorSlogan,
    required this.title,
    required this.description,
    required this.thumbOriginalName,
    required this.thumbPath,
    required this.thumbFileServer,
    required this.author,
    required this.chineseTeam,
    required this.categories,
    required this.categoriesString,
    required this.tags,
    required this.tagsString,
    required this.pagesCount,
    required this.epsCount,
    required this.finished,
    required this.updatedAt,
    required this.createdAt,
    required this.allowDownload,
    required this.allowComment,
    required this.totalLikes,
    required this.totalViews,
    required this.totalComments,
    required this.viewsCount,
    required this.likesCount,
    required this.commentsCount,
    required this.isFavourite,
    required this.isLiked,
    required this.history,
    required this.order,
    required this.epTitle,
    required this.epPageCount,
    required this.epId,
    required this.deleted,
  });

  Map<String, dynamic> toJson() => _$BikaComicHistoryToJson(this);

  // 实现 fromJson 方法
  factory BikaComicHistory.fromJson(Map<String, dynamic> json) =>
      _$BikaComicHistoryFromJson(json);

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

@Entity()
@JsonSerializable()
class BikaComicDownload {
  @Id()
  int id;

  String comicId;
  String creatorId;
  String creatorGender;
  String creatorName;
  bool creatorVerified;
  int creatorExp;
  int creatorLevel;
  List<String> creatorCharacters;
  String creatorCharactersString;
  String creatorRole;
  String creatorTitle;
  String creatorAvatarOriginalName;
  String creatorAvatarPath;
  String creatorAvatarFileServer;
  String creatorSlogan;
  String title;
  String description;
  String thumbOriginalName;
  String thumbPath;
  String thumbFileServer;
  String author;
  String chineseTeam;
  List<String> categories;
  String categoriesString;
  List<String> tags;
  String tagsString;
  int pagesCount;
  int epsCount;
  bool finished;
  @Property(type: PropertyType.date)
  DateTime updatedAt;
  @Property(type: PropertyType.date)
  DateTime createdAt;
  bool allowDownload;
  bool allowComment;
  int totalLikes;
  int totalViews;
  int totalComments;
  int viewsCount;
  int likesCount;
  int commentsCount;
  bool isFavourite;
  bool isLiked;
  @Property(type: PropertyType.date)
  DateTime downloadTime;

  // 这个用来放已经下载好的章节的标题，用来检测是否下载了
  List<String> epsTitle;

  // 这个用来放漫画的全部的信息，是一个json字符串
  String comicInfoAll;

  BikaComicDownload({
    this.id = 0,
    required this.comicId,
    required this.creatorId,
    required this.creatorGender,
    required this.creatorName,
    required this.creatorVerified,
    required this.creatorExp,
    required this.creatorLevel,
    required this.creatorCharacters,
    required this.creatorCharactersString,
    required this.creatorRole,
    required this.creatorTitle,
    required this.creatorAvatarOriginalName,
    required this.creatorAvatarPath,
    required this.creatorAvatarFileServer,
    required this.creatorSlogan,
    required this.title,
    required this.description,
    required this.thumbOriginalName,
    required this.thumbPath,
    required this.thumbFileServer,
    required this.author,
    required this.chineseTeam,
    required this.categories,
    required this.categoriesString,
    required this.tags,
    required this.tagsString,
    required this.pagesCount,
    required this.epsCount,
    required this.finished,
    required this.updatedAt,
    required this.createdAt,
    required this.allowDownload,
    required this.allowComment,
    required this.totalLikes,
    required this.totalViews,
    required this.totalComments,
    required this.viewsCount,
    required this.likesCount,
    required this.commentsCount,
    required this.isFavourite,
    required this.isLiked,
    required this.downloadTime,
    required this.epsTitle,
    required this.comicInfoAll,
  });

  Map<String, dynamic> toJson() => _$BikaComicDownloadToJson(this);

  factory BikaComicDownload.fromJson(Map<String, dynamic> json) =>
      _$BikaComicDownloadFromJson(json);

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

@Entity()
@JsonSerializable()
class JmFavorite {
  @Id()
  int id;

  String comicId;
  String name;
  String addtime;
  String description;
  String totalViews;
  String likes;
  String seriesId;
  String commentTotal;
  List<String> author;
  List<String> tags;
  List<String> works;
  List<String> actors;
  bool liked;
  bool isFavorite;
  bool isAids;
  String price;
  String purchased;

  bool deleted;
  @Property(type: PropertyType.date)
  DateTime history;

  JmFavorite({
    this.id = 0,
    required this.comicId,
    required this.name,
    required this.addtime,
    required this.description,
    required this.totalViews,
    required this.likes,
    required this.seriesId,
    required this.commentTotal,
    required this.author,
    required this.tags,
    required this.works,
    required this.actors,
    required this.liked,
    required this.isFavorite,
    required this.isAids,
    required this.price,
    required this.purchased,
    required this.deleted,
    required this.history,
  });

  Map<String, dynamic> toJson() => _$JmFavoriteToJson(this);

  factory JmFavorite.fromJson(Map<String, dynamic> json) =>
      _$JmFavoriteFromJson(json);

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

@Entity()
@JsonSerializable()
class JmHistory {
  @Id()
  int id;

  String comicId;
  String name;
  String addtime;
  String description;
  String totalViews;
  String likes;
  String seriesId;
  String commentTotal;
  List<String> author;
  List<String> tags;
  List<String> works;
  List<String> actors;
  bool liked;
  bool isFavorite;
  bool isAids;
  String price;
  String purchased;

  // 下面都是章节的观看历史信息
  int order;
  String epTitle;
  int epPageCount;
  String epId;

  bool deleted;
  @Property(type: PropertyType.date)
  DateTime history;

  JmHistory({
    this.id = 0,
    required this.comicId,
    required this.name,
    required this.addtime,
    required this.description,
    required this.totalViews,
    required this.likes,
    required this.seriesId,
    required this.commentTotal,
    required this.author,
    required this.tags,
    required this.works,
    required this.actors,
    required this.liked,
    required this.isFavorite,
    required this.isAids,
    required this.price,
    required this.purchased,
    required this.order,
    required this.epTitle,
    required this.epPageCount,
    required this.epId,
    required this.deleted,
    required this.history,
  });

  Map<String, dynamic> toJson() => _$JmHistoryToJson(this);

  factory JmHistory.fromJson(Map<String, dynamic> json) =>
      _$JmHistoryFromJson(json);

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

@Entity()
@JsonSerializable()
class JmDownload {
  @Id()
  int id;

  String comicId;
  String name;
  String addtime;
  String description;
  String totalViews;
  String likes;
  String seriesId;
  String commentTotal;
  List<String> author;
  List<String> tags;
  List<String> works;
  List<String> actors;
  bool liked;
  bool isFavorite;
  bool isAids;
  String price;
  String purchased;
  // 这个用来放已经下载好的章节的标题，用来检测是否下载了
  List<String> epsTitle;
  String allInfo;

  JmDownload({
    this.id = 0,
    required this.comicId,
    required this.name,
    required this.addtime,
    required this.description,
    required this.totalViews,
    required this.likes,
    required this.seriesId,
    required this.commentTotal,
    required this.author,
    required this.tags,
    required this.works,
    required this.actors,
    required this.liked,
    required this.isFavorite,
    required this.isAids,
    required this.price,
    required this.purchased,
    required this.epsTitle,
    required this.allInfo,
  });

  Map<String, dynamic> toJson() => _$JmDownloadToJson(this);

  factory JmDownload.fromJson(Map<String, dynamic> json) =>
      _$JmDownloadFromJson(json);

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
