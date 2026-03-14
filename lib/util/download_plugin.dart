import 'dart:convert';
import 'dart:io';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:path/path.dart' as p;
import 'package:zephyr/main.dart';
import 'package:zephyr/util/get_path.dart';

Future<void> downloadPlugin() async {
  try {
    await Future.delayed(10.seconds);
    logger.d("开始检测网络连通性...");
    await dio.head('https://gh-proxy.org/').timeout(const Duration(seconds: 5));
    logger.d("网络检查通过，准备获取配置...");

    final configResponse = await dio.get(
      'https://gh-proxy.org/https://github.com/deretame/Breeze/blob/main/plugin/config.json',
    );

    final List data = jsonDecode(configResponse.data);
    final basePath = await getFilePath();
    final pluginPath = p.join(basePath, 'plugin');

    for (var element in data) {
      final plugin = element as Map<String, dynamic>;
      final String downloadUrl = plugin['url'];
      final String fileName = "${plugin['id']}.js";

      final String savePath = p.join(pluginPath, fileName);

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
