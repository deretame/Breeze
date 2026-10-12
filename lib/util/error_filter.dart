import 'dart:io';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:logger/logger.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:zephyr/i18n/strings.g.dart';

bool shouldIgnoreError(dynamic error) {
  final errorStr = error.toString();
  if (error is PathNotFoundException ||
      errorStr.contains('PathNotFoundException') ||
      errorStr.contains('Cannot retrieve length of file') ||
      errorStr.contains('No such file or directory')) {
    return true;
  }
  return false;
}

class TersePrettyPrinter extends PrettyPrinter {
  TersePrettyPrinter({
    super.methodCount = 2,
    super.errorMethodCount = 8,
    super.lineLength = 120,
    super.colors = true,
    super.printEmojis = true,
    super.dateTimeFormat = DateTimeFormat.onlyTimeAndSinceStart,
  });

  @override
  String? formatStackTrace(StackTrace? stackTrace, int? methodCount) {
    if (stackTrace == null) return null;

    // 使用 stack_trace 库的 terse 过滤掉非项目代码的冗余帧
    var terseTrace = Trace.from(stackTrace).terse;

    // 将过滤后的 Trace 转换回符合 logger 格式的行列表
    return super.formatStackTrace(
      StackTrace.fromString(terseTrace.toString()),
      methodCount,
    );
  }
}

String normalizeSearchErrorMessage(Object error) {
  final message = switch (error) {
    AnyhowException(message: final message) => message.trim(),
    _ => error.toString().trim(),
  };
  // Dart 侧 StateError.toString() 会带上 `Bad state: ` 前缀，直接展示会让用户困惑；
  // 与 plugin_cloud_download_utils 的 _rawPluginErrorText 保持一致，展示前剥掉。
  var result = message;
  const prefixes = ['Bad state: ', 'Exception: '];
  var changed = true;
  while (changed) {
    changed = false;
    for (final prefix in prefixes) {
      if (result.startsWith(prefix)) {
        result = result.substring(prefix.length).trim();
        changed = true;
        break;
      }
    }
  }
  if (result.isNotEmpty) {
    return result;
  }
  return t.error.executionFailed;
}
