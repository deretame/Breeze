import 'package:objectbox/objectbox.dart';

@Entity()
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
  @Property(type: PropertyType.date)
  DateTime deletedAt;

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
    required this.deletedAt,
  });

  // 实现 toJson 方法
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'comicId': comicId,
      'creatorId': creatorId,
      'creatorGender': creatorGender,
      'creatorName': creatorName,
      'creatorVerified': creatorVerified,
      'creatorExp': creatorExp,
      'creatorLevel': creatorLevel,
      'creatorCharacters': creatorCharacters,
      'creatorCharactersString': creatorCharactersString,
      'creatorRole': creatorRole,
      'creatorTitle': creatorTitle,
      'creatorAvatarOriginalName': creatorAvatarOriginalName,
      'creatorAvatarPath': creatorAvatarPath,
      'creatorAvatarFileServer': creatorAvatarFileServer,
      'creatorSlogan': creatorSlogan,
      'title': title,
      'description': description,
      'thumbOriginalName': thumbOriginalName,
      'thumbPath': thumbPath,
      'thumbFileServer': thumbFileServer,
      'author': author,
      'chineseTeam': chineseTeam,
      'categories': categories,
      'categoriesString': categoriesString,
      'tags': tags,
      'tagsString': tagsString,
      'pagesCount': pagesCount,
      'epsCount': epsCount,
      'finished': finished,
      'updatedAt': updatedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'allowDownload': allowDownload,
      'allowComment': allowComment,
      'totalLikes': totalLikes,
      'totalViews': totalViews,
      'totalComments': totalComments,
      'viewsCount': viewsCount,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'isFavourite': isFavourite,
      'isLiked': isLiked,
      'history': history.toIso8601String(),
      'order': order,
      'epTitle': epTitle,
      'epPageCount': epPageCount,
      'epId': epId,
      'deleted': deleted,
      'deletedAt': deletedAt.toIso8601String()
    };
  }

  // 实现 fromJson 方法
  factory BikaComicHistory.fromJson(Map<String, dynamic> json) {
    return BikaComicHistory(
      id: json['id'] ?? 0,
      comicId: json['comicId'] ?? '',
      creatorId: json['creatorId'] ?? '',
      creatorGender: json['creatorGender'] ?? '',
      creatorName: json['creatorName'] ?? '',
      creatorVerified: json['creatorVerified'] ?? false,
      creatorExp: json['creatorExp'] ?? 0,
      creatorLevel: json['creatorLevel'] ?? 0,
      creatorCharacters: List<String>.from(json['creatorCharacters'] ?? []),
      creatorCharactersString: json['creatorCharactersString'] ?? '',
      creatorRole: json['creatorRole'] ?? '',
      creatorTitle: json['creatorTitle'] ?? '',
      creatorAvatarOriginalName: json['creatorAvatarOriginalName'] ?? '',
      creatorAvatarPath: json['creatorAvatarPath'] ?? '',
      creatorAvatarFileServer: json['creatorAvatarFileServer'] ?? '',
      creatorSlogan: json['creatorSlogan'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      thumbOriginalName: json['thumbOriginalName'] ?? '',
      thumbPath: json['thumbPath'] ?? '',
      thumbFileServer: json['thumbFileServer'] ?? '',
      author: json['author'] ?? '',
      chineseTeam: json['chineseTeam'] ?? '',
      categories: List<String>.from(json['categories'] ?? []),
      categoriesString: json['categoriesString'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      tagsString: json['tagsString'] ?? '',
      pagesCount: json['pagesCount'] ?? 0,
      epsCount: json['epsCount'] ?? 0,
      finished: json['finished'] ?? false,
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      allowDownload: json['allowDownload'] ?? false,
      allowComment: json['allowComment'] ?? false,
      totalLikes: json['totalLikes'] ?? 0,
      totalViews: json['totalViews'] ?? 0,
      totalComments: json['totalComments'] ?? 0,
      viewsCount: json['viewsCount'] ?? 0,
      likesCount: json['likesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      isFavourite: json['isFavourite'] ?? false,
      isLiked: json['isLiked'] ?? false,
      history:
          DateTime.parse(json['history'] ?? DateTime.now().toIso8601String()),
      order: json['order'] ?? 0,
      epTitle: json['epTitle'] ?? '',
      epPageCount: json['epPageCount'] ?? 0,
      epId: json['epId'] ?? '',
      deleted: json['deleted'] ?? false,
      deletedAt:
          DateTime.parse(json['deletedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  @override
  String toString() {
    return 'BikaComicHistory{id: $id, comicId: $comicId, creatorId: $creatorId, creatorGender: $creatorGender, creatorName: $creatorName, creatorVerified: $creatorVerified, creatorExp: $creatorExp, creatorLevel: $creatorLevel, creatorCharacters: $creatorCharacters, creatorCharactersString: $creatorCharactersString, creatorRole: $creatorRole, creatorTitle: $creatorTitle, creatorAvatarOriginalName: $creatorAvatarOriginalName, creatorAvatarPath: $creatorAvatarPath, creatorAvatarFileServer: $creatorAvatarFileServer, creatorSlogan: $creatorSlogan, title: $title, description: $description, thumbOriginalName: $thumbOriginalName, thumbPath: $thumbPath, thumbFileServer: $thumbFileServer, author: $author, chineseTeam: $chineseTeam, categories: $categories, categoriesString: $categoriesString, tags: $tags, tagsString: $tagsString, pagesCount: $pagesCount, epsCount: $epsCount, finished: $finished, updatedAt: $updatedAt, createdAt: $createdAt, allowDownload: $allowDownload, allowComment: $allowComment, totalLikes: $totalLikes, totalViews: $totalViews, totalComments: $totalComments, viewsCount: $viewsCount, likesCount: $likesCount, commentsCount: $commentsCount, isFavourite: $isFavourite, isLiked: $isLiked, history: $history, order: $order, epTitle: $epTitle, epPageCount: $epPageCount, deleted: $deleted}';
  }
}

@Entity()
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

  @override
  String toString() {
    return 'BikaComicDownload{id: $id, comicId: $comicId, creatorId: $creatorId, creatorGender: $creatorGender, creatorName: $creatorName, creatorVerified: $creatorVerified, creatorExp: $creatorExp, creatorLevel: $creatorLevel, creatorCharacters: $creatorCharacters, creatorCharactersString: $creatorCharactersString, creatorRole: $creatorRole, creatorTitle: $creatorTitle, creatorAvatarOriginalName: $creatorAvatarOriginalName, creatorAvatarPath: $creatorAvatarPath, creatorAvatarFileServer: $creatorAvatarFileServer, creatorSlogan: $creatorSlogan, title: $title, description: $description, thumbOriginalName: $thumbOriginalName, thumbPath: $thumbPath, thumbFileServer: $thumbFileServer, author: $author, chineseTeam: $chineseTeam, categories: $categories, categoriesString: $categoriesString, tags: $tags, tagsString: $tagsString, pagesCount: $pagesCount, epsCount: $epsCount, finished: $finished, updatedAt: $updatedAt, createdAt: $createdAt, allowDownload: $allowDownload, allowComment: $allowComment, totalLikes: $totalLikes, totalViews: $totalViews, totalComments: $totalComments, viewsCount: $viewsCount, likesCount: $likesCount, commentsCount: $commentsCount, isFavourite: $isFavourite, isLiked: $isLiked, downloadTime: $downloadTime, epsTitle: $epsTitle, comicInfoAll: $comicInfoAll}';
  }
}
