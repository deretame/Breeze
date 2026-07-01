// 一些工具函数
import 'dart:convert';

import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/src/rust/api/qjs.dart';

// 用来简化调用，将繁体中文转换为简体中文/包括日本汉字
String t2s(String text) {
  try {
    // 第一步：日文汉字 → 繁体中文
    final step1 = openccConvert(text: text, config: 'jp2t.json');
    // 第二步：繁体中文 → 简体中文
    return openccConvert(text: step1, config: 'tw2sp.json');
  } catch (e) {
    logger.e(e);
    return text;
  }
}

// 按全局设置转换漫画文本用于显示;关闭时原样返回。
// 与 t2s 的区别:t2s 固定转简体(用于搜索/屏蔽词的繁简无关匹配),
// 本函数受用户「简繁转换」开关控制,仅作用于显示层。
String convertChineseForDisplay(String text) {
  final mode = globalSetting.chineseConvertMode;
  if (mode == ChineseConvertMode.off || text.isEmpty) return text;
  return openccConvert(text: text, config: mode.openccConfig);
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

Future<void> registerPersistentCallbacks() async {
  await registerSavePluginConfig(
    dartCallback: (name, key, value) =>
        Future.sync(() => onSavePluginConfig(name, key, value)),
  );

  await registerLoadPluginConfig(
    dartCallback: (name, key, value) =>
        Future.sync(() => onLoadPluginConfig(name, key, value)),
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
