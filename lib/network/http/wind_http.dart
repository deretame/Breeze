import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:zephyr/src/native_gen/api/bridge_api.dart' as native;

/// WindHttp 的全局网络配置。
///
/// C++（fetchcore）侧的 fetch 不再读 Rust 全局状态，代理由 Dart 侧解析后
/// 逐 client 传入。main.dart 在应用启动 / 变更设置时，与 Rust 侧
/// （插件 QJS 运行时仍在用）同步更新这里。
class WindHttpConfig {
  WindHttpConfig._();

  /// 全局代理 URL（`http://…` / `socks5://…`）；null = 直连。
  static String? proxy;

  /// 全局 TLS 证书校验开关（应用启动时置 false 以兼容自签名图源）。
  static bool tlsVerify = true;
}

/// Fetch 风格 HTTP 客户端（底层为 wind_core_cpp / fetchcore）。
///
/// 每次 `WindHttp()` / `fetch()` 都会新建底层 client（不复用全局单例）。
///
/// ```dart
/// final res = await fetch(
///   'https://example.com/api',
///   method: 'POST',
///   headers: {'Accept': 'application/json'},
///   body: {'q': 'hi'},
/// );
/// if (res.ok) print(res.json);
/// ```
class WindHttp {
  WindHttp._(this._client, this._baseUrl, this._defaultHeaders);

  final native.WindHttpClient _client;
  final String? _baseUrl;
  final Map<String, String> _defaultHeaders;

  factory WindHttp({
    String? baseUrl,
    Map<String, String>? headers,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    bool followRedirects = true,
    bool noProxy = false,
    String? httpProxy,
    bool? dangerAcceptInvalidCerts,
    String? userAgent,
  }) {
    final timeout = receiveTimeout ?? const Duration(seconds: 30);
    // 代理：noProxy 强制直连；显式 httpProxy 优先；否则用全局配置
    final proxy = noProxy ? '' : (httpProxy ?? WindHttpConfig.proxy ?? '');
    // TLS：显式 dangerAcceptInvalidCerts 覆盖全局设置
    final tlsVerify =
        dangerAcceptInvalidCerts != null
            ? !dangerAcceptInvalidCerts
            : WindHttpConfig.tlsVerify;
    // connectTimeout 无独立对应项（C++ 侧超时为"发出→body 收完"全程 deadline）
    final _ = connectTimeout;
    return WindHttp._(
      native.WindHttpClient.mapStringStringInt64TBoolStringBoolString(
        defaultHeaders: headers ?? const {},
        timeoutMs: timeout.inMilliseconds,
        followRedirects: followRedirects,
        proxy: proxy,
        tlsVerify: tlsVerify,
        userAgent: userAgent ?? '',
      ),
      baseUrl,
      headers ?? const {},
    );
  }

  /// 强制直连（忽略代理）。
  factory WindHttp.direct({
    Duration? connectTimeout,
    Duration? receiveTimeout,
    bool followRedirects = true,
  }) {
    return WindHttp(
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      followRedirects: followRedirects,
      noProxy: true,
    );
  }

  String get baseUrl => _baseUrl ?? '';

  Map<String, String> get defaultHeaders => _defaultHeaders;

  /// `fetch(url, { method, headers, body, query, timeout })`
  Future<FetchResponse> fetch(
    String url, {
    String method = 'GET',
    Map<String, String>? headers,
    Object? body,
    Map<String, dynamic>? query,
    Duration? timeout,
    bool? followRedirects,
  }) async {
    final resolvedHeaders =
        headers == null ? null : Map<String, String>.from(headers);
    final encoded = _encodeBody(body, resolvedHeaders);

    final meta = await _client.fetch(
      url: _resolveUrl(url, query),
      init: native.WindFetchInit(
        method: method,
        headers: resolvedHeaders ?? const {},
        body: encoded ?? Uint8List(0),
        timeoutMs: timeout?.inMilliseconds ?? 0,
        followRedirects: followRedirects,
      ),
    );
    return FetchResponse._(meta);
  }

  /// 流式下载到本地文件。
  Future<void> download(
    String url,
    String savePath, {
    String method = 'GET',
    Map<String, String>? headers,
    Object? body,
    Map<String, dynamic>? query,
    Duration? timeout,
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    final resolvedHeaders =
        headers == null ? null : Map<String, String>.from(headers);
    final encoded = _encodeBody(body, resolvedHeaders);

    StreamController<native.WindDownloadProgress>? controller;
    StreamSubscription<native.WindDownloadProgress>? sub;
    if (onReceiveProgress != null) {
      controller = StreamController<native.WindDownloadProgress>();
      sub = controller.stream.listen(
        (e) => onReceiveProgress(e.received, e.total),
      );
    }

    try {
      await _client.download(
        url: _resolveUrl(url, query),
        savePath: savePath,
        init: native.WindFetchInit(
          method: method,
          headers: resolvedHeaders ?? const {},
          body: encoded ?? Uint8List(0),
          timeoutMs: timeout?.inMilliseconds ?? 0,
          followRedirects: null,
        ),
        progress: controller,
      );
    } finally {
      await sub?.cancel();
      await controller?.close();
    }
  }

  /// baseUrl 拼接 + query 参数合并（Rust 侧原在 reqwest 内做，现收拢到 Dart）。
  String _resolveUrl(String url, Map<String, dynamic>? query) {
    var u = url;
    final base = _baseUrl;
    if (base != null && base.isNotEmpty && !Uri.parse(u).hasScheme) {
      u = Uri.parse(base).resolve(u).toString();
    }
    if (query != null && query.isNotEmpty) {
      final uri = Uri.parse(u);
      final qp = Map<String, String>.from(uri.queryParameters);
      query.forEach((key, value) => qp[key] = value?.toString() ?? '');
      u = uri.replace(queryParameters: qp).toString();
    }
    return u;
  }
}

/// 对齐浏览器 `Response`。
class FetchResponse {
  FetchResponse._(this._meta);

  final native.WindFetchResponse _meta;

  int get status => _meta.status;
  String get statusText => _meta.statusText;
  bool get ok => status >= 200 && status < 300;
  bool get redirected => _meta.redirected;
  String get url => _meta.url;
  Map<String, String> get headers => _meta.headers;
  Uint8List get body => _meta.body;

  String get text => utf8.decode(body, allowMalformed: true);

  dynamic get json {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    return jsonDecode(trimmed);
  }

  String? header(String name) {
    final target = name.toLowerCase();
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == target) {
        return entry.value;
      }
    }
    return null;
  }
}

/// 请求体编码（与原 Rust 路径一致：bytes 直传，String 按 UTF-8，
/// 其他 JSON 序列化并自动补 Content-Type）。
Uint8List? _encodeBody(Object? body, Map<String, String>? headers) {
  if (body == null) return null;
  if (body is Uint8List) return body;
  if (body is List<int>) return Uint8List.fromList(body);
  if (body is String) return Uint8List.fromList(utf8.encode(body));
  headers?.putIfAbsent('Content-Type', () => 'application/json; charset=utf-8');
  return Uint8List.fromList(utf8.encode(jsonEncode(body)));
}

/// 顶层 fetch：每次新建默认客户端。
Future<FetchResponse> fetch(
  String url, {
  String method = 'GET',
  Map<String, String>? headers,
  Object? body,
  Map<String, dynamic>? query,
  Duration? timeout,
  bool? followRedirects,
}) => WindHttp().fetch(
  url,
  method: method,
  headers: headers,
  body: body,
  query: query,
  timeout: timeout,
  followRedirects: followRedirects,
);

/// 顶层直连 fetch：每次新建直连客户端。
Future<FetchResponse> fetchDirect(
  String url, {
  String method = 'GET',
  Map<String, String>? headers,
  Object? body,
  Map<String, dynamic>? query,
  Duration? timeout,
}) => WindHttp.direct().fetch(
  url,
  method: method,
  headers: headers,
  body: body,
  query: query,
  timeout: timeout,
);
