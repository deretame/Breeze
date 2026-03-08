import 'package:dio/dio.dart';

class JmRetryInterceptor extends Interceptor {
  final Dio dio;

  JmRetryInterceptor({required this.dio});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final extra = err.requestOptions.extra;
    final isRetried = extra['jm_retried'] == true;

    if (isRetried) {
      return handler.next(err);
    }

    extra['jm_retried'] = true;

    try {
      final response = await dio.fetch(err.requestOptions);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    } catch (e) {
      return handler.next(
        DioException(requestOptions: err.requestOptions, error: e.toString()),
      );
    }
  }
}
