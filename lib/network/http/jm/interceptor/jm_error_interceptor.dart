import 'package:dio/dio.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/jm/http_request_build.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/event/event.dart';
// 导入上面的工具类
// import 'package:zephyr/network/http/jm/jm_response_parser.dart';

class JmErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String? errorMsg;

    final responseData = JmResponseParser.toMap(err.response?.data);

    if (responseData != null) {
      final int? code = responseData['code'];
      final String? serverMsg = responseData['errorMsg'] ?? responseData['msg'];

      if (code == 401 || serverMsg == '請先登入會員') {
        eventBus.fire(NeedLogin(from: From.jm));
        errorMsg = (serverMsg?.contains('密码') ?? false)
            ? serverMsg
            : '登录过期，请重新登录';
      } else {
        errorMsg = serverMsg;
      }
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
