import 'package:dio/dio.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/event/event.dart';

class JmErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String? errorMsg;

    if (err.response?.data is Map) {
      final data = err.response!.data;
      if (data['code'] == 401 || data['errorMsg'] == '請先登入會員') {
        eventBus.fire(NeedLogin(from: From.jm));
        errorMsg = '登录过期，请重新登录';
      } else if (data['msg'] != null) {
        errorMsg = data['msg'];
      }
    }

    // 处理网络层错误文案
    errorMsg ??= _handleDioErrorType(err);

    final newErr = DioException(
      requestOptions: err.requestOptions,
      error: errorMsg,
      type: err.type,
      response: err.response,
    );

    handler.next(newErr);
  }

  String _handleDioErrorType(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return '连接服务器超时（${error.requestOptions.connectTimeout}秒）';
      case DioExceptionType.sendTimeout:
        return '请求发送超时（${error.requestOptions.sendTimeout}秒）';
      case DioExceptionType.receiveTimeout:
        return '响应接收超时（${error.requestOptions.receiveTimeout}秒）';
      case DioExceptionType.badResponse:
        return error.message ?? '未知错误';
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
}
