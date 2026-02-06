import 'dart:math';

import 'package:dio/dio.dart';
import 'package:zephyr/config/jm/config.dart';

class JmAuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 1. 生成时间戳
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    // 2. 保存到 extra，供解密拦截器使用
    options.extra['jm_ts'] = timestamp;

    // 3. 处理 UA
    if (JmConfig.device.isEmpty) {
      _generateDeviceId();
    }

    // 4. 构建 Headers
    final bool useJwt = options.extra['useJwt'] ?? true;

    options.headers.addAll({
      'token': JmConfig.token,
      'tokenparam': '$timestamp,${JmConfig.jmVersion}',
      'user-agent': _getJmUA(),
      'Host': JmConfig.baseUrl.replaceAll('https://', ''),
    });

    if (options.contentType == null && options.method == 'POST') {
      options.contentType = Headers.formUrlEncodedContentType;
    }

    if (useJwt) {
      options.headers['Authorization'] = 'Bearer ${JmConfig.jwt}';
    }

    handler.next(options);
  }

  String _getJmUA() {
    return 'Mozilla/5.0 (Linux; Android 13; ${JmConfig.device} Build/TQ1A.230305.002; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/114.0.5735.196 Safari/537.36';
  }

  void _generateDeviceId() {
    var chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    var random = Random();
    JmConfig.device = List.generate(
      9,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }
}
