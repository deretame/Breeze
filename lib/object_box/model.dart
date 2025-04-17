import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:objectbox/objectbox.dart';

part 'model.g.dart';

@Entity()
@JsonSerializable()
class BikaComicHistory {
  @Id()
  int id;

  // @Index()
  String comicId;
  String creatorId;
  String creatorGender;
  String creatorName;
  bool creatorVerified;
  int creatorExp;
  int creatorLevel;
  List<String> creatorCharacters;

  // 为啥要写这个玩意儿呢？
  // 因为List<String>使用contain的话，太耗时间了，所以用String拼接起来
  // 这样会提高很多速度
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

  // @Index()
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

  @Index()
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
  @Index()
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
