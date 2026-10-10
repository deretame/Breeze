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
  var attempt = 0;
  // 开启“失败后持续重试”时不设尝试上限：退出只靠取消、
  // 不可重试错误（404/空数据），或开关关闭且打满静默次数。
  while (true) {
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

      final retryNumber = attempt + 1;
      attempt += 1;
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
}

bool _isDownloadCancellation(Object error) {
  final message = error.toString();
  return message.contains(downloadTaskCancelledMessage) ||
      message.contains('__QJS_RUNTIME_CANCELLED__');
}
