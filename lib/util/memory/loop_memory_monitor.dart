import 'package:flutter/foundation.dart';
import 'package:zephyr/main.dart';

import 'combined_memory_monitor.dart';
import 'rust_memory_monitor.dart';
import 'simple_memory_monitor.dart';

/// 循环操作的内存监控器
class LoopMemoryMonitor {
  late SimpleMemoryInfo _initialMemory;
  late final String _operationName;
  int _currentIteration = 0;
  int _logInterval;
  final bool _trackRust;

  LoopMemoryMonitor({
    required String operationName,
    int logInterval = 10,
    bool trackRust = true,
  }) : _operationName = operationName,
       _logInterval = logInterval,
       _trackRust = trackRust;

  /// 开始监控循环操作
  Future<void> startMonitoring() async {
    if (!kDebugMode) return;

    _currentIteration = 0;
    _initialMemory = await SimpleMemoryMonitor.getMemoryInfo();

    logger.d('=== Starting Loop Memory Monitoring: $_operationName ===');
    await CombinedMemoryMonitor.logCompleteMemoryUsage(
      '$_operationName - Initial State',
    );

    if (_trackRust) {
      await RustMemoryMonitor.resetRustMemoryStats();
    }
  }

  /// 在每次循环迭代后调用
  Future<void> onIteration({String? itemDescription}) async {
    if (!kDebugMode) return;

    _currentIteration++;

    // 按间隔记录内存
    if (_currentIteration % _logInterval == 0) {
      final description = itemDescription ?? 'iteration $_currentIteration';
      logger.d(
        '=== Memory Status After $_currentIteration iterations ($_operationName) ===',
      );

      final currentMemory = await SimpleMemoryMonitor.getMemoryInfo();
      _printMemoryDiff(_initialMemory, currentMemory, description);

      if (_trackRust) {
        await RustMemoryMonitor.logRustMemoryUsage(
          'Rust memory after $_currentIteration iterations',
        );
      }
    }
  }

  /// 完成监控
  Future<void> finishMonitoring() async {
    if (!kDebugMode) return;

    logger.d('=== Loop Memory Monitoring Complete: $_operationName ===');
    logger.d('Total iterations: $_currentIteration');

    final finalMemory = await SimpleMemoryMonitor.getMemoryInfo();
    _printMemoryDiff(_initialMemory, finalMemory, 'Final');

    await CombinedMemoryMonitor.logCompleteMemoryUsage(
      '$_operationName - Final State',
    );

    if (_trackRust) {
      await RustMemoryMonitor.logRustMemoryUsage('Final Rust memory usage');
    }
  }

  /// 设置记录间隔
  void setLogInterval(int interval) {
    _logInterval = interval;
  }

  /// 强制记录当前内存状态
  Future<void> forceLog([String? description]) async {
    if (!kDebugMode) return;

    final desc = description ?? 'forced log at iteration $_currentIteration';
    logger.d('=== Forced Memory Log: $desc ===');

    final currentMemory = await SimpleMemoryMonitor.getMemoryInfo();
    _printMemoryDiff(_initialMemory, currentMemory, desc);

    if (_trackRust) {
      await RustMemoryMonitor.logRustMemoryUsage('Rust memory - $desc');
    }
  }

  void _printMemoryDiff(
    SimpleMemoryInfo initial,
    SimpleMemoryInfo current,
    String description,
  ) {
    final dartDiff = current.dartHeapUsed - initial.dartHeapUsed;
    final nativeDiff =
        current.nativeHeapAllocated - initial.nativeHeapAllocated;
    final runtimeDiff = current.runtimeUsed - initial.runtimeUsed;

    logger.d('Memory diff for $description:');
    logger.d('  Dart Heap: ${_formatBytesDiff(dartDiff)}');
    logger.d('  Native Heap: ${_formatBytesDiff(nativeDiff)}');
    logger.d('  Runtime: ${_formatBytesDiff(runtimeDiff)}');
    logger.d('  Current Dart: ${_formatBytes(current.dartHeapUsed)}');
    logger.d('  Current Native: ${_formatBytes(current.nativeHeapAllocated)}');
  }

  String _formatBytesDiff(int bytes) {
    final sign = bytes >= 0 ? '+' : '';
    return '$sign${_formatBytes(bytes.abs())}';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// 便捷的循环监控函数
class LoopMemoryHelper {
  /// 监控一个循环操作
  static Future<T> monitorLoop<T>(
    String operationName,
    Iterable<dynamic> items,
    Future<T> Function(dynamic item, int index, LoopMemoryMonitor monitor)
    operation, {
    int logInterval = 10,
    bool trackRust = true,
  }) async {
    if (!kDebugMode) {
      // 在 Release 模式下直接执行，不监控
      T? result;
      for (int i = 0; i < items.length; i++) {
        result = await operation(
          items.elementAt(i),
          i,
          LoopMemoryMonitor(operationName: operationName),
        );
      }
      return result!;
    }

    final monitor = LoopMemoryMonitor(
      operationName: operationName,
      logInterval: logInterval,
      trackRust: trackRust,
    );

    await monitor.startMonitoring();

    T? result;
    try {
      for (int i = 0; i < items.length; i++) {
        final item = items.elementAt(i);
        result = await operation(item, i, monitor);
        await monitor.onIteration(itemDescription: 'item $i');
      }
    } finally {
      await monitor.finishMonitoring();
    }

    return result!;
  }

  /// 监控下载循环的专用函数
  static Future<void> monitorDownloadLoop(
    List<dynamic> downloadItems,
    Future<void> Function(dynamic item, int index) downloadFunction, {
    int logInterval = 5,
  }) async {
    await monitorLoop(
      'Download Loop',
      downloadItems,
      (item, index, monitor) async {
        await downloadFunction(item, index);

        // 每次下载后检查是否需要强制记录内存（比如内存增长过快）
        if (index > 0 && index % 50 == 0) {
          await monitor.forceLog('Checkpoint at item $index');
        }
      },
      logInterval: logInterval,
      trackRust: true,
    );
  }
}
