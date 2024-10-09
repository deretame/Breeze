// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comic_realm.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// ignore_for_file: type=lint
class ComicRealm extends _ComicRealm
    with RealmEntity, RealmObjectBase, RealmObject {
  ComicRealm(
    String id,
    String title,
    String description,
    String author,
    String chineseTeam,
    int pagesCount,
    int epsCount,
    bool finished,
    DateTime updatedAt,
    DateTime createdAt,
    bool allowDownload,
    bool allowComment,
    int totalLikes,
    int totalViews,
    int totalComments,
    int viewsCount,
    int likesCount,
    int commentsCount,
    bool isFavourite,
    bool isLiked, {
    Creator? creator,
    Thumb? thumb,
    Iterable<String> categories = const [],
    Iterable<String> tags = const [],
  }) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'creator', creator);
    RealmObjectBase.set(this, 'title', title);
    RealmObjectBase.set(this, 'description', description);
    RealmObjectBase.set(this, 'thumb', thumb);
    RealmObjectBase.set(this, 'author', author);
    RealmObjectBase.set(this, 'chineseTeam', chineseTeam);
    RealmObjectBase.set<RealmList<String>>(
        this, 'categories', RealmList<String>(categories));
    RealmObjectBase.set<RealmList<String>>(
        this, 'tags', RealmList<String>(tags));
    RealmObjectBase.set(this, 'pagesCount', pagesCount);
    RealmObjectBase.set(this, 'epsCount', epsCount);
    RealmObjectBase.set(this, 'finished', finished);
    RealmObjectBase.set(this, 'updatedAt', updatedAt);
    RealmObjectBase.set(this, 'createdAt', createdAt);
    RealmObjectBase.set(this, 'allowDownload', allowDownload);
    RealmObjectBase.set(this, 'allowComment', allowComment);
    RealmObjectBase.set(this, 'totalLikes', totalLikes);
    RealmObjectBase.set(this, 'totalViews', totalViews);
    RealmObjectBase.set(this, 'totalComments', totalComments);
    RealmObjectBase.set(this, 'viewsCount', viewsCount);
    RealmObjectBase.set(this, 'likesCount', likesCount);
    RealmObjectBase.set(this, 'commentsCount', commentsCount);
    RealmObjectBase.set(this, 'isFavourite', isFavourite);
    RealmObjectBase.set(this, 'isLiked', isLiked);
  }

  ComicRealm._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  Creator? get creator =>
      RealmObjectBase.get<Creator>(this, 'creator') as Creator?;
  @override
  set creator(covariant Creator? value) =>
      RealmObjectBase.set(this, 'creator', value);

  @override
  String get title => RealmObjectBase.get<String>(this, 'title') as String;
  @override
  set title(String value) => RealmObjectBase.set(this, 'title', value);

  @override
  String get description =>
      RealmObjectBase.get<String>(this, 'description') as String;
  @override
  set description(String value) =>
      RealmObjectBase.set(this, 'description', value);

  @override
  Thumb? get thumb => RealmObjectBase.get<Thumb>(this, 'thumb') as Thumb?;
  @override
  set thumb(covariant Thumb? value) =>
      RealmObjectBase.set(this, 'thumb', value);

  @override
  String get author => RealmObjectBase.get<String>(this, 'author') as String;
  @override
  set author(String value) => RealmObjectBase.set(this, 'author', value);

  @override
  String get chineseTeam =>
      RealmObjectBase.get<String>(this, 'chineseTeam') as String;
  @override
  set chineseTeam(String value) =>
      RealmObjectBase.set(this, 'chineseTeam', value);

  @override
  RealmList<String> get categories =>
      RealmObjectBase.get<String>(this, 'categories') as RealmList<String>;
  @override
  set categories(covariant RealmList<String> value) =>
      throw RealmUnsupportedSetError();

  @override
  RealmList<String> get tags =>
      RealmObjectBase.get<String>(this, 'tags') as RealmList<String>;
  @override
  set tags(covariant RealmList<String> value) =>
      throw RealmUnsupportedSetError();

  @override
  int get pagesCount => RealmObjectBase.get<int>(this, 'pagesCount') as int;
  @override
  set pagesCount(int value) => RealmObjectBase.set(this, 'pagesCount', value);

  @override
  int get epsCount => RealmObjectBase.get<int>(this, 'epsCount') as int;
  @override
  set epsCount(int value) => RealmObjectBase.set(this, 'epsCount', value);

  @override
  bool get finished => RealmObjectBase.get<bool>(this, 'finished') as bool;
  @override
  set finished(bool value) => RealmObjectBase.set(this, 'finished', value);

  @override
  DateTime get updatedAt =>
      RealmObjectBase.get<DateTime>(this, 'updatedAt') as DateTime;
  @override
  set updatedAt(DateTime value) =>
      RealmObjectBase.set(this, 'updatedAt', value);

  @override
  DateTime get createdAt =>
      RealmObjectBase.get<DateTime>(this, 'createdAt') as DateTime;
  @override
  set createdAt(DateTime value) =>
      RealmObjectBase.set(this, 'createdAt', value);

  @override
  bool get allowDownload =>
      RealmObjectBase.get<bool>(this, 'allowDownload') as bool;
  @override
  set allowDownload(bool value) =>
      RealmObjectBase.set(this, 'allowDownload', value);

  @override
  bool get allowComment =>
      RealmObjectBase.get<bool>(this, 'allowComment') as bool;
  @override
  set allowComment(bool value) =>
      RealmObjectBase.set(this, 'allowComment', value);

  @override
  int get totalLikes => RealmObjectBase.get<int>(this, 'totalLikes') as int;
  @override
  set totalLikes(int value) => RealmObjectBase.set(this, 'totalLikes', value);

  @override
  int get totalViews => RealmObjectBase.get<int>(this, 'totalViews') as int;
  @override
  set totalViews(int value) => RealmObjectBase.set(this, 'totalViews', value);

  @override
  int get totalComments =>
      RealmObjectBase.get<int>(this, 'totalComments') as int;
  @override
  set totalComments(int value) =>
      RealmObjectBase.set(this, 'totalComments', value);

  @override
  int get viewsCount => RealmObjectBase.get<int>(this, 'viewsCount') as int;
  @override
  set viewsCount(int value) => RealmObjectBase.set(this, 'viewsCount', value);

  @override
  int get likesCount => RealmObjectBase.get<int>(this, 'likesCount') as int;
  @override
  set likesCount(int value) => RealmObjectBase.set(this, 'likesCount', value);

  @override
  int get commentsCount =>
      RealmObjectBase.get<int>(this, 'commentsCount') as int;
  @override
  set commentsCount(int value) =>
      RealmObjectBase.set(this, 'commentsCount', value);

  @override
  bool get isFavourite =>
      RealmObjectBase.get<bool>(this, 'isFavourite') as bool;
  @override
  set isFavourite(bool value) =>
      RealmObjectBase.set(this, 'isFavourite', value);

  @override
  bool get isLiked => RealmObjectBase.get<bool>(this, 'isLiked') as bool;
  @override
  set isLiked(bool value) => RealmObjectBase.set(this, 'isLiked', value);

  @override
  Stream<RealmObjectChanges<ComicRealm>> get changes =>
      RealmObjectBase.getChanges<ComicRealm>(this);

  @override
  Stream<RealmObjectChanges<ComicRealm>> changesFor([List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<ComicRealm>(this, keyPaths);

  @override
  ComicRealm freeze() => RealmObjectBase.freezeObject<ComicRealm>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'creator': creator.toEJson(),
      'title': title.toEJson(),
      'description': description.toEJson(),
      'thumb': thumb.toEJson(),
      'author': author.toEJson(),
      'chineseTeam': chineseTeam.toEJson(),
      'categories': categories.toEJson(),
      'tags': tags.toEJson(),
      'pagesCount': pagesCount.toEJson(),
      'epsCount': epsCount.toEJson(),
      'finished': finished.toEJson(),
      'updatedAt': updatedAt.toEJson(),
      'createdAt': createdAt.toEJson(),
      'allowDownload': allowDownload.toEJson(),
      'allowComment': allowComment.toEJson(),
      'totalLikes': totalLikes.toEJson(),
      'totalViews': totalViews.toEJson(),
      'totalComments': totalComments.toEJson(),
      'viewsCount': viewsCount.toEJson(),
      'likesCount': likesCount.toEJson(),
      'commentsCount': commentsCount.toEJson(),
      'isFavourite': isFavourite.toEJson(),
      'isLiked': isLiked.toEJson(),
    };
  }

  static EJsonValue _toEJson(ComicRealm value) => value.toEJson();
  static ComicRealm _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'title': EJsonValue title,
        'description': EJsonValue description,
        'author': EJsonValue author,
        'chineseTeam': EJsonValue chineseTeam,
        'pagesCount': EJsonValue pagesCount,
        'epsCount': EJsonValue epsCount,
        'finished': EJsonValue finished,
        'updatedAt': EJsonValue updatedAt,
        'createdAt': EJsonValue createdAt,
        'allowDownload': EJsonValue allowDownload,
        'allowComment': EJsonValue allowComment,
        'totalLikes': EJsonValue totalLikes,
        'totalViews': EJsonValue totalViews,
        'totalComments': EJsonValue totalComments,
        'viewsCount': EJsonValue viewsCount,
        'likesCount': EJsonValue likesCount,
        'commentsCount': EJsonValue commentsCount,
        'isFavourite': EJsonValue isFavourite,
        'isLiked': EJsonValue isLiked,
      } =>
        ComicRealm(
          fromEJson(id),
          fromEJson(title),
          fromEJson(description),
          fromEJson(author),
          fromEJson(chineseTeam),
          fromEJson(pagesCount),
          fromEJson(epsCount),
          fromEJson(finished),
          fromEJson(updatedAt),
          fromEJson(createdAt),
          fromEJson(allowDownload),
          fromEJson(allowComment),
          fromEJson(totalLikes),
          fromEJson(totalViews),
          fromEJson(totalComments),
          fromEJson(viewsCount),
          fromEJson(likesCount),
          fromEJson(commentsCount),
          fromEJson(isFavourite),
          fromEJson(isLiked),
          creator: fromEJson(ejson['creator']),
          thumb: fromEJson(ejson['thumb']),
          categories: fromEJson(ejson['categories']),
          tags: fromEJson(ejson['tags']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(ComicRealm._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
        ObjectType.realmObject, ComicRealm, 'ComicRealm', [
      SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
      SchemaProperty('creator', RealmPropertyType.object,
          optional: true, linkTarget: 'Creator'),
      SchemaProperty('title', RealmPropertyType.string),
      SchemaProperty('description', RealmPropertyType.string),
      SchemaProperty('thumb', RealmPropertyType.object,
          optional: true, linkTarget: 'Thumb'),
      SchemaProperty('author', RealmPropertyType.string),
      SchemaProperty('chineseTeam', RealmPropertyType.string),
      SchemaProperty('categories', RealmPropertyType.string,
          collectionType: RealmCollectionType.list),
      SchemaProperty('tags', RealmPropertyType.string,
          collectionType: RealmCollectionType.list),
      SchemaProperty('pagesCount', RealmPropertyType.int),
      SchemaProperty('epsCount', RealmPropertyType.int),
      SchemaProperty('finished', RealmPropertyType.bool),
      SchemaProperty('updatedAt', RealmPropertyType.timestamp),
      SchemaProperty('createdAt', RealmPropertyType.timestamp),
      SchemaProperty('allowDownload', RealmPropertyType.bool),
      SchemaProperty('allowComment', RealmPropertyType.bool),
      SchemaProperty('totalLikes', RealmPropertyType.int),
      SchemaProperty('totalViews', RealmPropertyType.int),
      SchemaProperty('totalComments', RealmPropertyType.int),
      SchemaProperty('viewsCount', RealmPropertyType.int),
      SchemaProperty('likesCount', RealmPropertyType.int),
      SchemaProperty('commentsCount', RealmPropertyType.int),
      SchemaProperty('isFavourite', RealmPropertyType.bool),
      SchemaProperty('isLiked', RealmPropertyType.bool),
    ]);
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}

class Creator extends _Creator with RealmEntity, RealmObjectBase, RealmObject {
  Creator(
    String id,
    String gender,
    String name,
    bool verified,
    int exp,
    int level,
    String role,
    String title,
    String slogan, {
    Iterable<String> characters = const [],
    Avatar? avatar,
  }) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'gender', gender);
    RealmObjectBase.set(this, 'name', name);
    RealmObjectBase.set(this, 'verified', verified);
    RealmObjectBase.set(this, 'exp', exp);
    RealmObjectBase.set(this, 'level', level);
    RealmObjectBase.set(this, 'role', role);
    RealmObjectBase.set<RealmList<String>>(
        this, 'characters', RealmList<String>(characters));
    RealmObjectBase.set(this, 'title', title);
    RealmObjectBase.set(this, 'avatar', avatar);
    RealmObjectBase.set(this, 'slogan', slogan);
  }

  Creator._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get gender => RealmObjectBase.get<String>(this, 'gender') as String;
  @override
  set gender(String value) => RealmObjectBase.set(this, 'gender', value);

  @override
  String get name => RealmObjectBase.get<String>(this, 'name') as String;
  @override
  set name(String value) => RealmObjectBase.set(this, 'name', value);

  @override
  bool get verified => RealmObjectBase.get<bool>(this, 'verified') as bool;
  @override
  set verified(bool value) => RealmObjectBase.set(this, 'verified', value);

  @override
  int get exp => RealmObjectBase.get<int>(this, 'exp') as int;
  @override
  set exp(int value) => RealmObjectBase.set(this, 'exp', value);

  @override
  int get level => RealmObjectBase.get<int>(this, 'level') as int;
  @override
  set level(int value) => RealmObjectBase.set(this, 'level', value);

  @override
  String get role => RealmObjectBase.get<String>(this, 'role') as String;
  @override
  set role(String value) => RealmObjectBase.set(this, 'role', value);

  @override
  RealmList<String> get characters =>
      RealmObjectBase.get<String>(this, 'characters') as RealmList<String>;
  @override
  set characters(covariant RealmList<String> value) =>
      throw RealmUnsupportedSetError();

  @override
  String get title => RealmObjectBase.get<String>(this, 'title') as String;
  @override
  set title(String value) => RealmObjectBase.set(this, 'title', value);

  @override
  Avatar? get avatar => RealmObjectBase.get<Avatar>(this, 'avatar') as Avatar?;
  @override
  set avatar(covariant Avatar? value) =>
      RealmObjectBase.set(this, 'avatar', value);

  @override
  String get slogan => RealmObjectBase.get<String>(this, 'slogan') as String;
  @override
  set slogan(String value) => RealmObjectBase.set(this, 'slogan', value);

  @override
  Stream<RealmObjectChanges<Creator>> get changes =>
      RealmObjectBase.getChanges<Creator>(this);

  @override
  Stream<RealmObjectChanges<Creator>> changesFor([List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<Creator>(this, keyPaths);

  @override
  Creator freeze() => RealmObjectBase.freezeObject<Creator>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'gender': gender.toEJson(),
      'name': name.toEJson(),
      'verified': verified.toEJson(),
      'exp': exp.toEJson(),
      'level': level.toEJson(),
      'role': role.toEJson(),
      'characters': characters.toEJson(),
      'title': title.toEJson(),
      'avatar': avatar.toEJson(),
      'slogan': slogan.toEJson(),
    };
  }

  static EJsonValue _toEJson(Creator value) => value.toEJson();
  static Creator _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'gender': EJsonValue gender,
        'name': EJsonValue name,
        'verified': EJsonValue verified,
        'exp': EJsonValue exp,
        'level': EJsonValue level,
        'role': EJsonValue role,
        'title': EJsonValue title,
        'slogan': EJsonValue slogan,
      } =>
        Creator(
          fromEJson(id),
          fromEJson(gender),
          fromEJson(name),
          fromEJson(verified),
          fromEJson(exp),
          fromEJson(level),
          fromEJson(role),
          fromEJson(title),
          fromEJson(slogan),
          characters: fromEJson(ejson['characters']),
          avatar: fromEJson(ejson['avatar']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(Creator._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(ObjectType.realmObject, Creator, 'Creator', [
      SchemaProperty('id', RealmPropertyType.string),
      SchemaProperty('gender', RealmPropertyType.string),
      SchemaProperty('name', RealmPropertyType.string),
      SchemaProperty('verified', RealmPropertyType.bool),
      SchemaProperty('exp', RealmPropertyType.int),
      SchemaProperty('level', RealmPropertyType.int),
      SchemaProperty('role', RealmPropertyType.string),
      SchemaProperty('characters', RealmPropertyType.string,
          collectionType: RealmCollectionType.list),
      SchemaProperty('title', RealmPropertyType.string),
      SchemaProperty('avatar', RealmPropertyType.object,
          optional: true, linkTarget: 'Avatar'),
      SchemaProperty('slogan', RealmPropertyType.string),
    ]);
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}

class Avatar extends _Avatar with RealmEntity, RealmObjectBase, RealmObject {
  Avatar(
    String originalName,
    String path,
    String fileServer,
  ) {
    RealmObjectBase.set(this, 'originalName', originalName);
    RealmObjectBase.set(this, 'path', path);
    RealmObjectBase.set(this, 'fileServer', fileServer);
  }

  Avatar._();

  @override
  String get originalName =>
      RealmObjectBase.get<String>(this, 'originalName') as String;
  @override
  set originalName(String value) =>
      RealmObjectBase.set(this, 'originalName', value);

  @override
  String get path => RealmObjectBase.get<String>(this, 'path') as String;
  @override
  set path(String value) => RealmObjectBase.set(this, 'path', value);

  @override
  String get fileServer =>
      RealmObjectBase.get<String>(this, 'fileServer') as String;
  @override
  set fileServer(String value) =>
      RealmObjectBase.set(this, 'fileServer', value);

  @override
  Stream<RealmObjectChanges<Avatar>> get changes =>
      RealmObjectBase.getChanges<Avatar>(this);

  @override
  Stream<RealmObjectChanges<Avatar>> changesFor([List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<Avatar>(this, keyPaths);

  @override
  Avatar freeze() => RealmObjectBase.freezeObject<Avatar>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'originalName': originalName.toEJson(),
      'path': path.toEJson(),
      'fileServer': fileServer.toEJson(),
    };
  }

  static EJsonValue _toEJson(Avatar value) => value.toEJson();
  static Avatar _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'originalName': EJsonValue originalName,
        'path': EJsonValue path,
        'fileServer': EJsonValue fileServer,
      } =>
        Avatar(
          fromEJson(originalName),
          fromEJson(path),
          fromEJson(fileServer),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(Avatar._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(ObjectType.realmObject, Avatar, 'Avatar', [
      SchemaProperty('originalName', RealmPropertyType.string),
      SchemaProperty('path', RealmPropertyType.string),
      SchemaProperty('fileServer', RealmPropertyType.string),
    ]);
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}

class Thumb extends _Thumb with RealmEntity, RealmObjectBase, RealmObject {
  Thumb(
    String originalName,
    String path,
    String fileServer,
  ) {
    RealmObjectBase.set(this, 'originalName', originalName);
    RealmObjectBase.set(this, 'path', path);
    RealmObjectBase.set(this, 'fileServer', fileServer);
  }

  Thumb._();

  @override
  String get originalName =>
      RealmObjectBase.get<String>(this, 'originalName') as String;
  @override
  set originalName(String value) =>
      RealmObjectBase.set(this, 'originalName', value);

  @override
  String get path => RealmObjectBase.get<String>(this, 'path') as String;
  @override
  set path(String value) => RealmObjectBase.set(this, 'path', value);

  @override
  String get fileServer =>
      RealmObjectBase.get<String>(this, 'fileServer') as String;
  @override
  set fileServer(String value) =>
      RealmObjectBase.set(this, 'fileServer', value);

  @override
  Stream<RealmObjectChanges<Thumb>> get changes =>
      RealmObjectBase.getChanges<Thumb>(this);

  @override
  Stream<RealmObjectChanges<Thumb>> changesFor([List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<Thumb>(this, keyPaths);

  @override
  Thumb freeze() => RealmObjectBase.freezeObject<Thumb>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'originalName': originalName.toEJson(),
      'path': path.toEJson(),
      'fileServer': fileServer.toEJson(),
    };
  }

  static EJsonValue _toEJson(Thumb value) => value.toEJson();
  static Thumb _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'originalName': EJsonValue originalName,
        'path': EJsonValue path,
        'fileServer': EJsonValue fileServer,
      } =>
        Thumb(
          fromEJson(originalName),
          fromEJson(path),
          fromEJson(fileServer),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(Thumb._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(ObjectType.realmObject, Thumb, 'Thumb', [
      SchemaProperty('originalName', RealmPropertyType.string),
      SchemaProperty('path', RealmPropertyType.string),
      SchemaProperty('fileServer', RealmPropertyType.string),
    ]);
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
