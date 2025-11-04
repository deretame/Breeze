import 'package:flutter/foundation.dart';
import 'package:zephyr/main.dart';

import 'combined_memory_monitor.dart';
import 'rust_memory_monitor.dart';

/// 简化的压缩内存测试工具
class SimpleCompressionMemoryTest {
  /// 测试任意异步操作的内存使用
  static Future<T> testOperationMemory<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    if (!kDebugMode) {
      return await operation();
    }

    return await CombinedMemoryMonitor.measureCompleteMemoryUsage(
      operationName,
      operation,
    );
  }

  /// 测试 Rust 操作的内存使用
  static Future<T> testRustOperationMemory<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    if (!kDebugMode) {
      return await operation();
    }

    return await RustMemoryMonitor.measureRustMemoryUsage(
      operationName,
      operation,
    );
  }

  /// 记录当前完整内存状态
  static Future<void> logCurrentMemoryState([String? label]) async {
    if (kDebugMode) {
      await CombinedMemoryMonitor.logCompleteMemoryUsage(label);
    }
  }

  /// 记录当前 Rust 内存状态
  static Future<void> logCurrentRustMemoryState([String? label]) async {
    if (kDebugMode) {
      await RustMemoryMonitor.logRustMemoryUsage(label);
    }
  }

  /// 内存压力测试
  static Future<void> memoryStressTest() async {
    if (!kDebugMode) return;

    logger.d('=== Memory Stress Test ===');

    await CombinedMemoryMonitor.measureCompleteMemoryUsage(
      'Memory Stress Test',
      () async {
        // 创建一些大的数据结构来测试内存跟踪
        final largeData = <String>[];

        // 分批创建数据
        for (int batch = 0; batch < 10; batch++) {
          logger.d('Creating batch $batch...');

          // 每批创建 100,000 个字符串
          for (int i = 0; i < 100000; i++) {
            largeData.add('Item ${batch * 100000 + i}');
          }

          // 每批后记录内存状态
          await logCurrentMemoryState('After batch $batch');

          // 短暂延迟
          await Future.delayed(const Duration(milliseconds: 100));
        }

        logger.d('Clearing data...');
        largeData.clear();

        // 最终内存状态
        await logCurrentMemoryState('After cleanup');
      },
    );
  }

  /// 比较两个操作的内存使用
  static Future<void> compareOperations<T1, T2>(
    String operation1Name,
    Future<T1> Function() operation1,
    String operation2Name,
    Future<T2> Function() operation2,
  ) async {
    if (!kDebugMode) {
      await operation1();
      await operation2();
      return;
    }

    logger.d('=== Comparing Operations ===');

    // 测试第一个操作
    logger.d('\n--- Testing $operation1Name ---');
    await testOperationMemory(operation1Name, operation1);

    // 等待内存稳定
    await Future.delayed(const Duration(seconds: 2));

    // 测试第二个操作
    logger.d('\n--- Testing $operation2Name ---');
    await testOperationMemory(operation2Name, operation2);

    logger.d('\n=== Comparison Complete ===');
  }
}
