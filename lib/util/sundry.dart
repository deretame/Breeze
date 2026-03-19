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
  final box = objectbox.pluginConfigBox;

  // 使用同步事务确保原子性
  return objectbox.store.runInTransaction(TxMode.write, () {
    var entity = box.query(PluginConfig_.name.equals(name)).build().findFirst();
    final parsedValue = _decodeMaybeJson(value);

    if (entity == null) {
      final data = key.isEmpty
          ? <String, dynamic>{}
          : <String, dynamic>{key: parsedValue};
      entity = PluginConfig(name: name, data: data);
    } else {
      final data = Map<String, dynamic>.from(
        entity.data ?? <String, dynamic>{},
      );
      if (key.isNotEmpty) {
        data[key] = parsedValue;
      }
      entity.data = data;
    }

    box.put(entity);
    return '{"ok":true}';
  });
}

String onLoadPluginConfig(String name, String key, String fallback) {
  final box = objectbox.pluginConfigBox;

  return objectbox.store.runInTransaction(TxMode.read, () {
    final entity = box
        .query(PluginConfig_.name.equals(name))
        .build()
        .findFirst();

    final data = Map<String, dynamic>.from(entity?.data ?? <String, dynamic>{});
    final value = key.isEmpty
        ? data
        : (data[key] ?? _decodeMaybeJson(fallback));

    return '{"ok":true,"value":${jsonEncode(value)}}';
  });
}

dynamic _decodeMaybeJson(String value) {
  final text = value.trim();
  if (text.isEmpty) {
    return value;
  }

  try {
    return jsonDecode(text);
  } catch (_) {
    return value;
  }
}

Future<void> registerPersistentCallbacks() async {
  await registerSavePluginConfig(
    dartCallback: (name, key, value) => onSavePluginConfig(name, key, value),
  );

  await registerLoadPluginConfig(
    dartCallback: (name, key, value) => onLoadPluginConfig(name, key, value),
  );
}

Future<void> savePluginConfigValue(
  String pluginName,
  String key,
  dynamic value,
) async {
  onSavePluginConfig(pluginName, key, jsonEncode(value));
}

void savePluginConfigValueSync(String pluginName, String key, dynamic value) {
  onSavePluginConfig(pluginName, key, jsonEncode(value));
}

T loadPluginConfigValue<T>(
  String pluginName,
  String key, {
  required T fallback,
}) {
  final raw = onLoadPluginConfig(pluginName, key, jsonEncode(fallback));
  final parsed = jsonDecode(raw) as Map<String, dynamic>;
  final value = parsed['value'];
  if (value is T) {
    return value;
  }
  return fallback;
}
