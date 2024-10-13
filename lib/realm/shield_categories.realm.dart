// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shield_categories.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// ignore_for_file: type=lint
class ShieldedCategories extends _ShieldedCategories
    with RealmEntity, RealmObjectBase, RealmObject {
  ShieldedCategories(
    String id, {
    Map<String, bool> map = const {},
  }) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set<RealmMap<bool>>(this, 'map', RealmMap<bool>(map));
  }

  ShieldedCategories._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  RealmMap<bool> get map =>
      RealmObjectBase.get<bool>(this, 'map') as RealmMap<bool>;
  @override
  set map(covariant RealmMap<bool> value) => throw RealmUnsupportedSetError();

  @override
  Stream<RealmObjectChanges<ShieldedCategories>> get changes =>
      RealmObjectBase.getChanges<ShieldedCategories>(this);

  @override
  Stream<RealmObjectChanges<ShieldedCategories>> changesFor(
          [List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<ShieldedCategories>(this, keyPaths);

  @override
  ShieldedCategories freeze() =>
      RealmObjectBase.freezeObject<ShieldedCategories>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'map': map.toEJson(),
    };
  }

  static EJsonValue _toEJson(ShieldedCategories value) => value.toEJson();
  static ShieldedCategories _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
      } =>
        ShieldedCategories(
          fromEJson(id),
          map: fromEJson(ejson['map']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(ShieldedCategories._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
        ObjectType.realmObject, ShieldedCategories, 'ShieldedCategories', [
      SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
      SchemaProperty('map', RealmPropertyType.bool,
          collectionType: RealmCollectionType.map),
    ]);
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
