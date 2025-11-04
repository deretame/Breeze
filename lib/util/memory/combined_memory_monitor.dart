import 'package:flutter/foundation.dart';
import 'package:zephyr/main.dart';

import 'rust_memory_monitor.dart';
import 'simple_memory_monitor.dart';

/// 组合的内存监控器，同时监控 Dart 和 Rust
class CombinedMemoryMonitor {
  /// 获取完整的内存使用情况（Dart + Rust + 系统）
  static Future<CombinedMemoryInfo> getCompleteMemoryInfo() async {
    final dartMemory = await SimpleMemoryMonitor.getMemoryInfo();

    String? rustMemorySummary;
    try {
      rustMemorySummary = await RustMemoryMonitor.getRustMemorySummary();
    } catch (e) {
      if (kDebugMode) logger.d('Failed to get Rust memory: $e');
      rustMemorySummary = null;
    }

    return CombinedMemoryInfo(
      dartMemory: dartMemory,
      rustMemorySummary: rustMemorySummary,
    );
  }

  /// 记录完整的内存使用情况
  static Future<void> logCompleteMemoryUsage([String? label]) async {
    if (kDebugMode) {
      final info = await getCompleteMemoryInfo();
      logger.d('${label ?? 'Complete Memory Usage'}:\n$info');
    }
  }

  /// 监控特定操作的完整内存使用（推荐用于压缩操作）
  static Future<T> measureCompleteMemoryUsage<T>(
    String label,
    Future<T> Function() operation,
  ) async {
    if (!kDebugMode) {
      return await operation();
    }

    logger.d('=== Starting memory measurement for $label ===');

    // 获取开始时的内存状态
    final beforeInfo = await getCompleteMemoryInfo();
    logger.d('Before $label:');
    logger.d(beforeInfo);

    // 重置 Rust 内存统计以获得准确的测量
    try {
      await RustMemoryMonitor.resetRustMemoryStats();
    } catch (e) {
      logger.d('Failed to reset Rust memory stats: $e');
    }

    // 执行操作
    final result = await operation();

    // 获取结束时的内存状态
    final afterInfo = await getCompleteMemoryInfo();
    logger.d('After $label:');
    logger.d(afterInfo);

    // 计算差异
    _printMemoryDiff(beforeInfo.dartMemory, afterInfo.dartMemory, label);

    return result;
  }

  static void _printMemoryDiff(
    SimpleMemoryInfo before,
    SimpleMemoryInfo after,
    String label,
  ) {
    final dartHeapDiff = after.dartHeapUsed - before.dartHeapUsed;
    final nativeDiff = after.nativeHeapAllocated - before.nativeHeapAllocated;
    final runtimeDiff = after.runtimeUsed - before.runtimeUsed;

    logger.d('=== Memory Diff for $label ===');
    logger.d('Dart Heap: ${_formatBytesDiff(dartHeapDiff)}');
    logger.d('Native Heap: ${_formatBytesDiff(nativeDiff)}');
    logger.d('Runtime: ${_formatBytesDiff(runtimeDiff)}');
  }

  static String _formatBytesDiff(int bytes) {
    final sign = bytes >= 0 ? '+' : '';
    return '$sign${_formatBytes(bytes.abs())}';
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class CombinedMemoryInfo {
  final SimpleMemoryInfo dartMemory;
  final String? rustMemorySummary;

  CombinedMemoryInfo({required this.dartMemory, this.rustMemorySummary});

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('=== Combined Memory Usage ===');
    buffer.writeln();
    buffer.writeln('--- Dart/Android Memory ---');
    buffer.write(dartMemory.toString());

    if (rustMemorySummary != null) {
      buffer.writeln();
      buffer.writeln('--- Rust Memory ---');
      buffer.write(rustMemorySummary!);
    } else {
      buffer.writeln();
      buffer.writeln('--- Rust Memory ---');
      buffer.writeln('Rust memory info not available');
    }

    return buffer.toString();
  }
}
