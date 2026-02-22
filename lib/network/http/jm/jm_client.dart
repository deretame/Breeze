import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:zephyr/config/jm/config.dart';
import 'package:zephyr/network/dio_cache.dart';
import 'package:zephyr/network/http/jm/interceptor/jm_auth_interceptor.dart';
import 'package:zephyr/network/http/jm/interceptor/jm_decrypt_interceptor.dart';
import 'package:zephyr/network/http/jm/interceptor/jm_error_interceptor.dart';

class JmClient {
  // 复用之前的缓存类
  final myCache = ExpiringMemoryCache(
    expiryDuration: const Duration(minutes: 10),
  );

  static final JmClient _instance = JmClient._internal();
  factory JmClient() => _instance;

  late final Dio dio;

  JmClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: JmConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        responseType: ResponseType.bytes,
      ),
    );

    dio.interceptors.add(CookieManager(JmConfig.cookieJar));

    dio.interceptors.addAll([
      JmAuthInterceptor(),
      JmDecryptInterceptor(),
      DioCacheInterceptor(myCache),
      JmErrorInterceptor(),
    ]);
  }
}
