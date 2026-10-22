import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/src/rust/api/qjs.dart';

/// 用来简化调用，将繁体中文转换为简体中文/包括日本汉字
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

/// 显示层繁简转换缓存：底层走 Rust FFI（opencc），配置加载后转换本身快，
/// 但跨语言调用仍有固定开销。列表滚动时同一标题每帧 build 都会调一次，
/// 这里按「模式|原文」缓存，切换设置后自然 miss。
/// 注意：t2s 不走这里——搜索/屏蔽词是低频调用，保持原样。
final Map<String, String> _displayConvertCache = {};

/// 按全局设置转换漫画文本用于显示;关闭时原样返回。
/// 与 t2s 的区别:t2s 固定转简体(用于搜索/屏蔽词的繁简无关匹配),
/// 本函数受用户「简繁转换」开关控制,仅作用于显示层。
String convertChineseForDisplay(String text) {
  final mode = globalSetting.chineseConvertMode;
  if (mode == ChineseConvertMode.off || text.isEmpty) return text;
  final key = '${mode.name}|$text';
  final cached = _displayConvertCache[key];
  if (cached != null) return cached;
  final converted = openccConvert(text: text, config: mode.openccConfig);
  if (_displayConvertCache.length > 2000) _displayConvertCache.clear();
  _displayConvertCache[key] = converted;
  return converted;
}
