import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:zephyr/config/jm/config.dart';
import 'package:zephyr/main.dart';

class _SpeedResult {
  final String url;
  final int? durationMs;

  _SpeedResult({required this.url, this.durationMs});
}

Future<_SpeedResult> _testUrlSpeed(Dio dio, String url) async {
  final stopwatch = Stopwatch()..start();
  try {
    await dio.head(
      url,
      options: Options(
        sendTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );
    stopwatch.stop();
    return _SpeedResult(url: url, durationMs: stopwatch.elapsedMilliseconds);
  } catch (e) {
    return _SpeedResult(url: url, durationMs: null);
  }
}

Future<int> getFastestUrlIndex(List<String> urls) async {
  if (urls.isEmpty) {
    return 0;
  }

  final testFutures = urls.map((url) => _testUrlSpeed(dio, url)).toList();

  final results = await Future.wait(testFutures);

  final successfulResults = results.where((r) => r.durationMs != null).toList();

  if (successfulResults.isEmpty) {
    return 0;
  }

  final fastestResult = successfulResults.reduce(
    (current, next) => current.durationMs! < next.durationMs! ? current : next,
  );

  return urls.indexOf(fastestResult.url);
}

Future<void> setFastestUrlIndex() async {
  final index = await getFastestUrlIndex(JmConfig.baseUrls);
  logger.d('Fastest URL index: $index');
  JmConfig.setBaseUrlIndex(index);
}

Future<void> setFastestImagesUrlIndex() async {
  final index = await getFastestUrlIndex(JmConfig.imagesUrls);
  logger.d('Fastest images URL index: $index');
  JmConfig.setImagesUrlIndex(index);
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
