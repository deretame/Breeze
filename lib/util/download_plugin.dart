import 'dart:convert';
import 'dart:io';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:path/path.dart' as p;
import 'package:zephyr/main.dart';
import 'package:zephyr/util/get_path.dart';

Future<void> downloadPlugin() async {
  try {
    final updateAccelerate = objectbox.userSettingBox
        .get(1)!
        .globalSetting
        .updateAccelerate;
    await Future.delayed(10.seconds);
    if (updateAccelerate) {
      logger.d("开始检测网络连通性...");
      await dio
          .head('https://gh-proxy.org/')
          .timeout(const Duration(seconds: 5));
      logger.d("网络检查通过，准备获取配置...");
    }

    final baseUrl = updateAccelerate ? 'https://gh-proxy.org/' : '';

    final configUrl =
        '${baseUrl}https://github.com/deretame/Breeze/blob/main/plugin/config.json';
    final configResponse = await dio.get(configUrl);

    final List data = jsonDecode(configResponse.data);
    final basePath = await getFilePath();
    final pluginPath = p.join(basePath, 'plugin');

    for (var element in data) {
      final plugin = element as Map<String, dynamic>;
      final String downloadUrl = updateAccelerate
          ? "https://gh-proxy.org/${plugin['url']}"
          : plugin['url'];
      final String fileName = "${plugin['id']}.js";

      final String savePath = p.join(pluginPath, fileName);

      if (await File(savePath).exists()) {
        await File(savePath).delete();
      }

      logger.d('正在下载插件: ${plugin['name']} -> $savePath');

      await dio.download(downloadUrl, savePath);

      logger.d('插件 ${plugin['name']} 下载完成并已写入数据。');
    }
  } catch (e) {
    logger.d('下载失败: $e');
  }
}
