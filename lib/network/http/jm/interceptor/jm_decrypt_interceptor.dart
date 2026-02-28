import 'package:dio/dio.dart';
import 'package:zephyr/config/jm/config.dart';
import 'package:zephyr/network/http/jm/jm_response_codec.dart';

class JmDecryptInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final ts = _resolveTs(response.requestOptions);
    response.data = JmResponseCodec.decode(response.data, ts: ts);

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    if (response != null) {
      final ts = _resolveTs(err.requestOptions);
      response.data = JmResponseCodec.decode(response.data, ts: ts);
    }

    handler.next(err);
  }

  String _resolveTs(RequestOptions options) {
    final ts = options.extra['jm_ts'];
    if (ts is String && ts.isNotEmpty) {
      return ts;
    }

    return JmConfig.timestamp;
  }
}
