import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

class PicaResponseInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // 如果响应是 Bytes 且包含 Gzip 头，进行解压
    if (response.data is List<int>) {
      response.data = _decodeResponse(
        response.data,
        response.headers.value('content-encoding'),
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 即使是报错，服务端也可能返回了 Gzip 压缩的 JSON 错误信息
    if (err.response?.data is List<int>) {
      try {
        final decoded = _decodeResponse(
          err.response!.data,
          err.response!.headers.value('content-encoding'),
        );
        err.response!.data = decoded;
      } catch (e) {
        // 解码失败忽略
      }
    }
    handler.next(err);
  }

  dynamic _decodeResponse(List<int> bytes, String? encoding) {
    List<int> resultBytes = bytes;

    // 检查是否 Gzip
    bool isGzipped = bytes.length >= 2 && bytes[0] == 0x1f && bytes[1] == 0x8b;
    if (encoding != null && encoding.contains('gzip') && isGzipped) {
      try {
        resultBytes = GZipCodec().decode(bytes);
      } catch (e) {
        // 解压失败降级处理
      }
    }

    // 尝试转 JSON
    try {
      final String decodedString = utf8.decode(resultBytes);
      return jsonDecode(decodedString);
    } catch (e) {
      // 不是 JSON，直接返回 String 或 Bytes
      try {
        return utf8.decode(resultBytes);
      } catch (_) {
        return resultBytes;
      }
    }
  }
}
