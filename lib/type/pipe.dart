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
  try {
    return int.parse(object.toString());
  } catch (e) {
    return 0; // 兜底处理
  }
}

double toDouble(Object? object) {
  try {
    return double.parse(object.toString());
  } catch (e) {
    return 0.0; // 兜底处理
  }
}
