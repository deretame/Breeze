import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:zephyr/config/jm/config.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/jm/http_request.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/src/rust/api/qjs.dart';
import 'package:zephyr/util/direct_dio.dart';

const _kQjsRuntimeCancelled = '__QJS_RUNTIME_CANCELLED__';
const _kDownloadTaskCancelled = '__DOWNLOAD_TASK_CANCELLED__';

Future<int> _getFastestUrlIndexByQjs(
  List<String> urls, {
  String qjsRuntimeName = 'jmComic',
}) async {
  final argsJson = jsonEncode([urls]);

  final raw = kDebugMode
      ? await qjsCallOnce(
          runtimeName: qjsRuntimeName,
          bundleJs: (await directDio.get(await jmJsUrl)).data,
          fnPath: 'getFastestUrlIndex',
          argsJson: argsJson,
        )
      : await qjsCall(
          runtimeName: qjsRuntimeName,
          fnPath: 'getFastestUrlIndex',
          argsJson: argsJson,
        );

  final decoded = jsonDecode(raw);
  if (decoded is int) {
    return decoded;
  }
  if (decoded is num) {
    return decoded.toInt();
  }
  return 0;
}

Future<int> getFastestUrlIndex(
  List<String> urls, {
  String qjsRuntimeName = 'jmComic',
}) async {
  if (urls.isEmpty) {
    return 0;
  }

  try {
    final index = await _getFastestUrlIndexByQjs(
      urls,
      qjsRuntimeName: qjsRuntimeName,
    );
    if (index < 0 || index >= urls.length) {
      return 0;
    }
    return index;
  } catch (e, s) {
    if (_isQjsRuntimeCancelledError(e)) {
      throw Exception(_kDownloadTaskCancelled);
    }
    logger.e('QJS 测速失败，回退默认线路', error: e, stackTrace: s);
    return 0;
  }
}

bool _isQjsRuntimeCancelledError(Object error) {
  return error.toString().contains(_kQjsRuntimeCancelled);
}

Future<void> setFastestUrlIndex({String qjsRuntimeName = 'jmComic'}) async {
  final index = await getFastestUrlIndex(
    JmConfig.baseUrls,
    qjsRuntimeName: qjsRuntimeName,
  );
  logger.d('Fastest URL index: $index');
  JmConfig.setBaseUrlIndex(index);
}

Future<void> setFastestImagesUrlIndex({
  String qjsRuntimeName = 'jmComic',
}) async {
  final index = await getFastestUrlIndex(
    JmConfig.imagesUrls,
    qjsRuntimeName: qjsRuntimeName,
  );
  logger.d('Fastest images URL index: $index');
  JmConfig.setImagesUrlIndex(index);
}

Future<void> enableProxy() async {
  try {
    final content = await rootBundle.loadString('.env.proxy');
    String? proxyUrl;
    final lines = const LineSplitter().convert(content);

    for (var line in lines) {
      line = line.trim();
      if (line.isNotEmpty &&
          !line.startsWith('#') &&
          line.startsWith('proxy=')) {
        String value = line.substring('proxy='.length);
        proxyUrl = value.trim().replaceAll('"', '').replaceAll("'", "");
        break;
      }
    }
    if (proxyUrl != null &&
        proxyUrl.isNotEmpty &&
        await isProxyAvailable(proxyUrl)) {
      final dioInstances = [pictureDio, dio];
      for (var instance in dioInstances) {
        configProxy(instance, proxyUrl);
      }
      setHttpProxy(proxy: proxyUrl);
      logger.d("🚀 [Debug] 已从 .env.proxy 加载代理: $proxyUrl");
    }
  } catch (e) {
    logger.e("无法读取代理文件 (Asset not found): $e");
  }
}

void configProxy(Dio dio, String proxy) {
  // 获取 adapter (Dio 5.0+ 的写法)
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();

      client.findProxy = (uri) {
        return 'PROXY $proxy';
      };
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

      return client;
    },
  );
}

Future<bool> isProxyAvailable(String proxyUrl) async {
  try {
    final client = HttpClient();

    client.findProxy = (uri) {
      return "PROXY $proxyUrl";
    };

    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;

    client.connectionTimeout = const Duration(seconds: 3);

    final request = await client.getUrl(
      Uri.parse('http://connect.rom.miui.com/generate_204'),
    );

    final response = await request.close();

    if (response.statusCode < 400) {
      logger.d("代理测试成功，响应码: ${response.statusCode}");
      client.close();
      return true;
    } else {
      logger.w("代理响应了错误码: ${response.statusCode}");
      client.close();
      return false;
    }
  } catch (e) {
    logger.e("代理连接彻底失败: $e");
    return false;
  }
}
