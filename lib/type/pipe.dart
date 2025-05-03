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

  /// run: 在对象上下文中执行代码块
  R run<R>(R Function(T) block) => block(this);

  /// apply: 配置对象后返回自身
  T apply(void Function(T) block) {
    block(this);
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

  /// 异步版 run
  Future<R> run<R>(FutureOr<R> Function(T) block) => then(block);

  /// 异步版 apply
  Future<T> apply(FutureOr<void> Function(T) block) async {
    await block(await this);
    return this;
  }
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
