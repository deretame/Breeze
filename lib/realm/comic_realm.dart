import 'package:realm/realm.dart';

part 'comic_realm.realm.dart';

@RealmModel()
class _ComicRealm {
  @PrimaryKey()
  late String id;

  late _Creator? creator;
  late String title;
  late String description;
  late _Thumb? thumb;
  late String author;
  late String chineseTeam;
  late List<String> categories;
  late List<String> tags;
  late int pagesCount;
  late int epsCount;
  late bool finished;
  late DateTime updatedAt;
  late DateTime createdAt;
  late bool allowDownload;
  late bool allowComment;
  late int totalLikes;
  late int totalViews;
  late int totalComments;
  late int viewsCount;
  late int likesCount;
  late int commentsCount;
  late bool isFavourite;
  late bool isLiked;
}

@RealmModel()
class _Creator {
  late String id;
  late String gender;
  late String name;
  late bool verified;
  late int exp;
  late int level;
  late String role;
  late List<String> characters;
  late String title;
  late _Avatar? avatar;
  late String slogan;
}

@RealmModel()
class _Avatar {
  late String originalName;
  late String path;
  late String fileServer;
}

@RealmModel()
class _Thumb {
  late String originalName;
  late String path;
  late String fileServer;
}
