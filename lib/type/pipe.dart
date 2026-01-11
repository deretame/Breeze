import 'dart:async';

import 'package:flutter/foundation.dart';

import '../main.dart';

extension KotlinScopeFunctions<T> on T {
  /// let: 转换对象
  R let<R>(R Function(T) block) => block(this);

  /// also: 执行副作用后返回对象本身
  T also(void Function(T) block) {
    block(this);
    return this;
  }

  T debug([void Function(T)? logFn, String tag = 'DEBUG']) {
    final message = '[$tag] $this';
    if (logFn != null) {
      logFn(this);
    } else {
      logger.d(message);
    }
    return this;
  }
}

extension KotlinAsyncScopeFunctions<T> on Future<T> {
  /// 异步版 let
  Future<R> let<R>(FutureOr<R> Function(T) block) => then(block);

  /// 异步版 also
  Future<T> also(FutureOr<void> Function(T) block) async {
    await block(await this);
    return this;
  }

  Future<T> debug([void Function(T)? logFn, String tag = 'DEBUG']) async {
    if (!kDebugMode) return this;
    final value = await this;
    final message = '[$tag] $value';
    if (logFn != null) {
      logFn(value);
    } else {
      logger.d(message);
    }
    return value;
  }
}

// 这个是给管道用的
String toString(Object? object) {
  try {
    return object?.toString() ?? 'null';
  } catch (e) {
    return 'toString() failed: ${e.toString()}'; // 兜底处理
  }
}

int toInt(Object? object) {
  if (object == null) return 0;
  if (object is int) return object; // 已经是 int 直接返回，最快
  if (object is double) return object.toInt(); // 处理浮点数转整数

  // 仅对字符串进行解析，并忽略前后空格
  return int.tryParse(object.toString().trim()) ?? 0;
}

double toDouble(Object? object) {
  if (object == null) return 0.0;
  if (object is double) return object; // 已经是 double 直接返回
  if (object is int) return object.toDouble(); // 处理整数转浮点

  return double.tryParse(object.toString().trim()) ?? 0.0;
}

bool toBool(Object? object) {
  if (object is bool) return object;

  return bool.tryParse(object.toString(), caseSensitive: false) ?? false;
}
