import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/service/download/download_retry.dart';

void main() {
  test(
    'silently retries an operation three times after the first failure',
    () async {
      var attempts = 0;

      final result = await retryDownloadOperation<int>(
        operation: 'test operation',
        ensureTaskRunning: () async {},
        retryDelay: Duration.zero,
        action: () async {
          attempts++;
          if (attempts < 4) {
            throw StateError('temporary failure');
          }
          return 42;
        },
      );

      expect(result, 42);
      expect(attempts, 4);
    },
  );

  test('does not retry when the error is marked as non-retryable', () async {
    var attempts = 0;

    await expectLater(
      retryDownloadOperation<void>(
        operation: 'test operation',
        ensureTaskRunning: () async {},
        retryDelay: Duration.zero,
        shouldRetry: (_) => false,
        action: () async {
          attempts++;
          throw StateError('permanent failure');
        },
      ),
      throwsStateError,
    );

    expect(attempts, 1);
  });

  test('keeps retrying until success when enabled', () async {
    var attempts = 0;

    final result = await retryDownloadOperation<int>(
      operation: 'test operation',
      ensureTaskRunning: () async {},
      shouldRetryUntilSuccess: () => true,
      retryDelay: Duration.zero,
      action: () async {
        attempts++;
        if (attempts < 5) {
          throw StateError('temporary failure');
        }
        return 42;
      },
    );

    expect(result, 42);
    expect(attempts, 5);
  });

  test('stops retrying when the switch is turned off mid-flight', () async {
    var attempts = 0;
    var switchOn = true;

    await expectLater(
      retryDownloadOperation<int>(
        operation: 'test operation',
        ensureTaskRunning: () async {},
        // 前 5 次开着（无限重试），第 6 次起关闭：累计尝试已超静默预算，
        // 下一次失败即停，不再给新的静默次数。
        shouldRetryUntilSuccess: () => switchOn,
        retryDelay: Duration.zero,
        action: () async {
          attempts++;
          if (attempts >= 6) switchOn = false;
          throw StateError('temporary failure');
        },
      ),
      throwsStateError,
    );

    expect(attempts, 6);
  });
}
