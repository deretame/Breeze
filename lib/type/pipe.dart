import 'dart:async';

import 'package:flutter/foundation.dart';

import '../main.dart';

extension KotlinScopeFunctions<T> on T {
  R let<R>(R Function(T value) block) => block(this);

  T also(void Function(T value) block) {
    block(this);
    return this;
  }

  T debug([void Function(T value)? logFn, String tag = 'DEBUG']) {
    if (!kDebugMode) return this;
    if (logFn != null) {
      logFn(this);
    } else {
      logger.d('[$tag] $this');
    }
    return this;
  }
}

extension KotlinAsyncScopeFunctions<T> on Future<T> {
  Future<R> let<R>(FutureOr<R> Function(T value) block) => then(block);

  Future<T> also(FutureOr<void> Function(T value) block) async {
    final value = await this;
    await block(value);
    return value;
  }

  Future<T> debug([void Function(T value)? logFn, String tag = 'DEBUG']) async {
    final value = await this;
    if (!kDebugMode) return value;
    if (logFn != null) {
      logFn(value);
    } else {
      logger.d('[$tag] $value');
    }
    return value;
  }
}

String toString(Object? value) {
  try {
    return value?.toString() ?? 'null';
  } catch (e) {
    return 'toString() failed: $e';
  }
}

int toInt(Object? value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString().trim()) ?? 0;
}

double toDouble(Object? value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString().trim()) ?? 0.0;
}

bool toBool(Object? value) {
  if (value is bool) return value;
  return bool.tryParse(value.toString(), caseSensitive: false) ?? false;
}
