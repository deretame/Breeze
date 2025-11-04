import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 简化的内存监控器，更可靠但功能较少
class SimpleMemoryMonitor {
  static const MethodChannel _channel = MethodChannel('memory_monitor');

  /// 获取基本内存信息
  static Future<SimpleMemoryInfo> getMemoryInfo() async {
    Map<String, int> systemMemory = {};
    Map<String, int> dartMemory = {};

    // 获取系统内存信息
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final result = await _channel.invokeMethod<Map>('getMemoryInfo');
        systemMemory = Map<String, int>.from(result ?? {});
      }
    } catch (e) {
      if (kDebugMode) print('Failed to get system memory: $e');
    }

    // 获取 Dart/JVM 内存信息
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final result = await _channel.invokeMethod<Map>('getDartMemoryInfo');
        dartMemory = Map<String, int>.from(result ?? {});
      }
    } catch (e) {
      if (kDebugMode) print('Failed to get Dart memory: $e');
    }

    return SimpleMemoryInfo(
      // Dart/Runtime 内存
      dartHeapUsed: dartMemory['dartHeapUsed'] ?? 0,
      dartHeapCapacity: dartMemory['dartHeapCapacity'] ?? 0,
      dartHeapCommitted: dartMemory['dartHeapCommitted'] ?? 0,

      // Native 内存 (优先从 dartMemory 获取，因为更准确)
      nativeHeapSize:
          dartMemory['nativeHeapSize'] ?? systemMemory['nativeHeapSize'] ?? 0,
      nativeHeapAllocated:
          dartMemory['nativeHeapAllocated'] ??
          systemMemory['nativeHeapAllocatedSize'] ??
          0,

      // 系统内存
      systemTotal: systemMemory['totalMemory'] ?? 0,
      systemAvailable: systemMemory['availableMemory'] ?? 0,

      // Runtime 内存
      runtimeMax: dartMemory['maxMemory'] ?? 0,
      runtimeTotal: dartMemory['totalMemory'] ?? 0,
      runtimeFree: dartMemory['freeMemory'] ?? 0,
      runtimeUsed: dartMemory['usedMemory'] ?? 0,
    );
  }

  /// 记录内存使用情况
  static Future<void> logMemoryUsage([String? label]) async {
    if (kDebugMode) {
      final info = await getMemoryInfo();
      print('${label ?? 'Memory Usage'}:\n$info');
    }
  }

  /// 监控代码块的内存使用
  static Future<T> measureMemoryUsage<T>(
    String label,
    Future<T> Function() operation,
  ) async {
    final before = await getMemoryInfo();
    final result = await operation();
    final after = await getMemoryInfo();

    if (kDebugMode) {
      print('=== Memory Usage for $label ===');
      print(
        'Before: Dart=${_formatBytes(before.dartHeapUsed)}, Native=${_formatBytes(before.nativeHeapAllocated)}',
      );
      print(
        'After:  Dart=${_formatBytes(after.dartHeapUsed)}, Native=${_formatBytes(after.nativeHeapAllocated)}',
      );
      print(
        'Diff:   Dart=${_formatBytes(after.dartHeapUsed - before.dartHeapUsed)}, Native=${_formatBytes(after.nativeHeapAllocated - before.nativeHeapAllocated)}',
      );
    }

    return result;
  }

  static String _formatBytes(int bytes) {
    if (bytes < 0) return 'N/A';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class SimpleMemoryInfo {
  final int dartHeapUsed;
  final int dartHeapCapacity;
  final int dartHeapCommitted;
  final int nativeHeapSize;
  final int nativeHeapAllocated;
  final int systemTotal;
  final int systemAvailable;
  final int runtimeMax;
  final int runtimeTotal;
  final int runtimeFree;
  final int runtimeUsed;

  SimpleMemoryInfo({
    required this.dartHeapUsed,
    required this.dartHeapCapacity,
    required this.dartHeapCommitted,
    required this.nativeHeapSize,
    required this.nativeHeapAllocated,
    required this.systemTotal,
    required this.systemAvailable,
    required this.runtimeMax,
    required this.runtimeTotal,
    required this.runtimeFree,
    required this.runtimeUsed,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('=== Memory Usage (Simple) ===');

    // Dart/JVM 内存
    buffer.writeln('Dart Heap Used: ${_formatBytes(dartHeapUsed)}');
    buffer.writeln('Dart Heap Capacity: ${_formatBytes(dartHeapCapacity)}');
    buffer.writeln('Dart Heap Committed: ${_formatBytes(dartHeapCommitted)}');

    // Runtime 内存
    buffer.writeln('Runtime Used: ${_formatBytes(runtimeUsed)}');
    buffer.writeln('Runtime Total: ${_formatBytes(runtimeTotal)}');
    buffer.writeln('Runtime Max: ${_formatBytes(runtimeMax)}');

    // Native 内存
    if (nativeHeapAllocated > 0) {
      buffer.writeln('Native Heap: ${_formatBytes(nativeHeapAllocated)}');
    }

    // 系统内存
    if (systemTotal > 0 && systemAvailable > 0) {
      buffer.writeln('System Total: ${_formatBytes(systemTotal)}');
      buffer.writeln('System Available: ${_formatBytes(systemAvailable)}');
      buffer.writeln(
        'System Used: ${_formatBytes(systemTotal - systemAvailable)}',
      );
    }

    return buffer.toString();
  }

  static String _formatBytes(int bytes) {
    if (bytes < 0) return 'N/A';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
