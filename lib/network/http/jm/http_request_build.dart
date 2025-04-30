import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:encrypter_plus/encrypter_plus.dart';
import 'package:zephyr/type/pipe.dart';

import '../../../config/jm/config.dart';
import '../../../main.dart';

final jmDio = Dio();

String getTime() =>
    (DateTime
        .now()
        .millisecondsSinceEpoch ~/ 1000).toString();

String jmUA() {
  if (JmConfig.device.isEmpty) {
    var chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    var random = Random();
    for (var i = 0; i < 9; i++) {
      JmConfig.device += chars[random.nextInt(chars.length)];
    }
  }
  return 'Mozilla/5.0 (Linux; Android 13; ${JmConfig
      .device} Build/TQ1A.230305.002; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/114.0.5735.196 Safari/537.36';
}

Map<String, dynamic> getHeader(String time,
    bool post,
    Map<String, dynamic>? headers,) {
  var token = md5.convert(utf8.encode('$time${JmConfig.jmVersion}'));
  return {
    'token': token.toString(),
    'tokenparam': '$time,${JmConfig.jmVersion}',
    'use-agent': jmUA,
    'accpet-encoding': 'gzip',
    'Host': JmConfig.baseUrl.replaceAll('https://', ''),
    ...headers ?? {},
    if (post) 'Content-Type': 'application/x-www-form-urlencoded',
  };
}

Map<String, dynamic> decodeRespData(String data, String ts, [String? secret]) {
  final actualSecret = secret ?? JmConfig.kJmSecret;

  // 1. Base64解码
  final dataB64 = base64.decode(data);

  // 2. AES-ECB解密
  final key = md5.convert(utf8.encode('$ts$actualSecret')).toString();
  final encrypter = Encrypter(AES(Key(utf8.encode(key)), mode: AESMode.ecb));
  final dataAes = encrypter.decryptBytes(Encrypted(dataB64));

  // 3. 解码为字符串 (json)并转化为Map
  return json.decode(utf8.decode(dataAes));
}

Future<Map<String, dynamic>> request(String url, {
  String? body,
  String method = 'GET',
  Map<String, dynamic>? headers,
  Map<String, dynamic>? params,
  bool byte = true,
  bool cache = false,
}) async {
  final timestamp = getTime();

  if (cache) {
    jmDio.interceptors.add(cacheInterceptor);
  } else {
    jmDio.interceptors.removeWhere((Interceptor i) => i == cacheInterceptor);
  }

  jmDio.interceptors.add(CookieManager(JmConfig.cookieJar));

  try {
    return await jmDio
        .request(
      url,
      data: body,
      queryParameters: params,
      options: Options(
        method: method,
        headers: getHeader(timestamp, method == 'POST', headers),
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        responseType: byte ? ResponseType.bytes : null,
      ),
    )
        .pipe((var res) => res.data as List<int>)
        .pipe(utf8.decode)
        .pipe(jsonDecode)
        .pipe((var d) => decodeRespData(d['data'], timestamp));
  } on DioException catch (error) {
    logger.d(error, stackTrace: error.stackTrace);

    // 抛出封装后的错误信息
    _handleDioError(error).pipe((var e) => throw Exception(e));
  } catch (e, s) {
    logger.e(e, stackTrace: s);
    rethrow;
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
