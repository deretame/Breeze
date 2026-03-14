import 'dart:io';

import 'package:zephyr/main.dart';
import 'package:zephyr/util/get_path.dart';
import 'package:path/path.dart' as p;

Future<void> downloadPlugin() async {
  try {
    final configResponse = await dio.get(
      'https://cdn.jsdelivr.net/gh/deretame/Breeze@main/plugin/config.json',
    );

    final List data = configResponse.data;
    final String basePath = await getFilePath();

    for (var element in data) {
      final plugin = element as Map<String, dynamic>;
      final String downloadUrl = plugin['url'];
      final String fileName = plugin['main'];

      final String savePath = p.join(basePath, fileName);

      if (await File(savePath).exists()) {
        await File(savePath).delete();
      }

      logger.d('正在下载插件: ${plugin['name']} -> $savePath');

      await dio.download(
        downloadUrl,
        savePath,
        onReceiveProgress: (count, total) {
          if (total != -1) {
            logger.d("${(count / total * 100).toStringAsFixed(0)}%");
          }
        },
      );

      logger.d('插件 ${plugin['name']} 下载完成并已写入数据。');
    }
  } catch (e) {
    logger.d('下载失败: $e');
  }
}
