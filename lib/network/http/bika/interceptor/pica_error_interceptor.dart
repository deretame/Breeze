import 'package:dio/dio.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/event/event.dart';

class PicaErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 1. 处理业务错误 (服务端返回了响应，但状态码或内容标识错误)
    if (err.response?.data is Map<String, dynamic>) {
      final data = err.response!.data as Map<String, dynamic>;

      // 处理 401
      if (data['code'] == 401 && data['message'] == 'unauthorized') {
        eventBus.fire(NeedLogin(from: From.bika));
      }

      // 处理 "审核中"
      if (data['message'] == "under review") {
        // 构造一个新的 DioException 抛出
        return handler.next(
          DioException(
            requestOptions: err.requestOptions,
            error: "审核中",
            type: DioExceptionType.badResponse,
          ),
        );
      }

      // 优先使用服务端返回的 message
      if (data['message'] != null) {
        return handler.next(
          DioException(
            requestOptions: err.requestOptions,
            error: data['message'],
            type: DioExceptionType.badResponse,
          ),
        );
      }
    }

    // 2. 处理网络层错误 (转换错误信息为中文)
    String friendlyMsg = _handleDioError(err);
    final newErr = DioException(
      requestOptions: err.requestOptions,
      error: friendlyMsg,
      type: err.type,
      response: err.response,
    );

    handler.next(newErr);
  }

  String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return '连接服务器超时（${error.requestOptions.connectTimeout}秒）';
      case DioExceptionType.sendTimeout:
        return '请求发送超时（${error.requestOptions.sendTimeout}秒）';
      case DioExceptionType.receiveTimeout:
        return '响应接收超时（${error.requestOptions.receiveTimeout}秒）';
      case DioExceptionType.badResponse:
        return error.response?.toString() ?? '未知错误';
      case DioExceptionType.cancel:
        return '请求被取消';
      case DioExceptionType.connectionError:
        return '网络连接失败，请检查网络';
      case DioExceptionType.unknown:
        return error.error?.toString() ?? '未知网络错误';
      case DioExceptionType.badCertificate:
        return '证书验证失败';
    }
  }
}
