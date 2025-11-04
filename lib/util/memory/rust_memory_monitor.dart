import 'package:flutter/foundation.dart';
import 'package:zephyr/main.dart';

import '../../src/rust/api/memory.dart';

/// Rust 端内存监控器
class RustMemoryMonitor {
  /// 获取 Rust 端内存使用情况
  static Future<RustMemoryInfo> getRustMemoryInfo() async {
    try {
      return await getRustMemoryInfo();
    } catch (e) {
      if (kDebugMode) logger.d('Failed to get Rust memory info: $e');
      rethrow;
    }
  }

  /// 重置 Rust 内存统计
  static Future<void> resetRustMemoryStats() async {
    try {
      await resetRustMemoryStats();
    } catch (e) {
      if (kDebugMode) logger.d('Failed to reset Rust memory stats: $e');
      rethrow;
    }
  }

  /// 获取 Rust 内存使用的格式化字符串
  static Future<String> getRustMemorySummary() async {
    try {
      return await getRustMemorySummary();
    } catch (e) {
      if (kDebugMode) logger.d('Failed to get Rust memory summary: $e');
      return 'Failed to get Rust memory info: $e';
    }
  }

  /// 记录 Rust 内存使用情况到日志
  static Future<void> logRustMemoryUsage([String? label]) async {
    if (kDebugMode) {
      final summary = await getRustMemorySummary();
      logger.d('${label ?? 'Rust Memory Usage'}:\n$summary');
    }
  }

  /// 监控特定操作的 Rust 内存使用
  static Future<T> measureRustMemoryUsage<T>(
    String label,
    Future<T> Function() operation,
  ) async {
    if (!kDebugMode) {
      // 在 Release 模式下直接执行操作，不进行监控
      return await operation();
    }

    // 重置统计以获得准确的测量
    await resetRustMemoryStats();

    final result = await operation();

    final info = await getRustMemoryInfo();
    logger.d('=== Rust Memory Usage for $label ===');
    logger.d('Total Allocated: ${_formatBytes(info.totalAllocated)}');
    logger.d('Peak Allocated: ${_formatBytes(info.peakAllocated)}');
    logger.d('Allocations: ${info.allocationCount}');
    logger.d('Deallocations: ${info.deallocationCount}');

    if (info.taggedAllocations.isNotEmpty) {
      logger.d('Tagged Allocations:');
      for (final tagged in info.taggedAllocations) {
        logger.d('  ${tagged.tag}: ${_formatBytes(tagged.size)}');
      }
    }

    return result;
  }

  /// 获取格式化的内存信息
  static Future<String> getFormattedMemoryInfo() async {
    try {
      final info = await getRustMemoryInfo();
      final buffer = StringBuffer();

      buffer.writeln('=== Rust Memory Usage ===');
      buffer.writeln('Total Allocated: ${_formatBytes(info.totalAllocated)}');
      buffer.writeln('Peak Allocated: ${_formatBytes(info.peakAllocated)}');
      buffer.writeln('Allocations: ${info.allocationCount}');
      buffer.writeln('Deallocations: ${info.deallocationCount}');

      if (info.taggedAllocations.isNotEmpty) {
        buffer.writeln('Tagged Allocations:');
        for (final tagged in info.taggedAllocations) {
          buffer.writeln('  ${tagged.tag}: ${_formatBytes(tagged.size)}');
        }
      }

      return buffer.toString();
    } catch (e) {
      return 'Failed to get Rust memory info: $e';
    }
  }

  static String _formatBytes(BigInt bytes) {
    final bytesInt = bytes.toInt();
    if (bytesInt < 1024) return '$bytesInt B';
    if (bytesInt < 1024 * 1024) {
      return '${(bytesInt / 1024).toStringAsFixed(1)} KB';
    }
    if (bytesInt < 1024 * 1024 * 1024) {
      return '${(bytesInt / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytesInt / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
