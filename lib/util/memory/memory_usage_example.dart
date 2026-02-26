import 'package:flutter/material.dart';
import 'package:zephyr/main.dart';

import '../../widgets/memory_monitor_widget.dart';
import 'memory_monitor.dart';

// 使用示例：如何在你的应用中集成内存监控

class MemoryUsageExample extends StatelessWidget {
  const MemoryUsageExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MemoryMonitorWidget(
      // 在 debug 模式下显示内存监控覆盖层
      showOverlay: true,
      updateInterval: const Duration(seconds: 1),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('内存监控示例'),
          actions: [
            IconButton(
              icon: const Icon(Icons.memory),
              onPressed: () => _showMemoryDialog(context),
            ),
          ],
        ),
        body: Column(
          children: [
            ElevatedButton(
              onPressed: () => _testMemoryUsage(),
              child: const Text('测试内存使用'),
            ),
            ElevatedButton(
              onPressed: () => _logCurrentMemory(),
              child: const Text('记录当前内存'),
            ),
            ElevatedButton(
              onPressed: () => MemoryMonitor.forceGC(),
              child: const Text('强制垃圾回收'),
            ),
          ],
        ),
      ),
    );
  }

  // 测试内存使用的示例
  Future<void> _testMemoryUsage() async {
    await MemoryMonitor.measureMemoryUsage('Large List Creation', () async {
      // 创建一个大列表来测试内存使用
      final largeList = List.generate(1000000, (i) => 'Item $i');

      // 模拟一些处理
      await Future.delayed(const Duration(milliseconds: 100));

      // 清理
      largeList.clear();
    });
  }

  // 记录当前内存使用
  Future<void> _logCurrentMemory() async {
    MemoryMonitor.logMemoryUsage('Manual Check');
  }

  // 显示详细内存信息对话框
  Future<void> _showMemoryDialog(BuildContext context) async {
    final memoryInfo = await MemoryMonitor.getMemoryInfo();

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('内存使用详情'),
          content: SingleChildScrollView(
            child: Text(
              memoryInfo.toString(),
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        ),
      );
    }
  }
}

// 在你的 main.dart 中使用内存监控的示例
class MyAppWithMemoryMonitoring extends StatelessWidget {
  const MyAppWithMemoryMonitoring({super.key});

  @override
  Widget build(BuildContext context) {
    return MemoryMonitorWidget(
      child: MaterialApp(title: 'Zephyr', home: const MemoryUsageExample()),
    );
  }
}

// 监控特定操作的内存使用示例
class ImageProcessingWithMemoryMonitoring {
  static Future<void> processImagesWithMonitoring(
    List<String> imagePaths,
  ) async {
    await MemoryMonitor.measureMemoryUsage('Image Processing', () async {
      for (final imagePath in imagePaths) {
        await MemoryMonitor.measureMemoryUsage('Process $imagePath', () async {
          // 这里是你的图片处理逻辑
          // 比如调用 Rust 的压缩函数
          await Future.delayed(const Duration(milliseconds: 100)); // 模拟处理
        });
      }
    });
  }
}

// 持续监控内存的示例
class ContinuousMemoryMonitoring {
  static void startMonitoring() {
    MemoryMonitor.startContinuousMonitoring().listen((memoryInfo) {
      // 检查内存使用是否过高
      final dartHeapMB = memoryInfo.dartHeapUsed / (1024 * 1024);

      if (dartHeapMB > 100) {
        // 如果 Dart 堆超过 100MB
        logger.d('警告：Dart 堆内存使用过高: ${dartHeapMB.toStringAsFixed(1)} MB');

        // 可以触发一些清理操作
        MemoryMonitor.forceGC();
      }

      // 记录到日志或发送到分析服务
      _logMemoryToAnalytics(memoryInfo);
    });
  }

  static void _logMemoryToAnalytics(MemoryInfo memoryInfo) {
    logger.d('Memory Analytics: ${memoryInfo.dartHeapUsed} bytes');
  }
}
