import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:objectbox/objectbox.dart';
import 'package:zephyr/config/bika/bika_setting.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/config/jm/jm_setting.dart';
import 'package:zephyr/util/foreground_task/data/download_task_json.dart';

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
  // 这个用来放已经下载好的章节的id，用来检测是否下载了
  List<String> epsIds;
  String allInfo;
  @Property(type: PropertyType.date)
  DateTime downloadTime;

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
    required this.epsIds,
    required this.allInfo,
    required this.downloadTime,
  });

  Map<String, dynamic> toJson() => _$JmDownloadToJson(this);

  factory JmDownload.fromJson(Map<String, dynamic> json) =>
      _$JmDownloadFromJson(json);

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

@Entity()
@JsonSerializable()
class UnifiedComicFavorite {
  @Id()
  int id;

  @Unique()
  String uniqueKey;

  String source;
  String comicId;
  String title;
  String description;
  @Property(type: PropertyType.flex)
  Map<String, dynamic>? cover;
  @Property(type: PropertyType.flex)
  Map<String, dynamic>? creator;
  @Property(type: PropertyType.flex)
  List<Map<String, dynamic>>? titleMeta;
  @Property(type: PropertyType.flex)
  List<Map<String, dynamic>>? metadata;
  @Property(type: PropertyType.date)
  DateTime createdAt;
  @Property(type: PropertyType.date)
  DateTime updatedAt;
  bool deleted;
  int schemaVersion;

  UnifiedComicFavorite({
    this.id = 0,
    required this.uniqueKey,
    required this.source,
    required this.comicId,
    required this.title,
    required this.description,
    required this.cover,
    required this.creator,
    required this.titleMeta,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
    required this.deleted,
    required this.schemaVersion,
  });

  Map<String, dynamic> toJson() => _$UnifiedComicFavoriteToJson(this);

  factory UnifiedComicFavorite.fromJson(Map<String, dynamic> json) =>
      _$UnifiedComicFavoriteFromJson(json);

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

@Entity()
@JsonSerializable()
class UnifiedComicHistory {
  @Id()
  int id;

  @Unique()
  String uniqueKey;

  String source;
  String comicId;
  String title;
  String description;
  @Property(type: PropertyType.flex)
  Map<String, dynamic>? cover;
  @Property(type: PropertyType.flex)
  Map<String, dynamic>? creator;
  @Property(type: PropertyType.flex)
  List<Map<String, dynamic>>? titleMeta;
  @Property(type: PropertyType.flex)
  List<Map<String, dynamic>>? metadata;
  String chapterId;
  String chapterTitle;
  int chapterOrder;
  int pageIndex;
  @Property(type: PropertyType.date)
  DateTime createdAt;
  @Property(type: PropertyType.date)
  DateTime lastReadAt;
  @Property(type: PropertyType.date)
  DateTime updatedAt;
  bool deleted;
  int schemaVersion;

  UnifiedComicHistory({
    this.id = 0,
    required this.uniqueKey,
    required this.source,
    required this.comicId,
    required this.title,
    required this.description,
    required this.cover,
    required this.creator,
    required this.titleMeta,
    required this.metadata,
    required this.chapterId,
    required this.chapterTitle,
    required this.chapterOrder,
    required this.pageIndex,
    required this.createdAt,
    required this.lastReadAt,
    required this.updatedAt,
    required this.deleted,
    required this.schemaVersion,
  });

  Map<String, dynamic> toJson() => _$UnifiedComicHistoryToJson(this);

  factory UnifiedComicHistory.fromJson(Map<String, dynamic> json) =>
      _$UnifiedComicHistoryFromJson(json);

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

@Entity()
@JsonSerializable()
class UnifiedComicDownload {
  @Id()
  int id;

  @Unique()
  String uniqueKey;

  String source;
  String comicId;
  String title;
  String description;
  @Property(type: PropertyType.flex)
  Map<String, dynamic>? cover;
  @Property(type: PropertyType.flex)
  Map<String, dynamic>? creator;
  @Property(type: PropertyType.flex)
  List<Map<String, dynamic>>? titleMeta;
  @Property(type: PropertyType.flex)
  List<Map<String, dynamic>>? metadata;
  int totalViews;
  int totalLikes;
  int totalComments;
  bool isFavourite;
  bool isLiked;
  bool allowComment;
  bool allowLike;
  bool allowFavorite;
  bool allowDownload;
  @Property(type: PropertyType.flex)
  List<Map<String, dynamic>>? chapters;
  String detailJson;
  String storageRoot;
  @Property(type: PropertyType.date)
  DateTime createdAt;
  @Property(type: PropertyType.date)
  DateTime updatedAt;
  @Property(type: PropertyType.date)
  DateTime downloadedAt;
  bool deleted;
  int schemaVersion;

  UnifiedComicDownload({
    this.id = 0,
    required this.uniqueKey,
    required this.source,
    required this.comicId,
    required this.title,
    required this.description,
    required this.cover,
    required this.creator,
    required this.titleMeta,
    required this.metadata,
    required this.totalViews,
    required this.totalLikes,
    required this.totalComments,
    required this.isFavourite,
    required this.isLiked,
    required this.allowComment,
    required this.allowLike,
    required this.allowFavorite,
    required this.allowDownload,
    required this.chapters,
    required this.detailJson,
    required this.storageRoot,
    required this.createdAt,
    required this.updatedAt,
    required this.downloadedAt,
    required this.deleted,
    required this.schemaVersion,
  });

  Map<String, dynamic> toJson() => _$UnifiedComicDownloadToJson(this);

  factory UnifiedComicDownload.fromJson(Map<String, dynamic> json) =>
      _$UnifiedComicDownloadFromJson(json);

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

@Entity()
@JsonSerializable()
class UserSetting {
  @Id()
  int id;

  // 1. ObjectBox 存储字段 (String 类型)
  String? globalSettingData;
  String? bikaSettingData;
  String? jmSettingData;
  String jmJwt;

  // 2. 内存缓存字段 (@Transient)
  @Transient()
  GlobalSettingState? _globalSetting;
  @Transient()
  BikaSettingState? _bikaSetting;
  @Transient()
  JmSettingState? _jmSetting;

  UserSetting({
    this.id = 0,
    this.globalSettingData,
    this.bikaSettingData,
    this.jmSettingData,
    this.jmJwt = '',
  });

  GlobalSettingState get globalSetting {
    if (_globalSetting == null && globalSettingData != null) {
      _globalSetting = GlobalSettingState.fromJson(
        jsonDecode(globalSettingData!),
      );
    }
    return _globalSetting ??= GlobalSettingState();
  }

  set globalSetting(GlobalSettingState value) {
    _globalSetting = value;
    globalSettingData = jsonEncode(value.toJson());
  }

  BikaSettingState get bikaSetting {
    if (_bikaSetting == null && bikaSettingData != null) {
      _bikaSetting = BikaSettingState.fromJson(jsonDecode(bikaSettingData!));
    }
    return _bikaSetting ??= BikaSettingState();
  }

  set bikaSetting(BikaSettingState value) {
    _bikaSetting = value;
    bikaSettingData = jsonEncode(value.toJson());
  }

  JmSettingState get jmSetting {
    if (_jmSetting == null && jmSettingData != null) {
      _jmSetting = JmSettingState.fromJson(jsonDecode(jmSettingData!));
    }
    return _jmSetting ??= JmSettingState();
  }

  set jmSetting(JmSettingState value) {
    _jmSetting = value;
    jmSettingData = jsonEncode(value.toJson());
  }

  Map<String, dynamic> toJson() => _$UserSettingToJson(this);

  factory UserSetting.fromJson(Map<String, dynamic> json) =>
      _$UserSettingFromJson(json);

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

@Entity()
@JsonSerializable()
class DownloadTask {
  DownloadTask();

  @Id()
  int id = 0;

  String comicId = "";

  String comicName = "";

  bool isCompleted = false;

  bool isDownloading = false;

  String status = "";

  @Property(type: PropertyType.flex)
  Map<String, dynamic>? dbTaskInfo;

  @Transient()
  DownloadTaskJson? _taskInfo;

  @Transient()
  DownloadTaskJson? get taskInfo {
    if (_taskInfo == null && dbTaskInfo != null) {
      _taskInfo = DownloadTaskJson.fromJson(dbTaskInfo!);
    }
    return _taskInfo;
  }

  set taskInfo(DownloadTaskJson? value) {
    _taskInfo = value;
    dbTaskInfo = value?.toJson();
  }

  Map<String, dynamic> toJson() => _$DownloadTaskToJson(this);

  factory DownloadTask.fromJson(Map<String, dynamic> json) =>
      _$DownloadTaskFromJson(json);

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

@Entity()
@JsonSerializable()
class PluginConfig {
  @Id()
  int id;

  String name;

  @Property(type: PropertyType.flex)
  Map<String, dynamic>? data;

  PluginConfig({this.id = 0, required this.name, required this.data});

  Map<String, dynamic> toJson() => _$PluginConfigToJson(this);

  factory PluginConfig.fromJson(Map<String, dynamic> json) =>
      _$PluginConfigFromJson(json);

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

@Entity()
@JsonSerializable()
class PluginInfo {
  @Id()
  int id = 0;

  @Unique()
  String uuid;

  String version;

  bool lastLoadSuccess;

  String? lastLoadError;

  @Property(type: PropertyType.date)
  DateTime insertedAt;

  @Property(type: PropertyType.date)
  DateTime updatedAt;

  bool isEnabled;

  bool isDeleted;

  @Property(type: PropertyType.date)
  DateTime? deletedAt;

  bool debug = false;

  String? debugUrl;

  PluginInfo({
    this.id = 0,
    required this.uuid,
    required this.version,
    required this.insertedAt,
    required this.updatedAt,
    required this.isEnabled,
    required this.isDeleted,
    this.deletedAt,
    required this.lastLoadSuccess,
    this.lastLoadError,
    required this.debug,
    this.debugUrl,
  });

  Map<String, dynamic> toJson() => _$PluginInfoToJson(this);

  factory PluginInfo.fromJson(Map<String, dynamic> json) =>
      _$PluginInfoFromJson(json);

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
