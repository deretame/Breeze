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

/// 按全局设置转换漫画文本用于显示;关闭时原样返回。
/// 与 t2s 的区别:t2s 固定转简体(用于搜索/屏蔽词的繁简无关匹配),
/// 本函数受用户「简繁转换」开关控制,仅作用于显示层。
String convertChineseForDisplay(String text) {
  final mode = globalSetting.chineseConvertMode;
  if (mode == ChineseConvertMode.off || text.isEmpty) return text;
  return openccConvert(text: text, config: mode.openccConfig);
}
