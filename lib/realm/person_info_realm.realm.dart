// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person_info_realm.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// ignore_for_file: type=lint
class PersonInfoRealm extends _PersonInfoRealm
    with RealmEntity, RealmObjectBase, RealmObject {
  PersonInfoRealm(
    String id,
    DateTime birthday,
    String email,
    String gender,
    String name,
    String slogan,
    String title,
    bool verified,
    int exp,
    int level,
    DateTime createdAt,
    bool isPunched,
    String character, {
    Iterable<String> characters = const [],
    Avatar? avatar,
  }) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'birthday', birthday);
    RealmObjectBase.set(this, 'email', email);
    RealmObjectBase.set(this, 'gender', gender);
    RealmObjectBase.set(this, 'name', name);
    RealmObjectBase.set(this, 'slogan', slogan);
    RealmObjectBase.set(this, 'title', title);
    RealmObjectBase.set(this, 'verified', verified);
    RealmObjectBase.set(this, 'exp', exp);
    RealmObjectBase.set(this, 'level', level);
    RealmObjectBase.set<RealmList<String>>(
        this, 'characters', RealmList<String>(characters));
    RealmObjectBase.set(this, 'createdAt', createdAt);
    RealmObjectBase.set(this, 'avatar', avatar);
    RealmObjectBase.set(this, 'isPunched', isPunched);
    RealmObjectBase.set(this, 'character', character);
  }

  PersonInfoRealm._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  DateTime get birthday =>
      RealmObjectBase.get<DateTime>(this, 'birthday') as DateTime;
  @override
  set birthday(DateTime value) => RealmObjectBase.set(this, 'birthday', value);

  @override
  String get email => RealmObjectBase.get<String>(this, 'email') as String;
  @override
  set email(String value) => RealmObjectBase.set(this, 'email', value);

  @override
  String get gender => RealmObjectBase.get<String>(this, 'gender') as String;
  @override
  set gender(String value) => RealmObjectBase.set(this, 'gender', value);

  @override
  String get name => RealmObjectBase.get<String>(this, 'name') as String;
  @override
  set name(String value) => RealmObjectBase.set(this, 'name', value);

  @override
  String get slogan => RealmObjectBase.get<String>(this, 'slogan') as String;
  @override
  set slogan(String value) => RealmObjectBase.set(this, 'slogan', value);

  @override
  String get title => RealmObjectBase.get<String>(this, 'title') as String;
  @override
  set title(String value) => RealmObjectBase.set(this, 'title', value);

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
  RealmList<String> get characters =>
      RealmObjectBase.get<String>(this, 'characters') as RealmList<String>;
  @override
  set characters(covariant RealmList<String> value) =>
      throw RealmUnsupportedSetError();

  @override
  DateTime get createdAt =>
      RealmObjectBase.get<DateTime>(this, 'createdAt') as DateTime;
  @override
  set createdAt(DateTime value) =>
      RealmObjectBase.set(this, 'createdAt', value);

  @override
  Avatar? get avatar => RealmObjectBase.get<Avatar>(this, 'avatar') as Avatar?;
  @override
  set avatar(covariant Avatar? value) =>
      RealmObjectBase.set(this, 'avatar', value);

  @override
  bool get isPunched => RealmObjectBase.get<bool>(this, 'isPunched') as bool;
  @override
  set isPunched(bool value) => RealmObjectBase.set(this, 'isPunched', value);

  @override
  String get character =>
      RealmObjectBase.get<String>(this, 'character') as String;
  @override
  set character(String value) => RealmObjectBase.set(this, 'character', value);

  @override
  Stream<RealmObjectChanges<PersonInfoRealm>> get changes =>
      RealmObjectBase.getChanges<PersonInfoRealm>(this);

  @override
  Stream<RealmObjectChanges<PersonInfoRealm>> changesFor(
          [List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<PersonInfoRealm>(this, keyPaths);

  @override
  PersonInfoRealm freeze() =>
      RealmObjectBase.freezeObject<PersonInfoRealm>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'birthday': birthday.toEJson(),
      'email': email.toEJson(),
      'gender': gender.toEJson(),
      'name': name.toEJson(),
      'slogan': slogan.toEJson(),
      'title': title.toEJson(),
      'verified': verified.toEJson(),
      'exp': exp.toEJson(),
      'level': level.toEJson(),
      'characters': characters.toEJson(),
      'createdAt': createdAt.toEJson(),
      'avatar': avatar.toEJson(),
      'isPunched': isPunched.toEJson(),
      'character': character.toEJson(),
    };
  }

  static EJsonValue _toEJson(PersonInfoRealm value) => value.toEJson();
  static PersonInfoRealm _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'birthday': EJsonValue birthday,
        'email': EJsonValue email,
        'gender': EJsonValue gender,
        'name': EJsonValue name,
        'slogan': EJsonValue slogan,
        'title': EJsonValue title,
        'verified': EJsonValue verified,
        'exp': EJsonValue exp,
        'level': EJsonValue level,
        'createdAt': EJsonValue createdAt,
        'isPunched': EJsonValue isPunched,
        'character': EJsonValue character,
      } =>
        PersonInfoRealm(
          fromEJson(id),
          fromEJson(birthday),
          fromEJson(email),
          fromEJson(gender),
          fromEJson(name),
          fromEJson(slogan),
          fromEJson(title),
          fromEJson(verified),
          fromEJson(exp),
          fromEJson(level),
          fromEJson(createdAt),
          fromEJson(isPunched),
          fromEJson(character),
          characters: fromEJson(ejson['characters']),
          avatar: fromEJson(ejson['avatar']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(PersonInfoRealm._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
        ObjectType.realmObject, PersonInfoRealm, 'PersonInfoRealm', [
      SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
      SchemaProperty('birthday', RealmPropertyType.timestamp),
      SchemaProperty('email', RealmPropertyType.string),
      SchemaProperty('gender', RealmPropertyType.string),
      SchemaProperty('name', RealmPropertyType.string),
      SchemaProperty('slogan', RealmPropertyType.string),
      SchemaProperty('title', RealmPropertyType.string),
      SchemaProperty('verified', RealmPropertyType.bool),
      SchemaProperty('exp', RealmPropertyType.int),
      SchemaProperty('level', RealmPropertyType.int),
      SchemaProperty('characters', RealmPropertyType.string,
          collectionType: RealmCollectionType.list),
      SchemaProperty('createdAt', RealmPropertyType.timestamp),
      SchemaProperty('avatar', RealmPropertyType.object,
          optional: true, linkTarget: 'Avatar'),
      SchemaProperty('isPunched', RealmPropertyType.bool),
      SchemaProperty('character', RealmPropertyType.string),
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
