import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/main.dart';

import 'http_request.dart';

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
  String raw = "${url.replaceAll(baseUrl, '')}$timestamp$nonce$method$apiKey"
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
    'user-agent': 'okhttp/3.8.1'
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

  headers['image-quality'] = bikaSetting.imageQuality;

  return headers;
}

Future<Map<String, dynamic>> request(
  String url,
  String method, {
  String body = "",
  bool cache = false,
}) async {
  final headers = _getRequestHeaders(
    url,
    method,
    body: body,
  );

  // 根据useCache决定是否添加缓存拦截器
  if (cache) {
    dio.interceptors.add(cacheInterceptor);
  } else {
    dio.interceptors.removeWhere((Interceptor i) => i == cacheInterceptor);
  }

  try {
    final cancelToken = CancelToken();
    Timer(Duration(seconds: 10), () {
      cancelToken.cancel('请求超时');
    });

    final response = await dio.request(
      url,
      data: body.isNotEmpty && (method == 'POST' || method == 'PUT')
          ? body
          : null,
      options: Options(
        method: method,
        headers: headers,
      ),
      cancelToken: cancelToken,
    );

    return response.data;
  } on DioException catch (error) {
    debugPrint(error.toString());

    // 定义基础错误信息
    String errorMessage = 'DioError: ${error.toString()}';

    // 检查错误是否有响应体
    if (error.response != null) {
      // 如果有响应体，尝试解析错误信息
      String responseBody =
          error.response?.data?.toString() ?? 'No response body';
      errorMessage += '\nBody: $responseBody';
    }

    // 如果是掉登录了
    if (error.response?.data?['code'] == 401 &&
            error.response?.data?['message'] == 'unauthorized'
        // && bikaSetting.account.isNotEmpty &&
        // bikaSetting.password.isNotEmpty
        ) {
      // errorMessage += '\n登录状态失效，请重新登录哔咔';
      try {
        var result = await login(bikaSetting.account, bikaSetting.password);

        bikaSetting.setAuthorization(result['data']['token']);
      } catch (e) {
        // 抛出封装后的错误信息
        throw Exception(errorMessage);
      }
    }

    // 抛出封装后的错误信息
    throw Exception(errorMessage);
  } catch (error) {
    debugPrint(error.toString());
    throw Exception('General Error: ${error.toString()}');
  }
}
