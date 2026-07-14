import 'dart:convert';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:zephyr/src/rust/api/http.dart' as rust;

/// Fetch 风格 HTTP 客户端。
///
/// 每次 `WindHttp()` / `fetch()` 都会新建底层 reqwest client（不复用全局单例）。
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
  WindHttp._(this._client);

  final rust.HttpClient _client;

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
    final connect = connectTimeout ?? const Duration(seconds: 15);
    return WindHttp._(
      rust.HttpClient.create(
        options: rust.HttpClientOptions(
          baseUrl: baseUrl,
          defaultHeaders: headers,
          timeoutMs: BigInt.from(timeout.inMilliseconds),
          connectTimeoutMs: BigInt.from(connect.inMilliseconds),
          followRedirects: followRedirects,
          noProxy: noProxy,
          httpProxy: httpProxy,
          dangerAcceptInvalidCerts: dangerAcceptInvalidCerts,
          userAgent: userAgent,
        ),
      ),
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

  String get baseUrl => _client.baseUrl();

  Map<String, String> get defaultHeaders => _client.defaultHeaders();

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
    final resolvedHeaders = headers == null
        ? null
        : Map<String, String>.from(headers);
    final encoded = _encodeBody(body, resolvedHeaders);

    final raw = await _client.fetch(
      url: url,
      init: rust.FetchInit(
        method: method,
        headers: resolvedHeaders,
        query: _stringifyQuery(query),
        body: encoded,
        timeoutMs: timeout == null ? null : BigInt.from(timeout.inMilliseconds),
        followRedirects: followRedirects,
      ),
    );
    return FetchResponse._(raw);
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
    final resolvedHeaders = headers == null
        ? null
        : Map<String, String>.from(headers);
    final encoded = _encodeBody(body, resolvedHeaders);
    final init = rust.FetchInit(
      method: method,
      headers: resolvedHeaders,
      query: _stringifyQuery(query),
      body: encoded,
      timeoutMs: timeout == null ? null : BigInt.from(timeout.inMilliseconds),
    );

    if (onReceiveProgress == null) {
      await _client.download(url: url, savePath: savePath, init: init);
      return;
    }

    final sink = RustStreamSink<rust.HttpProgress>();
    final sub = sink.stream.listen((event) {
      onReceiveProgress(event.received.toInt(), event.total?.toInt() ?? -1);
    });
    try {
      await _client.download(
        url: url,
        savePath: savePath,
        init: init,
        progress: sink,
      );
    } finally {
      await sub.cancel();
    }
  }
}

/// 对齐浏览器 `Response`。
class FetchResponse {
  FetchResponse._(this._raw);

  final rust.FetchResponse _raw;

  int get status => _raw.status;
  String get statusText => _raw.statusText;
  bool get ok => _raw.ok;
  bool get redirected => _raw.redirected;
  String get url => _raw.url;
  Map<String, String> get headers => _raw.headers;
  Uint8List get body => _raw.body;

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

Uint8List? _encodeBody(Object? body, Map<String, String>? headers) {
  if (body == null) return null;
  if (body is Uint8List) return body;
  if (body is List<int>) return Uint8List.fromList(body);
  if (body is String) return Uint8List.fromList(utf8.encode(body));
  headers?.putIfAbsent('Content-Type', () => 'application/json; charset=utf-8');
  return Uint8List.fromList(utf8.encode(jsonEncode(body)));
}

Map<String, String>? _stringifyQuery(Map<String, dynamic>? query) {
  if (query == null || query.isEmpty) return null;
  return query.map((key, value) => MapEntry(key, value?.toString() ?? ''));
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
