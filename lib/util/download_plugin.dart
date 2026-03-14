import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:zephyr/main.dart';
import 'package:zephyr/util/get_path.dart';

Future<void> downloadPlugin() async {
  try {
    logger.d("开始检测网络连通性...");
    await dio.head('https://gh-proxy.org/').timeout(const Duration(seconds: 5));
    logger.d("网络检查通过，准备获取配置...");

    final configResponse = await dio.get(
      'https://gh-proxy.org/https://github.com/deretame/Breeze/blob/main/plugin/config.json',
    );

    final List data = jsonDecode(configResponse.data);
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
