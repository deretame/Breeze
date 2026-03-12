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

String _flushTask(Store store, List<String> params) {
  final name = params[0];
  final key = params[1];
  final value = params[2];

  final box = store.box<FlushPersistentStore>();

  var entity = box
      .query(FlushPersistentStore_.name.equals(name))
      .build()
      .findFirst();

  if (entity == null) {
    var data = <String, dynamic>{key: value};
    entity = FlushPersistentStore(name: name, data: data);
    box.put(entity);
  } else {
    var data = entity.data ?? <String, dynamic>{};
    data[key] = value;
    entity.data = data;
    box.put(entity);
  }

  return '{"ok":true}';
}

String _loadTask(Store store, List<String> params) {
  final name = params[0];
  final key = params[1];
  final fallback = params[2];

  final box = store.box<FlushPersistentStore>();
  final entity = box
      .query(FlushPersistentStore_.name.equals(name))
      .build()
      .findFirst();

  final data = entity?.data ?? <String, dynamic>{};
  final value = data[key] ?? fallback;

  return '{"ok":true,"value":${jsonEncode(value)}}';
}

Future<String> onFlush(String name, String key, String value) {
  return objectbox.store.runInTransactionAsync(
    TxMode.write,
    _flushTask,
    [name, key, value], //
  );
}

Future<String> onLoad(String name, String key, String fallback) {
  return objectbox.store.runInTransactionAsync(
    TxMode.read,
    _loadTask,
    [name, key, fallback], //
  );
}

Future<void> registerPersistentCallbacks() async {
  await registerFlushPersistentStore(
    dartCallback: (name, key, value) => onFlush(name, key, value),
  );

  await registerLoadPersistentStore(
    dartCallback: (name, key, value) => onLoad(name, key, value),
  );
}
