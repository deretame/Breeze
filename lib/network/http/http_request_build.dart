import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/widgets/toast.dart';

import '../../page/main.dart';

String _getNonce() {
  return const Uuid().v4().replaceAll('-', '');
}

int _getCurrentTimestamp() {
  return (DateTime.now().millisecondsSinceEpoch / 1000).floor();
}

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

Map<String, String> _getRequestHeaders(
  String url,
  String method, {
  String body = "",
  String imageQuality = "",
}) {
  String? authorization = bikaSetting.authorization;
  String nonce = _getNonce();
  int timestamp = _getCurrentTimestamp();
  String signature = _getSignature(
    url,
    timestamp,
    nonce,
    method,
    "C69BAF41DA5ABD1FFEDC6D2FEA56B",
  );

  Map<String, String> headers = {
    'api-key': "C69BAF41DA5ABD1FFEDC6D2FEA56B",
    'accept': 'application/vnd.picacomic.com.v1+json',
    'app-channel': bikaSetting.getProxy().toString(),
    'time': timestamp.toString(),
    'nonce': nonce,
    'signature': signature,
    'app-version': "2.2.1.3.3.4",
    'app-uuid': "defaultUuid",
    'app-platform': "android",
    'app-build-version': "45",
    'accept-encoding': 'gzip',
    'user-agent': 'okhttp/3.8.1',
  };

  if ((method == 'POST' || method == 'PUT')) {
    if (body.isNotEmpty) {
      headers['Content-Length'] = utf8.encode(body).length.toString();
      headers['content-type'] = 'application/json; charset=UTF-8';
    } else {
      headers['Content-Length'] = '0';
    }
  }

  if (authorization.isNotEmpty &&
      !url.contains('/auth/sign-in') &&
      !url.contains('/auth/register')) {
    headers['authorization'] = authorization;
  }

  headers['image-quality'] =
      imageQuality.isEmpty ? bikaSetting.imageQuality : imageQuality;

  return headers;
}

Future<Map<String, dynamic>> request(
  String url,
  String method, {
  String body = "",
  bool cache = false,
  String imageQuality = "",
}) async {
  final headers = _getRequestHeaders(
    url,
    method,
    body: body,
    imageQuality: imageQuality,
  );

  // 根据useCache决定是否添加缓存拦截器
  if (cache) {
    dio.interceptors.add(cacheInterceptor);
  } else {
    dio.interceptors.removeWhere((Interceptor i) => i == cacheInterceptor);
  }

  final data =
      body.isNotEmpty && (method == 'POST' || method == 'PUT') ? body : null;

  try {
    final response = await dio.request(
      url,
      data: data,
      options: Options(
        method: method,
        headers: headers,
        sendTimeout: const Duration(seconds: 10), // 连接超时时间
        receiveTimeout: const Duration(seconds: 10), // 接收超时时间
      ),
    );

    return response.data;
  } on DioException catch (error) {
    // 如果是掉登录了
    if (error.response?.data?['code'] == 401 &&
        error.response?.data?['message'] == 'unauthorized') {
      bikaSetting.deleteAuthorization();
      showErrorToast('登录失效，请重新登录');
      eventBus.fire(NeedLogin());
    }

    // 抛出封装后的错误信息
    throw Exception(_handleDioError(error));
  } catch (error) {
    throw Exception('General Error: ${error.toString()}');
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
      return error.response?.data?['message'] ??
          '服务器返回错误状态码: ${error.response?.statusCode}';
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
