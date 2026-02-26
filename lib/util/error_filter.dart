import 'dart:io';

import 'package:logger/logger.dart';
import 'package:stack_trace/stack_trace.dart';

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
