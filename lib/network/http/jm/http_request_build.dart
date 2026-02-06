import 'dart:async';

import 'package:dio/dio.dart';
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

    return response.data;
  } on DioException catch (e) {
    throw Exception(e.error ?? e.message);
  }
}
