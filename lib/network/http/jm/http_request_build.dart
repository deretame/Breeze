import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import '../../../config/jm/config.dart';
import '../../../main.dart';

String get jmUA {
  if (JmConfig.device.isEmpty) {
    var chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    var random = Random();
    for (var i = 0; i < 9; i++) {
      JmConfig.device += chars[random.nextInt(chars.length)];
    }
  }
  return 'Mozilla/5.0 (Linux; Android 13; ${JmConfig.device} Build/TQ1A.230305.002; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/114.0.5735.196 Safari/537.36';
}

Map<String, dynamic> getHeader(
  int time, {
  bool post = false,
  Map<String, dynamic>? headers,
}) {
  var token = md5.convert(utf8.encode('$time${JmConfig.jmVersion}'));
  return {
    'token': token.toString(),
    'tokenparam': '$time,${JmConfig.jmVersion}',
    'use-agent': jmUA,
    'accpet-encoding': 'gzip',
    'Host': JmConfig.baseUrls[0].replaceFirst('https://', ''),
    ...headers ?? {},
    if (post) 'Content-Type': 'application/x-www-form-urlencoded',
  };
}

Future<Map<String, dynamic>> request(
  int time,
  String url, {
  String? body,
  String method = 'GET',
  Map<String, dynamic>? headers,
  Map<String, dynamic>? params,
  bool byte = true,
  bool cache = false,
}) async {
  if (cache) {
    dio.interceptors.add(cacheInterceptor);
  } else {
    dio.interceptors.removeWhere((Interceptor i) => i == cacheInterceptor);
  }

  try {
    final response = await dio.request(
      url,
      data: body,
      queryParameters: params,
      options: Options(
        method: method,
        headers: getHeader(time, post: method == 'POST', headers: headers),
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        responseType: byte ? ResponseType.bytes : null,
      ),
    );

    // logger.d(response.data);

    return response.data;
  } on DioException catch (error) {
    logger.d(error, stackTrace: error.stackTrace);

    // 抛出封装后的错误信息
    throw Exception(_handleDioError(error));
  }
}

String _handleDioError(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
      return '连接服务器超时（${error.requestOptions.connectTimeout}秒）';
    case DioExceptionType.sendTimeout:
      return '请求发送超时（${error.requestOptions.sendTimeout}秒）';
    case DioExceptionType.receiveTimeout:
      return '响应接收超时（${error.requestOptions.receiveTimeout}秒）';
    case DioExceptionType.badResponse:
      return error.response?.toString() ?? '未知错误';
    case DioExceptionType.cancel:
      return '请求被取消';
    case DioExceptionType.connectionError:
      return '网络连接失败，请检查网络';
    case DioExceptionType.unknown:
      return error.error?.toString() ?? '未知网络错误';
    case DioExceptionType.badCertificate:
      return '证书验证失败';
  }
}
