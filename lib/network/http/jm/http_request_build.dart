import 'dart:async';

import 'package:dio/dio.dart';
import 'package:zephyr/network/http/jm/jm_client.dart';
import 'package:zephyr/network/http/jm/jm_error_message.dart';
import 'package:zephyr/network/http/jm/jm_response_codec.dart';

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

    return JmResponseParser.toMap(
      response.data,
      ts: response.requestOptions.extra['jm_ts'] is String
          ? response.requestOptions.extra['jm_ts'] as String
          : null,
    );
  } on DioException catch (e) {
    throw Exception(
      sanitizeJmErrorMessage(
        e.error?.toString() ?? e.message,
        fallback: '网络错误，请稍后再试',
      ),
    );
  }
}

class JmResponseParser {
  static dynamic toMap(dynamic data, {String? ts}) {
    return JmResponseCodec.decode(data, ts: ts);
  }
}
