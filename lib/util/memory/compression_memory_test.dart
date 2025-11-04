import 'package:flutter/foundation.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/src/rust/api/simple.dart';

import '../../src/rust/compressed/compressed.dart';
import 'combined_memory_monitor.dart';
import 'rust_memory_monitor.dart';

/// 压缩操作的内存测试工具
class CompressionMemoryTest {
  /// 测试 TAR 压缩的内存使用
  static Future<void> testTarCompression(
    PackInfo packInfo,
    String destPath,
  ) async {
    if (!kDebugMode) return;

    await CombinedMemoryMonitor.measureCompleteMemoryUsage(
      'TAR Compression',
      () async {
        await packFolder(destPath: destPath, packInfo: packInfo);
      },
    );
  }

  /// 测试 ZIP 压缩的内存使用
  static Future<void> testZipCompression(
    PackInfo packInfo,
    String destPath,
  ) async {
    if (!kDebugMode) return;

    await CombinedMemoryMonitor.measureCompleteMemoryUsage(
      'ZIP Compression',
      () async {
        await packFolderZip(destPath: destPath, packInfo: packInfo);
      },
    );
  }

  /// 比较 TAR 和 ZIP 压缩的内存使用
  static Future<void> compareCompressionMethods(
    PackInfo packInfo,
    String tarPath,
    String zipPath,
  ) async {
    if (!kDebugMode) return;

    logger.d('=== Compression Memory Comparison ===');

    // 测试 TAR
    logger.d('\n--- Testing TAR Compression ---');
    await testTarCompression(packInfo, tarPath);

    // 等待一下让内存稳定
    await Future.delayed(const Duration(seconds: 2));

    // 测试 ZIP
    logger.d('\n--- Testing ZIP Compression ---');
    await testZipCompression(packInfo, zipPath);

    logger.d('\n=== Comparison Complete ===');
  }

  /// 测试图片压缩的内存使用
  static Future<String> testImageCompression(List<int> imageBytes) async {
    if (!kDebugMode) {
      return await compressImage(imageBytes: imageBytes);
    }

    return await RustMemoryMonitor.measureRustMemoryUsage(
      'Image Compression',
      () async {
        return await compressImage(imageBytes: imageBytes);
      },
    );
  }

  /// 批量测试多个图片压缩的内存使用
  static Future<List<String>> testBatchImageCompression(
    List<List<int>> imageBatchBytes,
  ) async {
    if (!kDebugMode) {
      final results = <String>[];
      for (final imageBytes in imageBatchBytes) {
        results.add(await compressImage(imageBytes: imageBytes));
      }
      return results;
    }

    return await CombinedMemoryMonitor.measureCompleteMemoryUsage(
      'Batch Image Compression',
      () async {
        final results = <String>[];

        for (int i = 0; i < imageBatchBytes.length; i++) {
          final imageBytes = imageBatchBytes[i];
          logger.d('Processing image ${i + 1}/${imageBatchBytes.length}');

          final compressed = await RustMemoryMonitor.measureRustMemoryUsage(
            'Image $i',
            () async {
              return await compressImage(imageBytes: imageBytes);
            },
          );

          results.add(compressed);

          // 每处理几张图片记录一次内存状态
          if ((i + 1) % 5 == 0) {
            await CombinedMemoryMonitor.logCompleteMemoryUsage(
              'After ${i + 1} images',
            );
          }
        }

        return results;
      },
    );
  }

  /// 内存压力测试 - 创建大量数据来测试内存管理
  static Future<void> memoryStressTest() async {
    if (!kDebugMode) return;

    logger.d('=== Memory Stress Test ===');

    await CombinedMemoryMonitor.measureCompleteMemoryUsage(
      'Memory Stress Test',
      () async {
        // 创建一些大的数据结构来测试内存跟踪
        final largeData = List.generate(1000000, (i) => i.toString());

        // 模拟一些内存密集的操作
        for (int i = 0; i < 10; i++) {
          final _ = largeData.sublist(i * 100000, (i + 1) * 100000);
          await Future.delayed(const Duration(milliseconds: 100));

          if (i % 3 == 0) {
            await RustMemoryMonitor.logRustMemoryUsage(
              'Stress test iteration $i',
            );
          }
        }

        // 清理
        largeData.clear();
      },
    );
  }
}
