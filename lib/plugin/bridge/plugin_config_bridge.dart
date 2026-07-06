import 'dart:async';
import 'dart:convert';

import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/src/rust/api/qjs.dart';

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
      entity = PluginConfig(name: name, config: jsonEncode(data));
    } else {
      final data = _decodeObjectMap(entity.config);
      if (key.isNotEmpty) {
        data[key] = parsedValue;
      }
      entity.config = jsonEncode(data);
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

    final data = _decodeObjectMap(entity?.config ?? '');
    final value = key.isEmpty
        ? data
        : (data[key] ?? _decodeMaybeJson(fallback));

    return '{"ok":true,"value":${jsonEncode(value)}}';
  });
}

Map<String, dynamic> _decodeObjectMap(String raw) {
  final text = raw.trim();
  if (text.isEmpty) {
    return <String, dynamic>{};
  }
  try {
    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
  } catch (_) {}
  return <String, dynamic>{};
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

void _register(
  String functionName,
  FutureOr<String> Function(String) dartCallback,
) {
  registerFunction(functionName: functionName, dartCallback: dartCallback);
}

Future<void> registerPersistentCallbacks() async {
  _register('save_plugin_config', (String data) async {
    final args = jsonDecode(data) as List<dynamic>;
    final runtime = args[0] as String;
    final pluginName = args[1] as String;
    final value = args[2] as String;
    return onSavePluginConfig(runtime, pluginName, value);
  });

  _register('load_plugin_config', (String data) async {
    final args = jsonDecode(data) as List<dynamic>;
    final runtime = args[0] as String;
    final pluginName = args[1] as String;
    final fallback = args[2] as String;
    return onLoadPluginConfig(runtime, pluginName, fallback);
  });
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
