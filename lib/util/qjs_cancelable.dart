import 'dart:async';
import 'dart:convert';

import '../src/rust/api/qjs.dart';

class QjsCallCancelledException implements Exception {
  const QjsCallCancelledException({
    required this.runtimeName,
    required this.taskId,
    this.cause,
  });

  final String runtimeName;
  final BigInt taskId;
  final Object? cause;

  @override
  String toString() {
    final base = 'QJS call cancelled (runtime=$runtimeName, taskId=$taskId)';
    if (cause == null) {
      return base;
    }
    return '$base, cause: $cause';
  }
}

class QjsCancelableCall {
  QjsCancelableCall._({required this.runtimeName, required this.taskId});

  final String runtimeName;
  final BigInt taskId;

  bool _cancelRequested = false;
  bool _cancelConfirmed = false;
  Future<String>? _waitFuture;

  static Future<QjsCancelableCall> start({
    required String runtimeName,
    required String fnPath,
    required String argsJson,
  }) async {
    final taskId = await qjsCallStart(
      runtimeName: runtimeName,
      fnPath: fnPath,
      argsJson: argsJson,
    );
    return QjsCancelableCall._(runtimeName: runtimeName, taskId: taskId);
  }

  static Future<QjsCancelableCall> startWithArgs({
    required String runtimeName,
    required String fnPath,
    required List<dynamic> args,
  }) {
    return start(
      runtimeName: runtimeName,
      fnPath: fnPath,
      argsJson: jsonEncode(args),
    );
  }

  Future<bool> cancel() async {
    _cancelRequested = true;
    final cancelled = await qjsCallCancel(
      runtimeName: runtimeName,
      taskId: taskId,
    );
    if (cancelled) {
      _cancelConfirmed = true;
    }
    return cancelled;
  }

  Future<String> waitRaw({Duration? timeout}) {
    return _waitFuture ??= _waitRawInternal(timeout: timeout);
  }

  Future<dynamic> waitJson({Duration? timeout}) async {
    final raw = await waitRaw(timeout: timeout);
    return jsonDecode(raw);
  }

  Future<T> waitDecoded<T>(
    T Function(dynamic json) decoder, {
    Duration? timeout,
  }) async {
    final json = await waitJson(timeout: timeout);
    return decoder(json);
  }

  Future<String> _waitRawInternal({Duration? timeout}) async {
    var waitFuture = qjsCallWait(runtimeName: runtimeName, taskId: taskId);

    if (timeout != null) {
      waitFuture = waitFuture.timeout(
        timeout,
        onTimeout: () {
          unawaited(cancel());
          throw TimeoutException(
            'QJS call timeout after ${timeout.inMilliseconds}ms (runtime=$runtimeName, taskId=$taskId)',
          );
        },
      );
    }

    try {
      final raw = await waitFuture;
      if (_cancelConfirmed) {
        throw QjsCallCancelledException(
          runtimeName: runtimeName,
          taskId: taskId,
        );
      }
      return raw;
    } catch (error) {
      if (_cancelRequested || _cancelConfirmed) {
        throw QjsCallCancelledException(
          runtimeName: runtimeName,
          taskId: taskId,
          cause: error,
        );
      }
      rethrow;
    }
  }
}

// 使用示例
// final call = await QjsCancelableCall.startWithArgs(
//   runtimeName: 'jm',
//   fnPath: 'request',
//   args: [payload],
// );

// // 需要取消时
// await call.cancel();

// // 等待结果（可选超时）
// final data = await call.waitJson(timeout: const Duration(seconds: 20));
