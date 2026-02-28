import 'package:dio/dio.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/jm/jm_error_message.dart';
import 'package:zephyr/network/http/jm/http_request_build.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/event/event.dart';

class JmErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String? errorMsg;
    final ts = err.requestOptions.extra['jm_ts'] is String
        ? err.requestOptions.extra['jm_ts'] as String
        : null;
    final responseData = JmResponseParser.toMap(err.response?.data, ts: ts);

    if (err.response != null) {
      err.response!.data = responseData;
    }

    if (responseData is Map) {
      final parsedMap = Map<String, dynamic>.fromEntries(
        responseData.entries.map(
          (entry) => MapEntry(entry.key.toString(), entry.value),
        ),
      );
      final code = parsedMap['code'] is num
          ? (parsedMap['code'] as num).toInt()
          : null;
      final serverMsgRaw =
          (parsedMap['errorMsg'] ?? parsedMap['msg'] ?? parsedMap['message'])
              ?.toString();
      final serverMsg = sanitizeJmErrorMessage(
        serverMsgRaw,
        fallback: '服务器异常，请稍后再试',
      );

      if (code == 401 || serverMsgRaw == '請先登入會員') {
        eventBus.fire(NeedLogin(from: From.jm));
        errorMsg = (serverMsgRaw?.contains('密码') ?? false)
            ? sanitizeJmErrorMessage(serverMsgRaw)
            : '登录过期，请重新登录';
      } else {
        errorMsg = serverMsg;
      }
    } else if (responseData is String && responseData.trim().isNotEmpty) {
      errorMsg = sanitizeJmErrorMessage(
        responseData.trim(),
        fallback: '服务器异常，请稍后再试',
      );
    }

    errorMsg ??= _handleDioErrorType(err);

    final newErr = DioException(
      requestOptions: err.requestOptions,
      error: errorMsg,
      type: err.type,
      response: err.response,
      message: errorMsg,
    );

    handler.next(newErr);
  }

  String _handleDioErrorType(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return '连接服务器超时';
      case DioExceptionType.sendTimeout:
        return '请求发送超时';
      case DioExceptionType.receiveTimeout:
        return '响应接收超时';
      case DioExceptionType.badResponse:
        return '服务器响应异常 (${error.response?.statusCode})';
      case DioExceptionType.cancel:
        return '请求被取消';
      case DioExceptionType.connectionError:
        return '网络连接失败';
      default:
        return '未知网络错误';
    }
  }
}
