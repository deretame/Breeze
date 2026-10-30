import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:objectbox/objectbox.dart';
import 'package:zephyr/config/bika/bika_setting.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/config/jm/jm_setting.dart';
import 'package:zephyr/service/download/models/download_task_json.dart';

part 'model.g.dart';

@Entity()
@JsonSerializable()
@Deprecated("不再使用，仅作为迁移时作为参考数据结构")
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
@Deprecated("不再使用，仅作为迁移时作为参考数据结构")
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
@Deprecated("不再使用，仅作为迁移时作为参考数据结构")
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
@Deprecated("不再使用，仅作为迁移时作为参考数据结构")
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
@Deprecated("不再使用，仅作为迁移时作为参考数据结构")
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
  String cover;
  String creator;
  String titleMeta;
  String metadata;
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
  String cover;
  String creator;
  String titleMeta;
  String metadata;
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
  String cover;
  String creator;
  String titleMeta;
  String metadata;
  int totalViews;
  int totalLikes;
  int totalComments;
  bool isFavourite;
  bool isLiked;
  bool allowComment;
  bool allowLike;
  bool allowFavorite;
  bool allowDownload;
  String chapters;
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

  @Transient()
  GlobalSettingState get globalSetting {
    if (_globalSetting == null && globalSettingData != null) {
      _globalSetting = GlobalSettingState.fromJson(
        jsonDecode(globalSettingData!),
      );
    }
    return _globalSetting ??= GlobalSettingState();
  }

  @Transient()
  set globalSetting(GlobalSettingState value) {
    _globalSetting = value;
    globalSettingData = jsonEncode(value.toJson());
  }

  @Transient()
  BikaSettingState get bikaSetting {
    if (_bikaSetting == null && bikaSettingData != null) {
      _bikaSetting = BikaSettingState.fromJson(jsonDecode(bikaSettingData!));
    }
    return _bikaSetting ??= BikaSettingState();
  }

  @Transient()
  set bikaSetting(BikaSettingState value) {
    _bikaSetting = value;
    bikaSettingData = jsonEncode(value.toJson());
  }

  @Transient()
  JmSettingState get jmSetting {
    if (_jmSetting == null && jmSettingData != null) {
      _jmSetting = JmSettingState.fromJson(jsonDecode(jmSettingData!));
    }
    return _jmSetting ??= JmSettingState();
  }

  @Transient()
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

  String? dbTaskInfoStr;

  @Transient()
  DownloadTaskJson? _taskInfo;

  @Transient()
  DownloadTaskJson? get taskInfo {
    if (_taskInfo == null &&
        dbTaskInfoStr != null &&
        dbTaskInfoStr!.isNotEmpty) {
      _taskInfo = DownloadTaskJson.fromJson(
        jsonDecode(dbTaskInfoStr!) as Map<String, dynamic>,
      );
    }
    return _taskInfo;
  }

  set taskInfo(DownloadTaskJson? value) {
    _taskInfo = value;
    dbTaskInfoStr = value == null ? null : jsonEncode(value.toJson());
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

  String config;

  PluginConfig({this.id = 0, required this.name, required this.config});

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

  String originScript;

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

  /// 用户自定义的插件顺序；为空时回退到 [insertedAt]。
  int? sortOrder;

  bool debug = false;

  String? debugUrl;

  /// getInfo 返回的完整 JSON 字符串缓存（用于更新通道 npmName / updateUrl 等）。
  String getInfoJson;

  PluginInfo({
    this.id = 0,
    required this.uuid,
    required this.version,
    required this.originScript,
    required this.insertedAt,
    required this.updatedAt,
    required this.isEnabled,
    required this.isDeleted,
    this.deletedAt,
    required this.lastLoadSuccess,
    this.lastLoadError,
    this.sortOrder,
    required this.debug,
    this.debugUrl,
    this.getInfoJson = '',
  });

  Map<String, dynamic> toJson() => _$PluginInfoToJson(this);

  factory PluginInfo.fromJson(Map<String, dynamic> json) =>
      _$PluginInfoFromJson(json);

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

@Entity()
@JsonSerializable()
class ComicFollow {
  @Id()
  int id;

  @Unique()
  String uniqueKey;

  String source;
  String comicId;
  String title;
  String description;
  String cover;
  String creator;
  String titleMeta;
  String metadata;

  /// 上次进入漫画 / 加入追更时的章节数
  int lastChapterCount;

  /// 检测到的最新章节数
  int detectedChapterCount;

  /// 检测到的最新章节名称
  String detectedChapterTitle;

  /// 是否有更新
  bool hasUpdate;

  /// 最近一次检测是否失败（仅内存，不持久化）
  @Transient()
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool lastCheckFailed;

  @Property(type: PropertyType.date)
  DateTime updateTime;

  bool deleted;

  @Property(type: PropertyType.date)
  DateTime createdAt;

  @Property(type: PropertyType.date)
  DateTime updatedAt;

  int schemaVersion;

  ComicFollow({
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
    required this.lastChapterCount,
    required this.detectedChapterCount,
    this.detectedChapterTitle = '',
    required this.hasUpdate,
    this.lastCheckFailed = false,
    required this.updateTime,
    required this.deleted,
    required this.createdAt,
    required this.updatedAt,
    required this.schemaVersion,
  });

  ComicFollow copyWith({
    int? id,
    String? uniqueKey,
    String? source,
    String? comicId,
    String? title,
    String? description,
    String? cover,
    String? creator,
    String? titleMeta,
    String? metadata,
    int? lastChapterCount,
    int? detectedChapterCount,
    String? detectedChapterTitle,
    bool? hasUpdate,
    bool? lastCheckFailed,
    DateTime? updateTime,
    bool? deleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? schemaVersion,
  }) {
    return ComicFollow(
      id: id ?? this.id,
      uniqueKey: uniqueKey ?? this.uniqueKey,
      source: source ?? this.source,
      comicId: comicId ?? this.comicId,
      title: title ?? this.title,
      description: description ?? this.description,
      cover: cover ?? this.cover,
      creator: creator ?? this.creator,
      titleMeta: titleMeta ?? this.titleMeta,
      metadata: metadata ?? this.metadata,
      lastChapterCount: lastChapterCount ?? this.lastChapterCount,
      detectedChapterCount: detectedChapterCount ?? this.detectedChapterCount,
      detectedChapterTitle: detectedChapterTitle ?? this.detectedChapterTitle,
      hasUpdate: hasUpdate ?? this.hasUpdate,
      lastCheckFailed: lastCheckFailed ?? this.lastCheckFailed,
      updateTime: updateTime ?? this.updateTime,
      deleted: deleted ?? this.deleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toJson() => _$ComicFollowToJson(this);

  factory ComicFollow.fromJson(Map<String, dynamic> json) =>
      _$ComicFollowFromJson(json);

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

/// 漫画文件夹/链接类型：收藏、历史、下载
enum ComicFolderType { favorite, history, download }

@Entity()
@JsonSerializable()
class ComicFolder {
  @Id()
  int id;

  /// 全局稳定同步 ID，创建后不变，跨设备同步时使用。
  @JsonKey(defaultValue: '')
  @Index()
  String syncId;

  /// 父文件夹的 syncId，null 表示根目录
  @Index()
  String? parentSyncId;

  /// 复合唯一键：parentSyncId|name|typeData
  @Unique()
  String uniqueKey;

  /// 显示名称
  String name;

  /// 实际存储的枚举名称：favorite / history / download
  String typeData;

  @Transient()
  @JsonKey(includeFromJson: false, includeToJson: false)
  ComicFolderType get type => ComicFolderType.values.byName(typeData);

  @Transient()
  set type(ComicFolderType value) => typeData = value.name;

  /// 版本向量 JSON 字符串
  String versionVectorJson;

  /// 软删除时间戳（毫秒），null 表示未删除
  int? deletedAt;

  /// 创建时间戳（毫秒）
  int createdAt;

  /// 最后修改时间戳（毫秒）
  int updatedAt;

  ComicFolder({
    this.id = 0,
    required this.syncId,
    this.parentSyncId,
    required this.uniqueKey,
    required this.name,
    required this.typeData,
    required this.versionVectorJson,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => _$ComicFolderToJson(this);

  factory ComicFolder.fromJson(Map<String, dynamic> json) =>
      _$ComicFolderFromJson(json);

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

@Entity()
@JsonSerializable()
class ComicLink {
  @Id()
  int id;

  /// 复合唯一键：comicUniqueKey|folderSyncId|typeData
  @Unique()
  String uniqueKey;

  /// 漫画全局唯一标识（如 UnifiedComicFavorite 的 uniqueKey）
  String comicUniqueKey;

  /// 所属文件夹的 syncId，null 表示根目录
  @Index()
  String? folderSyncId;

  /// 实际存储的枚举名称：favorite / history / download
  String typeData;

  @Transient()
  @JsonKey(includeFromJson: false, includeToJson: false)
  ComicFolderType get type => ComicFolderType.values.byName(typeData);

  @Transient()
  set type(ComicFolderType value) => typeData = value.name;

  /// 版本向量 JSON 字符串
  String versionVectorJson;

  /// 软删除时间戳（毫秒），null 表示未删除
  int? deletedAt;

  /// 创建时间戳（毫秒）
  int createdAt;

  /// 最后修改时间戳（毫秒）
  int updatedAt;

  ComicLink({
    this.id = 0,
    required this.uniqueKey,
    required this.comicUniqueKey,
    this.folderSyncId,
    required this.typeData,
    required this.versionVectorJson,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => _$ComicLinkToJson(this);

  factory ComicLink.fromJson(Map<String, dynamic> json) =>
      _$ComicLinkFromJson(json);

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

/// 单本漫画独立阅读设置（稀疏 patch，与全局共用一套 JSON 结构）。
///
/// [overridesJson] 只存用户显式改过的键（如 `{"readMode":2}`），键名与
/// `ReadSettingState.toJson()` 对齐；没有 key = 没设置 = 跟随全局。
/// 有记录且 [deleted] 为 false 表示启用了本漫特定设置；
/// 删除时清空 patch 并立 [deleted] 墓碑，靠 LWW 同步到其它设备。
/// 合并规则：unix 时间戳（[updatedAt]）更大的保留，与收藏/历史同一套 LWW。
@Entity()
@JsonSerializable()
class ComicReadPreference {
  @Id()
  int id;

  /// 复合唯一键：`$source:$comicId`，与历史/收藏保持一致。
  @Unique()
  String uniqueKey;

  String source;
  String comicId;

  /// 稀疏覆盖 JSON：只含显式设置的 `ReadSettingState` 键。
  String overridesJson;

  /// v12 前的单字段存储，已被 [overridesJson] 取代。
  ///
  /// 保留该列仅用于 v11→v12 存量迁移读取，读写一律走 [overridesJson]；
  /// 存量转完后的版本可删除此列。
  @Deprecated('由 overridesJson 取代，仅迁移读取使用')
  @JsonKey(includeToJson: false)
  int readMode;

  @Property(type: PropertyType.date)
  DateTime updatedAt;

  bool deleted;

  ComicReadPreference({
    this.id = 0,
    required this.uniqueKey,
    required this.source,
    required this.comicId,
    this.overridesJson = '{}',
    @Deprecated('由 overridesJson 取代，仅迁移读取使用') this.readMode = 0,
    required this.updatedAt,
    this.deleted = false,
  });

  /// 本漫独立设置：与全局共用一套 `ReadSettingState` 结构。
  ///
  /// 列里只存用户显式改过的键（稀疏，如 `{"readMode":2}`）；
  /// 返回 null 表示没有覆盖 = 跟随全局（含墓碑行）。
  /// record 的 `keys` 是精确的 key 集合：“有没有设置”看它，不看值。
  /// 脏数据兜底：解析失败返回 null。
  @Transient()
  @JsonKey(includeFromJson: false, includeToJson: false)
  ({ReadSettingState setting, Set<String> keys})? get overrideSetting {
    if (deleted) return null;
    final patch = _readOverridePatch();
    if (patch.isEmpty) return null;
    try {
      return (
        setting: ReadSettingState.fromJson(patch),
        keys: patch.keys.toSet(),
      );
    } catch (_) {
      return null;
    }
  }

  /// 用 [updated] 相对 [current] 的变化更新本列，返回实际变化的 key。
  ///
  /// [includeKeys] 强制记录的键（即使值没变，如首次快照 readMode）。
  /// 只改列内容，不碰 `updatedAt`，落盘由调用方 `box.put`。
  Set<String> applyChanges(
    ReadSettingState current,
    ReadSettingState updated, {
    Set<String> includeKeys = const {},
  }) {
    final before = current.toJson();
    final after = updated.toJson();
    final delta = <String, dynamic>{};
    for (final key in after.keys) {
      if (before[key] != after[key]) delta[key] = after[key];
    }
    for (final key in includeKeys) {
      if (after.containsKey(key)) delta[key] = after[key];
    }
    if (delta.isEmpty) return const {};
    final patch = Map<String, dynamic>.of(_readOverridePatch())
      ..addAll(_sanitizeOverridePatch(delta));
    overridesJson = jsonEncode(patch);
    return delta.keys.toSet();
  }

  /// 解析并清洗后的 patch（内部用）。
  Map<String, dynamic> _readOverridePatch() {
    try {
      final decoded = jsonDecode(overridesJson);
      final map = decoded is Map<String, dynamic>
          ? decoded
          : decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : const <String, dynamic>{};
      return _sanitizeOverridePatch(map);
    } catch (_) {
      return const {};
    }
  }

  Map<String, dynamic> toJson() => _$ComicReadPreferenceToJson(this);

  /// 兼容 v11 及更早：老数据只有 `readMode` 整列，转成 `{"readMode":x}` patch。
  /// 缺 `readMode` 时（新版备份/同步）补 0，生成的 `fromJson` 才能安全解析。
  factory ComicReadPreference.fromJson(Map<String, dynamic> json) {
    json = Map.of(json);
    json.putIfAbsent('readMode', () => 0);
    if (!json.containsKey('overridesJson') && json['readMode'] is num) {
      json['overridesJson'] = jsonEncode({
        'readMode': (json['readMode'] as num).toInt().clamp(0, 2),
      });
    }
    return _$ComicReadPreferenceFromJson(json);
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

/// 搜索书签：记录一次搜索现场 + 锚点漫画，跳转时参数重放直达记录页。
///
/// 不做排序键提取、不做定位探测，无需插件声明：快照只是搜索参数重放。
/// [uniqueKey] 复合唯一：`$source|$keyword|$anchorComicId`。
@Entity()
@JsonSerializable()
class SearchBookmark {
  @Id()
  int id;

  @Unique()
  String uniqueKey;

  /// 插件 uuid。
  String source;

  /// 搜索关键词（trim 后）。
  String keyword;

  /// 记录时的完整搜索 extern JSON（含分类筛选等，排序也在里面）。
  String externJson;

  /// 锚点漫画 id。
  String anchorComicId;

  /// 锚点漫画标题（列表展示用）。
  String anchorTitle;

  /// 锚点漫画封面 JSON（UnifiedComicCover.toJson，可空）。
  String anchorCover;

  /// 记录时锚点所在的页码（跳转目标）。
  int anchorPage;

  /// 记录时锚点在页内的序号（从 0 起，用于精确定位）。
  /// 老数据缺省为 0，揭示时回退 id 查找。
  @JsonKey(defaultValue: 0)
  int anchorIndex;

  @Property(type: PropertyType.date)
  DateTime createdAt;

  @Property(type: PropertyType.date)
  DateTime updatedAt;

  SearchBookmark({
    this.id = 0,
    required this.uniqueKey,
    required this.source,
    required this.keyword,
    required this.externJson,
    required this.anchorComicId,
    required this.anchorTitle,
    required this.anchorCover,
    required this.anchorPage,
    this.anchorIndex = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 记录时的完整搜索 extern（解析失败回退空 map）。
  @Transient()
  @JsonKey(includeFromJson: false, includeToJson: false)
  Map<String, dynamic> get extern {
    try {
      final decoded = jsonDecode(externJson);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return const <String, dynamic>{};
  }

  Map<String, dynamic> toJson() => _$SearchBookmarkToJson(this);

  factory SearchBookmark.fromJson(Map<String, dynamic> json) =>
      _$SearchBookmarkFromJson(json);

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

/// 搜索书签复合唯一键：`$source|$keyword|$anchorComicId`。
String searchBookmarkUniqueKey(
  String source,
  String keyword,
  String anchorComicId,
) {
  return '${source.trim()}|${keyword.trim()}|${anchorComicId.trim()}';
}

/// 只保留 `ReadSettingState` 认识的 key，脏 key（旧版本残留/手改）直接丢弃。
///
/// 白名单与类型都从 `ReadSettingState` 自身派生：以后加字段零改动，
/// 类型按默认值的运行时类型校验（`readMode` 额外钳到 0~2）。
Map<String, dynamic> sanitizeReadSettingPatch(Map<String, dynamic> patch) {
  if (patch.isEmpty) return const {};
  final defaults = const ReadSettingState().toJson();
  final clean = <String, dynamic>{};
  for (final entry in patch.entries) {
    final key = entry.key;
    if (!defaults.containsKey(key)) continue;
    final value = entry.value;
    final fallback = defaults[key];
    if (fallback is bool && value is bool) {
      clean[key] = value;
    } else if (fallback is int && value is num) {
      clean[key] = key == 'readMode'
          ? value.toInt().clamp(0, 2)
          : value.toInt();
    } else if (fallback is String && value is String) {
      clean[key] = value;
    }
  }
  return clean;
}

/// Entity 内部复用（同库私有）：与 [sanitizeReadSettingPatch] 同一实现。
Map<String, dynamic> _sanitizeOverridePatch(Map<String, dynamic> patch) =>
    sanitizeReadSettingPatch(patch);
