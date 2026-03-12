import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/services.dart';
import 'package:zephyr/config/jm/config.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/bika/pica_client.dart';
import 'package:zephyr/network/http/jm/jm_client.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/src/rust/api/qjs.dart';
import 'package:zephyr/util/download/cancel_token.dart' as task_cancel;

class _SpeedResult {
  final String url;
  final int? durationMs;

  _SpeedResult({required this.url, this.durationMs});
}

Future<_SpeedResult> _testUrlSpeed(
  Dio dio,
  String url, {
  task_cancel.CancelToken? cancelToken,
}) async {
  final stopwatch = Stopwatch()..start();
  try {
    cancelToken?.throwIfCancelled();

    final dioCancelToken = CancelToken();
    if (cancelToken != null) {
      cancelToken.future.then((_) {
        if (!dioCancelToken.isCancelled) {
          dioCancelToken.cancel('user cancelled');
        }
      });
    }

    await dio.head(
      url,
      options: Options(
        sendTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
      cancelToken: dioCancelToken,
    );
    stopwatch.stop();
    return _SpeedResult(url: url, durationMs: stopwatch.elapsedMilliseconds);
  } catch (e) {
    if (e is DioException && e.type == DioExceptionType.cancel) {
      cancelToken?.throwIfCancelled();
    }
    return _SpeedResult(url: url, durationMs: null);
  }
}

Future<int> getFastestUrlIndex(
  List<String> urls, {
  task_cancel.CancelToken? cancelToken,
}) async {
  if (urls.isEmpty) {
    return 0;
  }

  final testFutures = urls
      .map((url) => _testUrlSpeed(dio, url, cancelToken: cancelToken))
      .toList();

  final results = await Future.wait(testFutures);

  cancelToken?.throwIfCancelled();

  final successfulResults = results.where((r) => r.durationMs != null).toList();

  if (successfulResults.isEmpty) {
    return 0;
  }

  final fastestResult = successfulResults.reduce(
    (current, next) => current.durationMs! < next.durationMs! ? current : next,
  );

  return urls.indexOf(fastestResult.url);
}

Future<void> setFastestUrlIndex({task_cancel.CancelToken? cancelToken}) async {
  final index = await getFastestUrlIndex(
    JmConfig.baseUrls,
    cancelToken: cancelToken,
  );
  logger.d('Fastest URL index: $index');
  JmConfig.setBaseUrlIndex(index);
}

Future<void> setFastestImagesUrlIndex({
  task_cancel.CancelToken? cancelToken,
}) async {
  final index = await getFastestUrlIndex(
    JmConfig.imagesUrls,
    cancelToken: cancelToken,
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
      final dioInstances = [JmClient().dio, pictureDio, dio, PicaClient().dio];
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
