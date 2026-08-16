import 'dart:typed_data';

import 'package:zephyr/network/http/wind_http.dart';

import 'package:zephyr/cs/domain/cs_library_record.dart';

class CsApiException implements Exception {
  const CsApiException({
    required this.status,
    required this.code,
    required this.message,
  });

  final int status;
  final String code;
  final String message;

  @override
  String toString() => 'CsApiException($status, $code): $message';
}

class CsSession {
  const CsSession({
    required this.accessToken,
    required this.expiresAt,
    required this.userId,
    required this.username,
  });

  final String accessToken;
  final String expiresAt;
  final String userId;
  final String username;

  factory CsSession.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    if (user is! Map) {
      throw const FormatException('CS session response has no user');
    }
    return CsSession(
      accessToken: json['access_token'] as String? ?? '',
      expiresAt: json['expires_at'] as String? ?? '',
      userId: user['id'] as String? ?? '',
      username: user['username'] as String? ?? '',
    );
  }
}

class CsApiClient {
  CsApiClient({required String baseUrl, this.accessToken, WindHttp? httpClient})
    : _baseUrl = _normalizeBaseUrl(baseUrl),
      _httpClient = httpClient ?? WindHttp();

  final String _baseUrl;
  final String? accessToken;
  final WindHttp _httpClient;

  Future<Map<String, dynamic>> health() => _get('/api/v1/health');

  Future<Map<String, dynamic>> capabilities() => _get('/api/v1/capabilities');

  Future<CsSession> register({
    required String username,
    required String password,
  }) async {
    final json = await _post('/api/v1/auth/register', {
      'username': username,
      'password': password,
    });
    return CsSession.fromJson(json);
  }

  Future<CsSession> login({
    required String username,
    required String password,
  }) async {
    final json = await _post('/api/v1/auth/login', {
      'username': username,
      'password': password,
    });
    return CsSession.fromJson(json);
  }

  Future<Map<String, dynamic>> me() => _get('/api/v1/auth/me');

  Future<void> logout() async {
    final response = await _httpClient.fetch(
      _url('/api/v1/auth/logout'),
      method: 'POST',
      headers: _headers(),
      body: const {},
    );
    _decodeAny(response);
  }

  Future<Map<String, dynamic>> accountSettings() {
    return _get('/api/v1/settings/account');
  }

  Future<Map<String, dynamic>> updateAccountSettings({
    required Map<String, dynamic> settings,
    int? expectedRevision,
  }) {
    return _patch('/api/v1/settings/account', {
      'settings': settings,
      'expected_revision': expectedRevision,
    });
  }

  Future<List<CsLibraryRecord>> listLibrary(
    String kind, {
    bool includeDeleted = false,
  }) async {
    final json = await _get(
      '/api/v1/library/$kind',
      query: {if (includeDeleted) 'include_deleted': 'true'},
    );
    final items = json['items'];
    if (items is! List) {
      throw const FormatException('CS library response has no items');
    }
    return items
        .map(
          (item) =>
              CsLibraryRecord.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<CsLibraryRecord> saveLibrary(
    String kind,
    CsLibraryRecord record,
  ) async {
    final json = await _post('/api/v1/library/$kind', {
      'unique_key': record.uniqueKey,
      'source': record.source,
      'comic_id': record.comicId,
      'payload': record.payload,
    });
    return CsLibraryRecord.fromJson(json);
  }

  Future<void> deleteLibrary(String kind, String uniqueKey) async {
    await _delete('/api/v1/library/$kind/${Uri.encodeComponent(uniqueKey)}');
  }

  Future<Map<String, dynamic>> invokePlugin({
    required String pluginId,
    required String function,
    required List<dynamic> args,
  }) async {
    final response = await _httpClient.fetch(
      _url('/api/v1/plugins/${Uri.encodeComponent(pluginId)}/invoke'),
      method: 'POST',
      headers: _headers(),
      body: {'function': function, 'args': args},
    );
    final value = _decodeAny(response);
    if (value is! Map) {
      throw const FormatException('插件响应必须是 JSON 对象');
    }
    return Map<String, dynamic>.from(value);
  }

  Future<Uint8List> invokePluginBytes({
    required String pluginId,
    required String function,
    required List<dynamic> args,
  }) async {
    final response = await _httpClient.fetch(
      _url('/api/v1/plugins/${Uri.encodeComponent(pluginId)}/invoke-bytes'),
      method: 'POST',
      headers: _headers(),
      body: {'function': function, 'args': args},
    );
    if (!response.ok) {
      _decodeAny(response);
    }
    return response.body;
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final response = await _httpClient.fetch(
      _url(path),
      headers: _headers(),
      query: query,
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> _post(String path, Object body) async {
    final response = await _httpClient.fetch(
      _url(path),
      method: 'POST',
      headers: _headers(),
      body: body,
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> _patch(String path, Object body) async {
    final response = await _httpClient.fetch(
      _url(path),
      method: 'PATCH',
      headers: _headers(),
      body: body,
    );
    return _decode(response);
  }

  Future<void> _delete(String path) async {
    final response = await _httpClient.fetch(
      _url(path),
      method: 'DELETE',
      headers: _headers(),
    );
    _decodeAny(response);
  }

  Map<String, String> _headers() {
    return {
      'Accept': 'application/json',
      if (accessToken case final token? when token.trim().isNotEmpty)
        'Authorization': 'Bearer ${token.trim()}',
    };
  }

  Map<String, dynamic> _decode(FetchResponse response) {
    final decoded = _decodeAny(response);
    if (decoded is! Map) {
      throw const FormatException('CS 服务端返回的 JSON 不是对象');
    }
    return Map<String, dynamic>.from(decoded);
  }

  dynamic _decodeAny(FetchResponse response) {
    dynamic decoded;
    try {
      decoded = response.json;
    } on Object catch (error) {
      throw FormatException('CS 服务端返回了无效 JSON: $error');
    }
    if (!response.ok) {
      final map = decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : const {};
      throw CsApiException(
        status: response.status,
        code: map['code'] as String? ?? 'http_error',
        message: map['message'] as String? ?? 'CS 请求失败',
      );
    }
    return decoded;
  }

  String _url(String path) => '$_baseUrl$path';

  static String _normalizeBaseUrl(String value) {
    final normalized = value.trim().replaceFirst(RegExp(r'/+$'), '');
    if (normalized.isEmpty) {
      throw const FormatException('CS serverUrl 不能为空');
    }
    return normalized;
  }
}
