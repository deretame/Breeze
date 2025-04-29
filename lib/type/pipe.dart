import 'dart:async';

import 'package:flutter/foundation.dart';

import '../main.dart';

extension Pipe<T> on T {
  R pipe<R>(R Function(T) fn) => fn(this);

  /// 显式类型标注版本
  R pipeAs<R>(R Function(T) fn) => fn(this);
}

extension FuturePipe<T> on Future<T> {
  Future<R> pipe<R>(FutureOr<R> Function(T) fn) => then(fn);

  /// 显式类型标注版本
  Future<R> pipeAs<R>(FutureOr<R> Function(T) fn) => then(fn);
}

extension PipeX<T> on T {
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

extension FutureDebug<T> on Future<T> {
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
