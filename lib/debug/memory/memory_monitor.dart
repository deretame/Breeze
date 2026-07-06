import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';
import 'package:zephyr/main.dart';

class MemoryInfo {
  final int dartHeapUsed;
  final int dartHeapCapacity;
  final int externalMemory;
  final int? nativeHeapSize;
  final int? totalMemory;
  final int? availableMemory;

  MemoryInfo({
    required this.dartHeapUsed,
    required this.dartHeapCapacity,
    required this.externalMemory,
    this.nativeHeapSize,
    this.totalMemory,
    this.availableMemory,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('=== Memory Usage ===');
    buffer.writeln('Dart Heap Used: ${_formatBytes(dartHeapUsed)}');
    buffer.writeln('Dart Heap Capacity: ${_formatBytes(dartHeapCapacity)}');
    buffer.writeln('External Memory: ${_formatBytes(externalMemory)}');
    if (nativeHeapSize != null) {
      buffer.writeln('Native Heap: ${_formatBytes(nativeHeapSize!)}');
    }
    if (totalMemory != null && availableMemory != null) {
      buffer.writeln('System Total: ${_formatBytes(totalMemory!)}');
      buffer.writeln('System Available: ${_formatBytes(availableMemory!)}');
      buffer.writeln(
        'System Used: ${_formatBytes(totalMemory! - availableMemory!)}',
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

class MemoryMonitor {
  static const MethodChannel _channel = MethodChannel('memory_monitor');
  static VmService? _vmService;

  // 获取详细的内存信息
  static Future<MemoryInfo> getMemoryInfo() async {
    // Dart 堆内存信息
    int dartHeapUsed = 0;
    int dartHeapCapacity = 0;
    int externalMemory = 0;

    // 方法1: 尝试使用 VM Service (仅在 Debug 模式下)
    if (kDebugMode) {
      try {
        await _connectToVmService();
        if (_vmService != null) {
          try {
            final vm = await _vmService!.getVM();
            if (vm.isolates?.isNotEmpty == true) {
              final isolateRef = vm.isolates!.first;
              final memoryUsage = await _vmService!.getMemoryUsage(
                isolateRef.id!,
              );
              dartHeapUsed = memoryUsage.heapUsage ?? 0;
              dartHeapCapacity = memoryUsage.heapCapacity ?? 0;
              externalMemory = memoryUsage.externalUsage ?? 0;
            }
          } catch (e) {
            logger.w('VM Service memory query failed: $e');
          }
        }
      } catch (e) {
        logger.w('VM Service connection failed: $e');
      }
    }

    // 方法2: 如果 VM Service 不可用，尝试通过 Platform Channel 获取
    if (dartHeapUsed == 0) {
      try {
        final dartMemory = await _getDartMemoryInfo();
        dartHeapUsed = dartMemory['dartHeapUsed'] ?? 0;
        dartHeapCapacity = dartMemory['dartHeapCapacity'] ?? 0;
        externalMemory = dartMemory['externalMemory'] ?? 0;
      } catch (e) {
        logger.w('Platform channel Dart memory query failed: $e');
      }
    }

    // 方法3: 如果以上都失败，使用简单的估算
    if (dartHeapUsed == 0) {
      logger.w('Unable to get precise Dart memory info, using estimation');
      // 这里我们无法获取精确的 Dart 内存，但至少不显示 0
      dartHeapUsed = -1; // 使用 -1 表示无法获取
      dartHeapCapacity = -1;
    }

    // 系统内存信息
    int? nativeHeapSize;
    int? totalMemory;
    int? availableMemory;

    try {
      final systemMemory = await _getSystemMemoryInfo();
      nativeHeapSize = systemMemory['nativeHeapSize'];
      totalMemory = systemMemory['totalMemory'];
      availableMemory = systemMemory['availableMemory'];
    } catch (e) {
      logger.e('Failed to get system memory info: $e');
    }

    return MemoryInfo(
      dartHeapUsed: dartHeapUsed,
      dartHeapCapacity: dartHeapCapacity,
      externalMemory: externalMemory,
      nativeHeapSize: nativeHeapSize,
      totalMemory: totalMemory,
      availableMemory: availableMemory,
    );
  }

  static Future<void> _connectToVmService() async {
    if (_vmService != null) return;

    try {
      final serviceInfo = await developer.Service.getInfo();
      final serviceUrl = serviceInfo.serverUri;
      if (serviceUrl != null) {
        _vmService = await vmServiceConnectUri(serviceUrl.toString());
      }
    } catch (e) {
      logger.e('Failed to connect to VM service: $e');
    }
  }

  static void logMemoryUsage([String? label]) async {
    if (kDebugMode) {
      final info = await getMemoryInfo();
      print('${label ?? 'Memory Usage'}:\n$info');
    }
  }

  // 获取系统级内存信息
  static Future<Map<String, int>> _getSystemMemoryInfo() async {
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        final result = await _channel.invokeMethod<Map>('getMemoryInfo');
        return Map<String, int>.from(result ?? {});
      } catch (e) {
        logger.e('Failed to get system memory info: $e');
        return {};
      }
    }
    return {};
  }

  // 获取 Dart 内存信息（通过 Platform Channel）
  static Future<Map<String, int>> _getDartMemoryInfo() async {
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        final result = await _channel.invokeMethod<Map>('getDartMemoryInfo');
        return Map<String, int>.from(result ?? {});
      } catch (e) {
        logger.e('Failed to get Dart memory info: $e');
        return {};
      }
    }
    return {};
  }

  // 监控特定代码块的内存使用
  static Future<T> measureMemoryUsage<T>(
    String label,
    Future<T> Function() operation,
  ) async {
    final beforeInfo = await getMemoryInfo();
    logger.d('Before $label:\n$beforeInfo');

    final result = await operation();

    final afterInfo = await getMemoryInfo();
    logger.d('After $label:\n$afterInfo');

    final dartHeapDiff = afterInfo.dartHeapUsed - beforeInfo.dartHeapUsed;
    final externalDiff = afterInfo.externalMemory - beforeInfo.externalMemory;

    logger.d('Memory diff for $label:');
    logger.d('  Dart Heap: ${MemoryInfo._formatBytes(dartHeapDiff)}');
    logger.d('  External: ${MemoryInfo._formatBytes(externalDiff)}');

    return result;
  }

  // 强制垃圾回收（仅用于测试）
  static void forceGC() {
    if (kDebugMode) {
      // 触发垃圾回收
      List.generate(1000000, (i) => i).clear();
      logger.d('Forced garbage collection');
    }
  }

  // 开始持续监控内存（每秒输出一次）
  static Stream<MemoryInfo> startContinuousMonitoring() async* {
    while (true) {
      yield await getMemoryInfo();
      await Future.delayed(const Duration(seconds: 1));
    }
  }
}
