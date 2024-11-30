import 'package:objectbox/objectbox.dart';

@Entity()
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
  DateTime updatedAt;
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
  DateTime history;
  int order;
  String epTitle;
  int epPageCount;

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
  });

  @override
  String toString() {
    return 'BikaComicHistory{id: $id, comicId: $comicId, creatorId: $creatorId, creatorGender: $creatorGender, creatorName: $creatorName, creatorVerified: $creatorVerified, creatorExp: $creatorExp, creatorLevel: $creatorLevel, creatorCharacters: $creatorCharacters, creatorCharactersString: $creatorCharactersString, creatorRole: $creatorRole, creatorTitle: $creatorTitle, creatorAvatarOriginalName: $creatorAvatarOriginalName, creatorAvatarPath: $creatorAvatarPath, creatorAvatarFileServer: $creatorAvatarFileServer, creatorSlogan: $creatorSlogan, title: $title, description: $description, thumbOriginalName: $thumbOriginalName, thumbPath: $thumbPath, thumbFileServer: $thumbFileServer, author: $author, chineseTeam: $chineseTeam, categories: $categories, categoriesString: $categoriesString, tags: $tags, tagsString: $tagsString, pagesCount: $pagesCount, epsCount: $epsCount, finished: $finished, updatedAt: $updatedAt, createdAt: $createdAt, allowDownload: $allowDownload, allowComment: $allowComment, totalLikes: $totalLikes, totalViews: $totalViews, totalComments: $totalComments, viewsCount: $viewsCount, likesCount: $likesCount, commentsCount: $commentsCount, isFavourite: $isFavourite, isLiked: $isLiked, history: $history, order: $order,epTitle: $epTitle, epPageCount: $epPageCount}';
  }
}
