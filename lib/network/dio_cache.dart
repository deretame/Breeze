import 'dart:collection';
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

class SimpleCacheService {
  // 使用LinkedHashMap保持插入顺序，方便后续可能的LRU实现
  final LinkedHashMap<String, Map<String, dynamic>> _cache = LinkedHashMap();
  final Duration _expiryDuration;

  SimpleCacheService({Duration? expiryDuration})
    : _expiryDuration = expiryDuration ?? Duration(minutes: 5);

  /// 存入缓存
  void set(String key, Map<String, dynamic> value) {
    final now = DateTime.now();
    _cache[key] = {
      'value': value,
      'timestamp': now,
      'expiry': now.add(_expiryDuration),
    };
  }

  /// 获取缓存
  Map<String, dynamic>? get(String key) {
    final cachedItem = _cache[key];
    if (cachedItem == null || _isExpired(cachedItem)) {
      _cache.remove(key); // 如果过期则移除
      return null;
    }
    return cachedItem['value'];
  }

  /// 清除所有缓存
  void clear() {
    _cache.clear();
  }

  /// 清除特定key的缓存
  void remove(String key) {
    _cache.remove(key);
  }

  /// 检查是否过期
  bool _isExpired(Map<String, dynamic> cachedItem) {
    final expiryTime = cachedItem['expiry'] as DateTime;
    return DateTime.now().isAfter(expiryTime);
  }

  /// 清除所有过期的缓存项
  void cleanExpired() {
    final now = DateTime.now();
    _cache.removeWhere(
      (key, value) => (value['expiry'] as DateTime).isBefore(now),
    );
  }

  /// 获取缓存大小
  int get size => _cache.length;

  /// 检查是否包含某个key
  bool containsKey(String key) {
    if (!_cache.containsKey(key)) return false;
    if (_isExpired(_cache[key]!)) {
      _cache.remove(key);
      return false;
    }
    return true;
  }
}
