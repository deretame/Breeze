import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:encrypter_plus/encrypter_plus.dart';
import 'package:zephyr/config/jm/config.dart';

class JmDecryptInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // 1. 获取 Timestamp
    final String ts =
        response.requestOptions.extra['jm_ts'] ?? JmConfig.timestamp;

    // 2. 如果是 Bytes (List<int>)，尝试转换为 Map
    if (response.data is List<int>) {
      try {
        // A. 解压 Gzip
        List<int> bytes = _handleGzip(response.data);

        // B. 尝试转为 String
        String rawString = utf8.decode(bytes);

        // C. 尝试解析 JSON
        // 注意：这里可能抛出 FormatException (如果返回的是 HTML 或图片)
        var jsonMap = jsonDecode(rawString);

        // D. 业务解密逻辑
        if (jsonMap is Map<String, dynamic> && jsonMap['data'] is String) {
          // 情况 1: {"code": 200, "data": "加密串..."} -> 解密
          response.data = _decodeRespData(jsonMap['data'], ts);
        } else {
          // 情况 2: {"code": 200, "data": {...}} -> 已经是明文，直接替换
          response.data = jsonMap;
        }
      } catch (e) {
        // E. 兜底处理
        // 如果上面任何一步报错（比如是图片流，或者 json 解析失败），
        // 保持 response.data 原样 (List<int>)，不要让 App 崩溃
      }
    }
    // 3. 如果已经是 String (某些情况下 Dio 可能会自动转)
    else if (response.data is String) {
      try {
        var jsonMap = jsonDecode(response.data);
        if (jsonMap is Map<String, dynamic> && jsonMap['data'] is String) {
          response.data = _decodeRespData(jsonMap['data'], ts);
        } else {
          response.data = jsonMap;
        }
      } catch (_) {}
    }

    handler.next(response);
  }

  List<int> _handleGzip(List<int> bytes) {
    final bool isGzipMagic =
        bytes.length >= 2 && bytes[0] == 0x1f && bytes[1] == 0x8b;
    if (isGzipMagic) {
      try {
        return GZipCodec().decode(bytes);
      } catch (e) {
        return bytes;
      }
    }
    return bytes;
  }

  // 核心解密逻辑
  dynamic _decodeRespData(String data, String ts) {
    final actualSecret = JmConfig.kJmSecret;

    // 1. Base64
    final dataB64 = base64.decode(data);

    // 2. AES-ECB
    final key = md5.convert(utf8.encode('$ts$actualSecret')).toString();
    final encrypter = Encrypter(AES(Key(utf8.encode(key)), mode: AESMode.ecb));
    final dataAes = encrypter.decryptBytes(Encrypted(dataB64));

    // 3. JSON Decode
    return json.decode(utf8.decode(dataAes));
  }
}
