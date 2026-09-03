import 'package:zephyr/main.dart';
import 'package:zephyr/service/download/download_cancel_signal.dart';

/// 下载操作在首次尝试失败后，默认最多静默重试的次数。
const downloadSilentRetryCount = 3;

Future<T> retryDownloadOperation<T>({
  required String operation,
  required Future<T> Function() action,
  required Future<void> Function() ensureTaskRunning,
  bool Function(Object error)? shouldRetry,
  bool Function()? shouldRetryUntilSuccess,
  Duration retryDelay = const Duration(seconds: 1),
}) async {
  Object? lastError;
  StackTrace? lastStackTrace;

  for (var attempt = 0; attempt <= downloadSilentRetryCount; attempt++) {
    // 取消检查放在 try 外，取消不会被当成普通网络错误再次重试。
    await ensureTaskRunning();
    try {
      return await action();
    } catch (error, stackTrace) {
      final retryForever = shouldRetryUntilSuccess?.call() ?? false;
      if (_isDownloadCancellation(error) ||
          (!retryForever && attempt >= downloadSilentRetryCount) ||
          shouldRetry?.call(error) == false) {
        Error.throwWithStackTrace(error, stackTrace);
      }

      lastError = error;
      lastStackTrace = stackTrace;
      final retryNumber = attempt + 1;
      logger.w(
        retryForever
            ? '$operation 失败，准备持续重试 (第 $retryNumber 次)'
            : '$operation 失败，准备静默重试 ($retryNumber/$downloadSilentRetryCount)',
        error: error,
        stackTrace: stackTrace,
      );
      await Future<void>.delayed(retryDelay);
    }
  }

  // 逻辑上不会到达这里；保留栈信息，避免错误被意外吞掉。
  Error.throwWithStackTrace(lastError!, lastStackTrace!);
}

bool _isDownloadCancellation(Object error) {
  final message = error.toString();
  return message.contains(downloadTaskCancelledMessage) ||
      message.contains('__QJS_RUNTIME_CANCELLED__');
}
