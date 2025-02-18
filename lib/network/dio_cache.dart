import 'dart:convert';

import 'package:dio/dio.dart';

class ExpiringMemoryCache {
  final Map<String, _CacheItem> _cache = {};
  final Duration _expiryDuration;

  ExpiringMemoryCache({Duration? expiryDuration})
    : _expiryDuration = expiryDuration ?? Duration(minutes: 5);

  T? get<T>(String key) {
    final cachedItem = _cache[key];
    if (cachedItem == null || _isExpired(cachedItem)) {
      _cache.remove(key);
      return null; // 返回 null 表示缓存已过期
    }
    return cachedItem.value as T?;
  }

  void set(String key, dynamic value) {
    final cacheItem = _CacheItem(value, DateTime.now());
    _cache[key] = cacheItem;
  }

  bool _isExpired(_CacheItem item) {
    final expiryTime = item.timestamp.add(_expiryDuration);
    return DateTime.now().isAfter(expiryTime);
  }

  void clear() {
    _cache.clear();
  }
}

class _CacheItem {
  final dynamic value;
  final DateTime timestamp;

  _CacheItem(this.value, this.timestamp);
}

class DioCacheInterceptor extends Interceptor {
  final ExpiringMemoryCache cache;

  DioCacheInterceptor(this.cache);

  void clear() {
    cache.clear();
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final cacheKey = _generateCacheKey(options);
    final cachedResponse = cache.get<Response>(cacheKey);

    if (cachedResponse != null) {
      return handler.resolve(cachedResponse);
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.statusCode == 200 && _isValidResponseBody(response.data)) {
      final cacheKey = _generateCacheKey(response.requestOptions);
      cache.set(cacheKey, response);
    }
    handler.next(response);
  }

  String _generateCacheKey(RequestOptions options) {
    // 仅当是 POST 请求且 Content-Length 为 0 时，才在 key 上加上请求体
    if (options.method.toUpperCase() == 'POST' &&
        options.headers['Content-Length'] == '0') {
      final body = options.data != null ? jsonEncode(options.data) : '';
      return '${options.uri.toString()}|$body';
    }
    // 其他情况只使用 URL 作为 key
    return options.uri.toString();
  }

  bool _isValidResponseBody(dynamic responseBody) {
    if (responseBody is Map<String, dynamic>) {
      return responseBody['code'] == 200;
    }
    return false;
  }
}
