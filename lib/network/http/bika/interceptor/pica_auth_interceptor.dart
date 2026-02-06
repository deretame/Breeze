import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/util/settings_hive_utils.dart';

class PicaAuthInterceptor extends Interceptor {
  final String _apiKey = "C69BAF41DA5ABD1FFEDC6D2FEA56B";
  final String _secretKey =
      r"~d}$Q7$eIni=V)9\RK/P.RM4;9[7|@/CA}b~OW!3?EV`:<>M7pddUBL5n|0/*Cn";

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final nonce = Uuid().v4().replaceAll('-', '');
    final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).floor();

    String cleanUrl = options.path.replaceAll(
      "https://picaapi.picacomic.com/",
      "",
    );

    final signature = _generateSignature(
      cleanUrl,
      timestamp,
      nonce,
      options.method,
    );
    String imageQuality =
        options.extra['imageQuality'] ?? SettingsHiveUtils.bikaImageQuality;
    String? auth =
        options.extra['authorization'] ?? SettingsHiveUtils.bikaAuthorization;
    int proxy = 3;
    try {
      proxy = SettingsHiveUtils.bikaProxy;
    } catch (_) {}

    options.headers.addAll({
      'api-key': _apiKey,
      'accept': 'application/vnd.picacomic.com.v1+json',
      'app-channel': proxy,
      'time': timestamp,
      'nonce': nonce,
      'signature': signature,
      'app-version': "2.2.1.3.3.4",
      'app-uuid': "defaultUuid",
      'app-platform': "android",
      'app-build-version': "45",
      'accept-encoding': 'gzip',
      'user-agent': 'okhttp/3.8.1',
      'content-type': 'application/json; charset=UTF-8',
      'image-quality': imageQuality,
    });

    if (auth != null) {
      options.headers['authorization'] = auth;
    }

    handler.next(options);
  }

  String _generateSignature(
    String url,
    int timestamp,
    String nonce,
    String method,
  ) {
    String raw = "$url$timestamp$nonce$method$_apiKey".toLowerCase();
    var key = utf8.encode(_secretKey);
    var data = utf8.encode(raw);
    var hmacSha256 = Hmac(sha256, key);
    return hmacSha256.convert(data).toString();
  }
}
