import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/main.dart';

import '../../page/navigation_bar.dart';

String _getNonce() => Uuid().v4().replaceAll('-', '');

int _getCurrentTimestamp() =>
    (DateTime.now().millisecondsSinceEpoch / 1000).floor();

String _getSignature(
  String url,
  int timestamp,
  String nonce,
  String method,
  String apiKey,
) {
  String baseUrl = "https://picaapi.picacomic.com/";
  String raw =
      "${url.replaceAll(baseUrl, '')}$timestamp$nonce$method$apiKey"
          .toLowerCase();
  String hashKey =
      r"~d}$Q7$eIni=V)9\RK/P.RM4;9[7|@/CA}b~OW!3?EV`:<>M7pddUBL5n|0/*Cn";

  var key = utf8.encode(hashKey);
  var data = utf8.encode(raw);

  var hmacSha256 = Hmac(sha256, key);
  var digest = hmacSha256.convert(data);

  return digest.toString();
}

Map<String, dynamic> _getRequestHeaders(
  String url,
  String method,
  String? body,
  String? imageQuality,
) {
  var nonce = _getNonce();
  var timestamp = _getCurrentTimestamp();
  var signature = _getSignature(
    url,
    timestamp,
    nonce,
    method,
    "C69BAF41DA5ABD1FFEDC6D2FEA56B",
  );

  Map<String, dynamic> headers = {
    'api-key': "C69BAF41DA5ABD1FFEDC6D2FEA56B",
    'accept': 'application/vnd.picacomic.com.v1+json',
    'app-channel': bikaSetting.proxy,
    'time': timestamp,
    'nonce': nonce,
    'signature': signature,
    'app-version': "2.2.1.3.3.4",
    'app-uuid': "defaultUuid",
    'app-platform': "android",
    'app-build-version': "45",
    'accept-encoding': 'gzip',
    'user-agent': 'okhttp/3.8.1',
    'content-type': 'application/json; charset=UTF-8',
    'image-quality': imageQuality ?? bikaSetting.imageQuality,
    'authorization': bikaSetting.authorization,
  };

  return headers;
}

Future<Map<String, dynamic>> request(
  String url,
  String method, {
  String? body,
  bool cache = false,
  String? imageQuality,
}) async {
  if (cache) {
    dio.interceptors.add(cacheInterceptor);
  } else {
    dio.interceptors.removeWhere((Interceptor i) => i == cacheInterceptor);
  }

  try {
    // 使用优选 IP 替换原始域名
    String requestUrl = url;
    // if (cfIpList.isNotEmpty) {
    //   final uri = Uri.parse(url);
    //   requestUrl = url.replaceFirst(
    //     '${uri.scheme}://${uri.host}',
    //     'https://${cfIpList.first}',
    //   );
    //
    //   logger.d('url: $url, requestUrl: $requestUrl');
    //
    //   // 添加 Host 头
    //   headers['Host'] = uri.host;
    // }
    // logger.d(headers);

    final response = await dio.request(
      requestUrl,
      data: body,
      options: Options(
        method: method,
        headers: _getRequestHeaders(url, method, body, imageQuality),
        sendTimeout: const Duration(seconds: 10), // 连接超时时间
        receiveTimeout: const Duration(seconds: 10), // 接收超时时间
      ),
    );

    // logger.d(response.data);

    return response.data;
  } on DioException catch (error) {
    logger.d(error, stackTrace: error.stackTrace);
    // 如果是掉登录了
    if (error.response?.data?['code'] == 401 &&
        error.response?.data?['message'] == 'unauthorized') {
      bikaSetting.deleteAuthorization();
      eventBus.fire(NeedLogin());
    }

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
