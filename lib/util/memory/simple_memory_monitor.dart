import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:zephyr/main.dart';

/// 简化的内存监控器，更可靠但功能较少
class SimpleMemoryMonitor {
  static const MethodChannel _channel = MethodChannel('memory_monitor');

  /// 获取基本内存信息
  static Future<SimpleMemoryInfo> getMemoryInfo() async {
    Map<String, int> systemMemory = {};
    Map<String, int> dartMemory = {};

    // 移动端：通过平台通道获取（iOS/Android）
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        final result = await _channel.invokeMethod<Map>('getMemoryInfo');
        systemMemory = Map<String, int>.from(result ?? {});
      } catch (e) {
        if (kDebugMode) logger.e('Failed to get system memory: $e');
      }

      try {
        final result = await _channel.invokeMethod<Map>('getDartMemoryInfo');
        dartMemory = Map<String, int>.from(result ?? {});
      } catch (e) {
        if (kDebugMode) logger.e('Failed to get Dart memory: $e');
      }
    }

    // 桌面端：通过系统接口获取（Windows/Linux/macOS）
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      try {
        final desktopSystem = await _getDesktopSystemMemory();
        if (desktopSystem.isNotEmpty) {
          systemMemory.addAll(desktopSystem);
        }
      } catch (e) {
        if (kDebugMode) logger.e('Failed to get desktop system memory: $e');
      }

      final desktopRuntime = _getDesktopRuntimeMemory(systemMemory);
      if (desktopRuntime.isNotEmpty) {
        dartMemory.addAll(desktopRuntime);
      }
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

  // 桌面端系统内存信息
  static Future<Map<String, int>> _getDesktopSystemMemory() async {
    if (Platform.isWindows) {
      return _getWindowsSystemMemory();
    }
    if (Platform.isLinux) {
      return _getLinuxSystemMemory();
    }
    if (Platform.isMacOS) {
      return _getMacOsSystemMemory();
    }
    return {};
  }

  // 桌面端运行时内存（基于当前进程 RSS 的近似值）
  static Map<String, int> _getDesktopRuntimeMemory(
    Map<String, int> systemMemory,
  ) {
    final rss = ProcessInfo.currentRss;
    if (rss <= 0) {
      return {};
    }

    final systemTotal = systemMemory['totalMemory'] ?? 0;
    final runtimeTotal = systemTotal > 0 ? systemTotal : rss;
    final runtimeFree = runtimeTotal > rss ? runtimeTotal - rss : 0;

    return {
      'dartHeapUsed': rss,
      'dartHeapCapacity': rss,
      'dartHeapCommitted': rss,
      'nativeHeapSize': rss,
      'nativeHeapAllocated': rss,
      'maxMemory': runtimeTotal,
      'totalMemory': runtimeTotal,
      'freeMemory': runtimeFree,
      'usedMemory': rss,
    };
  }

  // Windows: 优先 PowerShell，其次 WMIC
  static Future<Map<String, int>> _getWindowsSystemMemory() async {
    final byPowerShell = await _getWindowsSystemMemoryByPowerShell();
    if (byPowerShell.isNotEmpty) {
      return byPowerShell;
    }
    return _getWindowsSystemMemoryByWmic();
  }

  static Future<Map<String, int>> _getWindowsSystemMemoryByPowerShell() async {
    try {
      const script =
          '(Get-CimInstance Win32_OperatingSystem | Select-Object TotalVisibleMemorySize,FreePhysicalMemory | ConvertTo-Json -Compress)';
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-Command',
        script,
      ]);

      if (result.exitCode != 0) {
        return {};
      }

      final output = result.stdout.toString().trim();
      if (output.isEmpty) {
        return {};
      }

      final dynamic decoded = jsonDecode(output);
      if (decoded is! Map) {
        return {};
      }

      final totalKb = _parseLooseInt(
        decoded['TotalVisibleMemorySize']?.toString(),
      );
      final freeKb = _parseLooseInt(decoded['FreePhysicalMemory']?.toString());

      if (totalKb <= 0 || freeKb < 0) {
        return {};
      }

      return {'totalMemory': totalKb * 1024, 'availableMemory': freeKb * 1024};
    } catch (_) {
      return {};
    }
  }

  static Future<Map<String, int>> _getWindowsSystemMemoryByWmic() async {
    try {
      final result = await Process.run('wmic', [
        'OS',
        'get',
        'TotalVisibleMemorySize,FreePhysicalMemory',
        '/Value',
      ]);

      if (result.exitCode != 0) {
        return {};
      }

      final lines = result.stdout.toString().split(RegExp(r'\r?\n'));
      int totalKb = 0;
      int freeKb = 0;

      for (final line in lines) {
        if (line.startsWith('TotalVisibleMemorySize=')) {
          totalKb = _parseLooseInt(line.split('=').last);
        } else if (line.startsWith('FreePhysicalMemory=')) {
          freeKb = _parseLooseInt(line.split('=').last);
        }
      }

      if (totalKb <= 0 || freeKb < 0) {
        return {};
      }

      return {'totalMemory': totalKb * 1024, 'availableMemory': freeKb * 1024};
    } catch (_) {
      return {};
    }
  }

  // Linux: 读取 /proc/meminfo
  static Future<Map<String, int>> _getLinuxSystemMemory() async {
    try {
      final file = File('/proc/meminfo');
      if (!await file.exists()) {
        return {};
      }

      final lines = await file.readAsLines();
      int totalKb = 0;
      int availableKb = 0;
      int freeKb = 0;
      int buffersKb = 0;
      int cachedKb = 0;

      for (final line in lines) {
        if (line.startsWith('MemTotal:')) {
          totalKb = _parseLooseInt(line);
        } else if (line.startsWith('MemAvailable:')) {
          availableKb = _parseLooseInt(line);
        } else if (line.startsWith('MemFree:')) {
          freeKb = _parseLooseInt(line);
        } else if (line.startsWith('Buffers:')) {
          buffersKb = _parseLooseInt(line);
        } else if (line.startsWith('Cached:')) {
          cachedKb = _parseLooseInt(line);
        }
      }

      if (availableKb <= 0) {
        availableKb = freeKb + buffersKb + cachedKb;
      }

      if (totalKb <= 0 || availableKb < 0) {
        return {};
      }

      return {
        'totalMemory': totalKb * 1024,
        'availableMemory': availableKb * 1024,
      };
    } catch (_) {
      return {};
    }
  }

  // macOS: sysctl + vm_stat
  static Future<Map<String, int>> _getMacOsSystemMemory() async {
    try {
      final totalResult = await Process.run('sysctl', ['-n', 'hw.memsize']);
      if (totalResult.exitCode != 0) {
        return {};
      }

      final totalBytes = _parseLooseInt(totalResult.stdout.toString());
      if (totalBytes <= 0) {
        return {};
      }

      int availableBytes = 0;
      final vmStatResult = await Process.run('vm_stat', []);
      if (vmStatResult.exitCode == 0) {
        availableBytes = _parseMacOsAvailableMemory(
          vmStatResult.stdout.toString(),
        );
      }

      return {'totalMemory': totalBytes, 'availableMemory': availableBytes};
    } catch (_) {
      return {};
    }
  }

  static int _parseMacOsAvailableMemory(String vmStatOutput) {
    final pageSizeMatch = RegExp(
      r'page size of\s+(\d+)\s+bytes',
      caseSensitive: false,
    ).firstMatch(vmStatOutput);
    final pageSize = _parseLooseInt(pageSizeMatch?.group(1));
    if (pageSize <= 0) {
      return 0;
    }

    final freePages = _readVmStatPages(vmStatOutput, 'Pages free');
    final inactivePages = _readVmStatPages(vmStatOutput, 'Pages inactive');
    final speculativePages = _readVmStatPages(
      vmStatOutput,
      'Pages speculative',
    );
    final availablePages = freePages + inactivePages + speculativePages;

    if (availablePages <= 0) {
      return 0;
    }

    return availablePages * pageSize;
  }

  static int _readVmStatPages(String text, String key) {
    final match = RegExp('$key:\\s+([0-9\\.,]+)').firstMatch(text);
    return _parseLooseInt(match?.group(1));
  }

  static int _parseLooseInt(String? input) {
    if (input == null || input.isEmpty) {
      return 0;
    }

    final digitsOnly = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return 0;
    }

    return int.tryParse(digitsOnly) ?? 0;
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
