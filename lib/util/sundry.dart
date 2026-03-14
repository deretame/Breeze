// 一些工具函数
import 'dart:convert';

import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/src/rust/api/qjs.dart';
import 'package:zephyr/src/rust/api/simple.dart';

// 用来简化调用，将繁体中文转换为简体中文
String t2s(String text) {
  return traditionalToSimplified(text: text);
}

String onSavePluginConfig(String name, String key, String value) {
  final box = objectbox.flushPersistentBox;

  // 使用同步事务确保原子性
  return objectbox.store.runInTransaction(TxMode.write, () {
    var entity = box
        .query(FlushPersistentStore_.name.equals(name))
        .build()
        .findFirst();

    if (entity == null) {
      var data = <String, dynamic>{key: value};
      entity = FlushPersistentStore(name: name, data: data);
    } else {
      var data = entity.data ?? <String, dynamic>{};
      data[key] = value;
      entity.data = data;
    }

    box.put(entity);
    return '{"ok":true}';
  });
}

String onLoadPluginConfig(String name, String key, String fallback) {
  final box = objectbox.flushPersistentBox;

  return objectbox.store.runInTransaction(TxMode.read, () {
    final entity = box
        .query(FlushPersistentStore_.name.equals(name))
        .build()
        .findFirst();

    final data = entity?.data ?? <String, dynamic>{};
    final value = data[key] ?? fallback;

    return '{"ok":true,"value":${value.toJson()}}';
  });
}

Future<void> registerPersistentCallbacks() async {
  await registerSavePluginConfig(
    dartCallback: (name, key, value) => onSavePluginConfig(name, key, value),
  );

  await registerLoadPluginConfig(
    dartCallback: (name, key, value) => onLoadPluginConfig(name, key, value),
  );
}

extension MapConverterX on Map {
  String toJson() => jsonEncode(this);
}

extension MapListConverterX on List<Map> {
  String toJson() => jsonEncode(this);
}
