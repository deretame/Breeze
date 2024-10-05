import 'package:realm/realm.dart';

part 'comic_realm.realm.dart';

@RealmModel()
class _ComicRealm {
  @PrimaryKey()
  late final String id;

  late final _Creator? creator;
  late final String title;
  late final String description;
  late final _Thumb? thumb;
  late final String author;
  late final String chineseTeam;
  late final List<String> categories;
  late final List<String> tags;
  late final int pagesCount;
  late final int epsCount;
  late final bool finished;
  late final DateTime updatedAt;
  late final DateTime createdAt;
  late final bool allowDownload;
  late final bool allowComment;
  late final int totalLikes;
  late final int totalViews;
  late final int totalComments;
  late final int viewsCount;
  late final int likesCount;
  late final int commentsCount;
  late final bool isFavourite;
  late final bool isLiked;
}

@RealmModel()
class _Creator {
  @PrimaryKey()
  late final String id;

  late final String gender;
  late final String name;
  late final bool verified;
  late final int exp;
  late final int level;
  late final String role;
  late final List<String> characters;
  late final String title;
  late final _Avatar? avatar;
  late final String slogan;
}

@RealmModel()
class _Avatar {
  late final String originalName;
  late final String path;
  late final String fileServer;
}

@RealmModel()
class _Thumb {
  late final String originalName;
  late final String path;
  late final String fileServer;
}
