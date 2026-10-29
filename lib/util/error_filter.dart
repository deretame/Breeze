import 'dart:io';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:logger/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
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

/// 日志/Sentry/UI 展示前清洗异常文本：插件常把 `data:` URL（整张 base64 图，
/// 单行十几万字符不断行）当 URL 传给 fetch，失败后整段跟着异常到处打——
/// 控制台渲染、Sentry 上传都卡在这一行上。
/// 清洗只动展示层：原始异常对象原样传递，重试判定不受影响。
///
/// 只处理超长**单行**（默认 > 2000 字符）：正常的多行长日志原样保留；
/// 命中 dataURL/base64 的行折叠载荷，其余超长行按行截断并保留换行。
String sanitizeErrorText(
  Object error, {
  int maxLength = 500,
  int maxLineLength = 2000,
}) {
  final cleaned = <String>[];
  var total = 0;
  for (var line in error.toString().split('\n')) {
    if (total >= maxLength) break;
    if (line.length > maxLineLength) {
      // data: 开头的 URL 只保留头部声明，载荷丢掉。
      line = line.replaceAllMapped(
        RegExp(
          r'data:[a-zA-Z0-9/+.-]+/[a-zA-Z0-9/+.=-]+;base64,[A-Za-z0-9+/=]{16,}',
        ),
        (m) =>
            '${m.group(0)!.substring(0, m.group(0)!.indexOf(',') + 1)}<base64(${m.group(0)!.length} chars)>',
      );
      // 残余的超长 base64/blob 碎片（无 data: 头）：按长度折叠。
      line = line.replaceAllMapped(
        RegExp(r'[A-Za-z0-9+/=]{200,}'),
        (m) => '<base64(${m.group(0)!.length} chars)>',
      );
      // 只压连续空格/tab，不断行。
      line = line.replaceAll(RegExp(r'[ \t]+'), ' ').trim();
      // dataURL 正则漏网的行（如非 base64 编码的 data: URL）：硬截断。
      if (line.length > maxLineLength) {
        line =
            '${line.substring(0, maxLineLength)}…(line ${line.length} chars)';
      }
    }
    if (line.trim().isEmpty) continue;
    final remain = maxLength - total;
    if (line.length > remain) {
      cleaned.add('${line.substring(0, remain)}…');
      break;
    }
    cleaned.add(line);
    total += line.length + 1;
  }
  return cleaned.join('\n');
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

  /// 消息出口统一清洗：`logger.e(exceptionObject)` 时 message 是对象而非
  /// String，`log()` 里 `is String` 判断会漏过；`stringifyMessage` 是转字符串
  /// 的必经之路（String/Map/Iterable/Function/任意对象），在此截流全覆盖。
  @override
  String stringifyMessage(dynamic message) {
    return sanitizeErrorText(super.stringifyMessage(message), maxLength: 4000);
  }

  /// error/stackTrace 清洗：`logger.e(msg, error: e, stackTrace: s)` 的后两个
  /// 参数在父类 `log()` 里才 `toString()`，这里重建 event 提前清洗。
  /// 注意：只换 error/stackTrace，message/time 原样透传（message 由上面的
  /// [stringifyMessage] 统一清洗，避免漏掉对象类型）。
  @override
  List<String> log(LogEvent event) {
    if (event.error == null && event.stackTrace == null) {
      return super.log(event);
    }
    return super.log(
      LogEvent(
        event.level,
        event.message,
        time: event.time,
        error: event.error == null
            ? null
            : sanitizeErrorText(event.error!, maxLength: 4000),
        stackTrace: event.stackTrace == null
            ? null
            : StackTrace.fromString(
                sanitizeErrorText(event.stackTrace.toString(), maxLength: 2000),
              ),
      ),
    );
  }

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

/// Sentry 上报前清洗：`beforeSend` 把异常文本、面包屑里的 dataURL/base64
/// 载荷替换为类型声明 + 长度。Sentry 对超大事件去重失败还会反复上传，
/// 巨型 base64（整张图几十 KB～MB）直接炸配额。返回 null 会丢弃事件，
/// 这里永远返回 event，只清洗不丢弃。
FutureOr<SentryEvent?> sanitizeSentryEvent(SentryEvent event, Hint hint) {
  if (event.message != null) {
    event.message = SentryMessage(sanitizeErrorText(event.message!.formatted));
  }
  final exceptions = event.exceptions;
  if (exceptions != null) {
    for (final e in exceptions) {
      if (e.value != null) e.value = sanitizeErrorText(e.value!);
    }
  }
  final breadcrumbs = event.breadcrumbs;
  if (breadcrumbs != null) {
    for (var i = 0; i < breadcrumbs.length; i++) {
      final b = breadcrumbs[i];
      if (b.message != null) {
        breadcrumbs[i] = Breadcrumb(
          message: sanitizeErrorText(b.message!),
          category: b.category,
          data: b.data,
          level: b.level,
          type: b.type,
          timestamp: b.timestamp,
        );
      }
    }
  }
  return event;
}
