import 'package:dio/dio.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:zephyr/network/dio_cache.dart';
import 'package:zephyr/network/http/bika/interceptor/pica_auth_interceptor.dart';
import 'package:zephyr/network/http/bika/interceptor/pica_error_interceptor.dart';
import 'package:zephyr/network/http/bika/interceptor/pica_response_decoder.dart';

class PicaClient {
  final myCache = ExpiringMemoryCache(
    expiryDuration: const Duration(minutes: 10),
  );

  static final PicaClient _instance = PicaClient._internal();
  factory PicaClient() => _instance;

  late final Dio dio;

  PicaClient._internal() {
    final options = BaseOptions(
      baseUrl: "https://picaapi.picacomic.com/",
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      responseType: ResponseType.bytes,
    );

    dio = Dio(options);

    dio.httpClientAdapter = Http2Adapter(
      ConnectionManager(idleTimeout: const Duration(seconds: 15)),
    );

    dio.interceptors.addAll([
      PicaAuthInterceptor(),
      DioCacheInterceptor(myCache),
      PicaResponseInterceptor(),
      PicaErrorInterceptor(),
    ]);
  }
}
