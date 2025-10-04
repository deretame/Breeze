import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:encrypter_plus/encrypter_plus.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/event/event.dart';

import '../../../config/jm/config.dart';
import '../../../main.dart';
import '../../dio_cache.dart';

final jmDio = Dio();

final netCache = SimpleCacheService();

String jmUA() {
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
  String time,
  bool post,
  Map<String, dynamic>? headers,
) {
  return {
    'token': JmConfig.token,
    'tokenparam': '$time,${JmConfig.jmVersion}',
    'user-agent': jmUA(),
    'Host': JmConfig.baseUrl.replaceAll('https://', ''),
    ...headers ?? {},
    if (post) 'Content-Type': 'application/x-www-form-urlencoded',
  };
}

dynamic decodeRespData(String data, String ts, [String? secret]) {
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

Future<dynamic> request(
  String url, {
  String? body,
  String method = 'GET',
  Map<String, dynamic>? headers,
  Map<String, dynamic>? params,
  bool byte = true,
  bool cache = false,
}) async {
  var timestamp = JmConfig.timestamp;
  dynamic result;

  if (params != null) {
    url = "$url${_mapToUrlParams(params)}";
  }

  if (url.contains("/daily_list/filter")) {
    timestamp =
        (DateTime.now().millisecondsSinceEpoch / 1000).floor().toString();
  }

  if (cache) {
    result = netCache.get(url);
    if (result != null) {
      return result;
    }
  }

  var cancelToken = CancelToken();

  Timer(Duration(seconds: 20), () {
    if (!cancelToken.isCancelled) {
      cancelToken.cancel('请求超时自动取消');
    }
  });

  try {
    result = await jmDio
        .request(
          url,
          data: body,
          options: Options(
            method: method,
            headers: getHeader(timestamp, method == 'POST', headers),
            sendTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            responseType: byte ? ResponseType.bytes : null,
          ),
          cancelToken: cancelToken,
        )
        .let((res) => res.data as List<int>)
        .let(utf8.decode)
        .let(jsonDecode)
        .let((var d) => decodeRespData(d['data'], timestamp));
    if (cache) {
      netCache.set(url, result);
    }
    return result;
  } on DioException catch (error) {
    logger.d(error, stackTrace: error.stackTrace);

    if (cancelToken.isCancelled) {
      throw Exception('请求超时自动取消');
    }

    // 抛出封装后的错误信息
    throw Exception(_handleDioError(error));
  } catch (e, s) {
    logger.e(e, stackTrace: s);
    throw Exception(e);
  }
}

String _mapToUrlParams(
  Map<String, dynamic>? params, {
  bool includeQuestionMark = true,
}) {
  if (params == null || params.isEmpty) {
    return '';
  }
  final buffer = StringBuffer();
  if (includeQuestionMark) {
    buffer.write('?');
  }
  var first = true;

  void addParam(String key, String value) {
    if (!first) {
      buffer.write('&');
    }
    buffer.write(Uri.encodeQueryComponent(key));
    buffer.write('=');
    buffer.write(Uri.encodeQueryComponent(value));
    first = false;
  }

  params.forEach((key, value) {
    if (value == null) {
      return;
    }
    if (value is List) {
      for (var item in value) {
        if (item != null) {
          addParam(key, item.toString());
        }
      }
    } else if (value is Map) {
      // 对于嵌套的Map，可以展平处理，这里简单转为JSON字符串
      addParam(key, jsonEncode(value));
    } else if (value is DateTime) {
      addParam(key, value.toIso8601String());
    } else {
      addParam(key, value.toString());
    }
  });
  return buffer.toString();
}

String _handleDioError(DioException error) {
  String message = '';
  if (error.response != null) {
    message = (error.response!.data as List<int>).let(utf8.decode);
    logger.d(message);
  }

  try {
    if (message.let(jsonDecode)['errorMsg'] == '請先登入會員' &&
        message.let(jsonDecode)['code'] == 401) {
      eventBus.fire(NeedLogin(from: From.jm));
      return '登录过期，请重新登录';
    }
  } catch (e) {
    logger.e(e);
  }

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
      return '连接服务器超时（${error.requestOptions.connectTimeout}秒）';
    case DioExceptionType.sendTimeout:
      return '请求发送超时（${error.requestOptions.sendTimeout}秒）';
    case DioExceptionType.receiveTimeout:
      return '响应接收超时（${error.requestOptions.receiveTimeout}秒）';
    case DioExceptionType.badResponse:
      return message;
    case DioExceptionType.cancel:
      return '请求被取消';
    case DioExceptionType.connectionError:
      return '网络连接失败，请检查网络';
    case DioExceptionType.unknown:
      return '未知网络错误';
    case DioExceptionType.badCertificate:
      return '证书验证失败';
  }
}
