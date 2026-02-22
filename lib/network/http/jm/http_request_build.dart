import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/jm/jm_client.dart';

Future<dynamic> request(
  String path, {
  String method = 'GET',
  Map<String, dynamic>? params, // URL 参数
  dynamic data,
  Map<String, dynamic>? formData,
  bool cache = false,
  bool useJwt = true,
}) async {
  var cancelToken = CancelToken();

  try {
    dynamic requestBody;
    if (formData != null && method == 'POST') {
      requestBody = FormData.fromMap(formData);
    } else {
      requestBody = data;
    }

    final response = await JmClient().dio.request(
      path,
      data: requestBody,
      queryParameters: params,
      options: Options(
        method: method,
        extra: {'useCache': cache, 'useJwt': useJwt},
      ),
      cancelToken: cancelToken,
    );

    return JmResponseParser.toMap(response.data);
  } on DioException catch (e) {
    throw Exception(e.error ?? e.message);
  }
}

class JmResponseParser {
  static Map<String, dynamic>? toMap(dynamic data) {
    if (data == null) return null;

    try {
      List<int> bytes;
      if (data is List<int>) {
        bytes = _decodeGzip(data);
      } else if (data is String) {
        return jsonDecode(data) as Map<String, dynamic>;
      } else if (data is Map) {
        return data as Map<String, dynamic>;
      } else {
        return null;
      }

      String rawString = utf8.decode(bytes);
      return jsonDecode(rawString) as Map<String, dynamic>;
    } catch (e) {
      logger.e("解析响应数据失败: $e");
      rethrow;
    }
  }

  static List<int> _decodeGzip(List<int> bytes) {
    if (bytes.length >= 2 && bytes[0] == 0x1f && bytes[1] == 0x8b) {
      try {
        return GZipCodec().decode(bytes);
      } catch (e) {
        return bytes;
      }
    }
    return bytes;
  }
}
