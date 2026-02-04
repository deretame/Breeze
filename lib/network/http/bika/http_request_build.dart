import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/settings_hive_utils.dart';

import '../../../util/event/event.dart';

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

Map<String, dynamic> _getRequestHeaders(
  String url,
  String method,
  String? body,
  String? imageQuality, [
  String? authorization,
]) {
  var nonce = _getNonce();
  var timestamp = _getCurrentTimestamp();
  var signature = _getSignature(
    url,
    timestamp,
    nonce,
    method,
    "C69BAF41DA5ABD1FFEDC6D2FEA56B",
  );

  int proxy = 0;
  try {
    proxy = SettingsHiveUtils.bikaProxy;
  } catch (e) {
    proxy = 3;
  }

  Map<String, dynamic> headers = {
    'api-key': "C69BAF41DA5ABD1FFEDC6D2FEA56B",
    'accept': 'application/vnd.picacomic.com.v1+json',
    'app-channel': proxy,
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
    'image-quality': imageQuality ?? SettingsHiveUtils.bikaImageQuality,
    'authorization': authorization ?? SettingsHiveUtils.bikaAuthorization,
  };

  return headers;
}

Future<Map<String, dynamic>> request(
  String url,
  String method, {
  String? body,
  bool cache = false,
  String? imageQuality,
  String? authorization,
}) async {
  if (cache) {
    dio.interceptors.add(cacheInterceptor);
  } else {
    dio.interceptors.removeWhere((Interceptor i) => i == cacheInterceptor);
  }

  var cancelToken = CancelToken();

  try {
    String requestUrl = url;

    Timer(Duration(seconds: 20), () {
      if (!cancelToken.isCancelled) {
        cancelToken.cancel('请求超时自动取消');
      }
    });

    final response = await dio.request(
      requestUrl,
      data: body,
      options: Options(
        method: method,
        responseType: ResponseType.bytes,
        headers: _getRequestHeaders(
          url,
          method,
          body,
          imageQuality,
          authorization,
        ),
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
      cancelToken: cancelToken,
    );

    List<int> bytes = response.data as List<int>;

    final contentEncoding = response.headers.value('content-encoding');
    if (contentEncoding != null && contentEncoding.contains('gzip')) {
      bytes = GZipCodec().decode(bytes); // 解压
    }

    // 转换为字符串并解析为 Map
    final String decodedString = utf8.decode(bytes);
    final Map<String, dynamic> result = jsonDecode(decodedString);

    return result;
  } on DioException catch (error) {
    logger.d(error, stackTrace: error.stackTrace);

    Map<String, dynamic>? errorData;
    if (error.response?.data != null && error.response?.data is List<int>) {
      try {
        List<int> errBytes = error.response!.data as List<int>;
        if (error.response!.headers
                .value('content-encoding')
                ?.contains('gzip') ??
            false) {
          errBytes = GZipCodec().decode(errBytes);
        }
        errorData = jsonDecode(utf8.decode(errBytes));
      } catch (_) {}
    }

    // 使用解析后的 errorData 判断登录状态
    if (errorData?['code'] == 401 && errorData?['message'] == 'unauthorized') {
      eventBus.fire(NeedLogin(from: From.bika));
    }

    if (cancelToken.isCancelled) {
      throw Exception('请求超时自动取消');
    }

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
