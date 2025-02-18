class ComicAllInfoJsonNoFreeze {
  Comic comic;
  Eps eps;

  ComicAllInfoJsonNoFreeze({required this.comic, required this.eps});

  // 空构造函数
  ComicAllInfoJsonNoFreeze.empty() : comic = Comic.empty(), eps = Eps(docs: []);

  Map<String, dynamic> toJson() => {
    'comic': comic.toJson(),
    'eps': eps.toJson(),
  };

  Comic get comicInfo => comic;

  set comicInfo(Comic comic) => this.comic = comic;

  Eps get episodes => eps;

  set episodes(Eps eps) => this.eps = eps;
}

class Comic {
  String id;
  Creator creator;
  String title;
  String description;
  Thumb thumb;
  String author;
  String chineseTeam;
  List<String> categories;
  List<String> tags;
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

  Comic({
    required this.id,
    required this.creator,
    required this.title,
    required this.description,
    required this.thumb,
    required this.author,
    required this.chineseTeam,
    required this.categories,
    required this.tags,
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
  });

  // 空构造函数
  Comic.empty()
    : id = '',
      creator = Creator.empty(),
      title = '',
      description = '',
      thumb = Thumb.empty(),
      author = '',
      chineseTeam = '',
      categories = [],
      tags = [],
      pagesCount = 0,
      epsCount = 0,
      finished = false,
      updatedAt = DateTime.now().toUtc(),
      createdAt = DateTime.now().toUtc(),
      allowDownload = false,
      allowComment = false,
      totalLikes = 0,
      totalViews = 0,
      totalComments = 0,
      viewsCount = 0,
      likesCount = 0,
      commentsCount = 0,
      isFavourite = false,
      isLiked = false;

  Map<String, dynamic> toJson() => {
    '_id': id,
    '_creator': creator.toJson(),
    'title': title,
    'description': description,
    'thumb': thumb.toJson(),
    'author': author,
    'chineseTeam': chineseTeam,
    'categories': categories,
    'tags': tags,
    'pagesCount': pagesCount,
    'epsCount': epsCount,
    'finished': finished,
    'updated_at': updatedAt.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
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
  };

  String get comicId => id;

  set comicId(String id) => this.id = id;

  String get comicTitle => title;

  set comicTitle(String title) => this.title = title;

  String get comicDescription => description;

  set comicDescription(String description) => this.description = description;

  Thumb get comicThumb => thumb;

  set comicThumb(Thumb thumb) => this.thumb = thumb;

  String get comicAuthor => author;

  set comicAuthor(String author) => this.author = author;

  String get comicChineseTeam => chineseTeam;

  set comicChineseTeam(String chineseTeam) => this.chineseTeam = chineseTeam;

  List<String> get comicCategories => categories;

  set comicCategories(List<String> categories) => this.categories = categories;

  List<String> get comicTags => tags;

  set comicTags(List<String> tags) => this.tags = tags;

  int get comicPagesCount => pagesCount;

  set comicPagesCount(int pagesCount) => this.pagesCount = pagesCount;

  int get comicEpsCount => epsCount;

  set comicEpsCount(int epsCount) => this.epsCount = epsCount;

  bool get comicFinished => finished;

  set comicFinished(bool finished) => this.finished = finished;

  DateTime get comicUpdatedAt => updatedAt;

  set comicUpdatedAt(DateTime updatedAt) => this.updatedAt = updatedAt;

  DateTime get comicCreatedAt => createdAt;

  set comicCreatedAt(DateTime createdAt) => this.createdAt = createdAt;

  bool get comicAllowDownload => allowDownload;

  set comicAllowDownload(bool allowDownload) =>
      this.allowDownload = allowDownload;

  bool get comicAllowComment => allowComment;

  set comicAllowComment(bool allowComment) => this.allowComment = allowComment;

  int get comicTotalLikes => totalLikes;

  set comicTotalLikes(int totalLikes) => this.totalLikes = totalLikes;

  int get comicTotalViews => totalViews;

  set comicTotalViews(int totalViews) => this.totalViews = totalViews;

  int get comicTotalComments => totalComments;

  set comicTotalComments(int totalComments) =>
      this.totalComments = totalComments;

  int get comicViewsCount => viewsCount;

  set comicViewsCount(int viewsCount) => this.viewsCount = viewsCount;

  int get comicLikesCount => likesCount;

  set comicLikesCount(int likesCount) => this.likesCount = likesCount;

  int get comicCommentsCount => commentsCount;

  set comicCommentsCount(int commentsCount) =>
      this.commentsCount = commentsCount;

  bool get comicIsFavourite => isFavourite;

  set comicIsFavourite(bool isFavourite) => this.isFavourite = isFavourite;

  bool get comicIsLiked => isLiked;

  set comicIsLiked(bool isLiked) => this.isLiked = isLiked;
}

class Creator {
  String id;
  String gender;
  String name;
  bool verified;
  int exp;
  int level;
  String role;
  Thumb avatar;
  List<String> characters;
  String title;
  String slogan;

  Creator({
    required this.id,
    required this.gender,
    required this.name,
    required this.verified,
    required this.exp,
    required this.level,
    required this.role,
    required this.avatar,
    required this.characters,
    required this.title,
    required this.slogan,
  });

  // 空构造函数
  Creator.empty()
    : id = '',
      gender = '',
      name = '',
      verified = false,
      exp = 0,
      level = 0,
      role = '',
      avatar = Thumb.empty(),
      characters = [],
      title = '',
      slogan = '';

  Map<String, dynamic> toJson() => {
    '_id': id,
    'gender': gender,
    'name': name,
    'verified': verified,
    'exp': exp,
    'level': level,
    'role': role,
    'avatar': avatar.toJson(),
    'characters': characters,
    'title': title,
    'slogan': slogan,
  };

  String get creatorId => id;

  set creatorId(String id) => this.id = id;

  String get creatorGender => gender;

  set creatorGender(String gender) => this.gender = gender;

  String get creatorName => name;

  set creatorName(String name) => this.name = name;

  bool get creatorVerified => verified;

  set creatorVerified(bool verified) => this.verified = verified;

  int get creatorExp => exp;

  set creatorExp(int exp) => this.exp = exp;

  int get creatorLevel => level;

  set creatorLevel(int level) => this.level = level;

  String get creatorRole => role;

  set creatorRole(String role) => this.role = role;

  Thumb get creatorAvatar => avatar;

  set creatorAvatar(Thumb avatar) => this.avatar = avatar;

  List<String> get creatorCharacters => characters;

  set creatorCharacters(List<String> characters) =>
      this.characters = characters;

  String get creatorTitle => title;

  set creatorTitle(String title) => this.title = title;

  String get creatorSlogan => slogan;

  set creatorSlogan(String slogan) => this.slogan = slogan;
}

class Thumb {
  String fileServer;
  String path;
  String originalName;

  Thumb({
    required this.fileServer,
    required this.path,
    required this.originalName,
  });

  // 空构造函数
  Thumb.empty() : fileServer = '', path = '', originalName = '';

  Map<String, dynamic> toJson() => {
    'fileServer': fileServer,
    'path': path,
    'originalName': originalName,
  };

  String get thumbFileServer => fileServer;

  set thumbFileServer(String fileServer) => this.fileServer = fileServer;

  String get thumbPath => path;

  set thumbPath(String path) => this.path = path;

  String get thumbOriginalName => originalName;

  set thumbOriginalName(String originalName) =>
      this.originalName = originalName;
}

class Eps {
  List<EpsDoc> docs;

  Eps({required this.docs});

  // 空构造函数
  Eps.empty() : docs = [];

  Map<String, dynamic> toJson() => {
    'docs': docs.map((doc) => doc.toJson()).toList(),
  };

  List<EpsDoc> get episodes => docs;

  set episodes(List<EpsDoc> docs) => this.docs = docs;

  void add(EpsDoc epsDoc) {
    docs.add(epsDoc);
  }

  int get length => docs.length;

  EpsDoc operator [](int index) => docs[index];
}

class EpsDoc {
  String id;
  String title;
  int order;
  DateTime updatedAt;
  String docId;
  Pages pages;

  EpsDoc({
    required this.id,
    required this.title,
    required this.order,
    required this.updatedAt,
    required this.docId,
    required this.pages,
  });

  // 空构造函数
  EpsDoc.empty()
    : id = '',
      title = '',
      order = 0,
      updatedAt = DateTime.now(),
      docId = '',
      pages = Pages(docs: []);

  Map<String, dynamic> toJson() => {
    '_id': id,
    'title': title,
    'order': order,
    'updated_at': updatedAt.toIso8601String(),
    'id': docId,
    'pages': pages.toJson(),
  };

  String get episodeId => id;

  set episodeId(String id) => this.id = id;

  String get episodeTitle => title;

  set episodeTitle(String title) => this.title = title;

  int get episodeOrder => order;

  set episodeOrder(int order) => this.order = order;

  DateTime get episodeUpdatedAt => updatedAt;

  set episodeUpdatedAt(DateTime updatedAt) => this.updatedAt = updatedAt;

  String get episodeDocId => docId;

  set episodeDocId(String docId) => this.docId = docId;

  Pages get episodePages => pages;

  set episodePages(Pages pages) => this.pages = pages;
}

class Pages {
  List<PagesDoc> docs;

  Pages({required this.docs});

  // 空构造函数
  Pages.empty() : docs = [];

  Map<String, dynamic> toJson() => {
    'docs': docs.map((doc) => doc.toJson()).toList(),
  };

  List<PagesDoc> get pages => docs;

  set pages(List<PagesDoc> docs) => this.docs = docs;

  void add(PagesDoc pagesDoc) {
    docs.add(pagesDoc);
  }
}

class PagesDoc {
  String id;
  Thumb media;
  String docId;

  PagesDoc({required this.id, required this.media, required this.docId});

  // 空构造函数
  PagesDoc.empty() : id = '', media = Thumb.empty(), docId = '';

  Map<String, dynamic> toJson() => {
    '_id': id,
    'media': media.toJson(),
    'id': docId,
  };

  String get pageId => id;

  set pageId(String id) => this.id = id;

  Thumb get pageMedia => media;

  set pageMedia(Thumb media) => this.media = media;

  String get pageDocId => docId;

  set pageDocId(String docId) => this.docId = docId;
}
