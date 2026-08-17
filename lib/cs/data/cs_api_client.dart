import 'dart:convert';
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

class CsPluginRecord {
  const CsPluginRecord({
    required this.pluginId,
    required this.version,
    required this.bundleHash,
    required this.enabled,
    required this.updatedAt,
  });

  final String pluginId;
  final String version;
  final String bundleHash;
  final bool enabled;
  final String updatedAt;

  factory CsPluginRecord.fromJson(Map<String, dynamic> json) {
    return CsPluginRecord(
      pluginId: json['plugin_id'] as String? ?? '',
      version: json['version'] as String? ?? '',
      bundleHash: json['bundle_hash'] as String? ?? '',
      enabled: json['enabled'] == true,
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }
}

class CsCloudPluginItem {
  const CsCloudPluginItem({required this.repo, required this.manifest});

  final String repo;
  final CsCloudPluginManifest manifest;

  factory CsCloudPluginItem.fromJson(Map<String, dynamic> json) {
    final rawManifest = json['manifest'];
    return CsCloudPluginItem(
      repo: json['repo'] as String? ?? '',
      manifest: CsCloudPluginManifest.fromJson(
        rawManifest is Map
            ? Map<String, dynamic>.from(rawManifest)
            : const <String, dynamic>{},
      ),
    );
  }
}

class CsCloudPluginManifest {
  const CsCloudPluginManifest({
    required this.name,
    required this.uuid,
    required this.iconUrl,
    required this.creatorName,
    required this.creatorDescribe,
    required this.describe,
    required this.version,
    required this.home,
    required this.updateUrl,
    required this.npmName,
  });

  final String name;
  final String uuid;
  final String iconUrl;
  final String creatorName;
  final String creatorDescribe;
  final String describe;
  final String version;
  final String home;
  final String updateUrl;
  final String npmName;

  factory CsCloudPluginManifest.fromJson(Map<String, dynamic> json) {
    final rawCreator = json['creator'];
    final creator = rawCreator is Map
        ? Map<String, dynamic>.from(rawCreator)
        : const <String, dynamic>{};
    return CsCloudPluginManifest(
      name: json['name'] as String? ?? '',
      uuid: json['uuid'] as String? ?? '',
      iconUrl: json['iconUrl'] as String? ?? '',
      creatorName: creator['name'] as String? ?? '',
      creatorDescribe: creator['describe'] as String? ?? '',
      describe: json['describe'] as String? ?? '',
      version: json['version'] as String? ?? '',
      home: json['home'] as String? ?? '',
      updateUrl: json['updateUrl'] as String? ?? '',
      npmName: json['npmName'] as String? ?? '',
    );
  }
}

class CsPluginConfig {
  const CsPluginConfig({
    required this.pluginId,
    required this.config,
    required this.revision,
    required this.updatedAt,
  });

  final String pluginId;
  final Map<String, dynamic> config;
  final int revision;
  final String updatedAt;

  factory CsPluginConfig.fromJson(Map<String, dynamic> json) {
    final config = json['config'];
    if (config is! Map) {
      throw const FormatException('CS plugin config must be an object');
    }
    return CsPluginConfig(
      pluginId: json['plugin_id'] as String? ?? '',
      config: Map<String, dynamic>.from(config),
      revision: (json['revision'] as num?)?.toInt() ?? 0,
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }
}

class CsDownloadTask {
  const CsDownloadTask({
    required this.taskId,
    required this.status,
    required this.progress,
    required this.payload,
    required this.updatedAt,
    this.error,
  });

  final String taskId;
  final String status;
  final int progress;
  final Map<String, dynamic> payload;
  final String updatedAt;
  final String? error;

  factory CsDownloadTask.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'];
    return CsDownloadTask(
      taskId: json['task_id'] as String? ?? '',
      status: json['status'] as String? ?? '',
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      payload: payload is Map ? Map<String, dynamic>.from(payload) : const {},
      updatedAt: json['updated_at'] as String? ?? '',
      error: json['error'] as String?,
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

  Future<List<CsPluginRecord>> plugins() async {
    final json = await _get('/api/v1/plugins');
    final items = json['items'];
    if (items is! List) {
      throw const FormatException('CS plugin response has no items');
    }
    return items
        .map(
          (item) =>
              CsPluginRecord.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<List<CsCloudPluginItem>> pluginCatalog() async {
    final json = await _get('/api/v1/plugins/catalog');
    final items = json['items'];
    if (items is! List) {
      throw const FormatException('CS plugin catalog response has no items');
    }
    return items
        .map(
          (item) => CsCloudPluginItem.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .where((item) => item.manifest.uuid.trim().isNotEmpty)
        .toList();
  }

  Future<CsPluginRecord> installCatalogPlugin(String pluginId) async {
    final json = await _post('/api/v1/plugins/catalog/install', {
      'plugin_id': pluginId,
    });
    return CsPluginRecord.fromJson(json);
  }

  Future<CsPluginRecord> installPluginFromUrl(String url) async {
    final json = await _post('/api/v1/plugins/install-url', {'url': url});
    return CsPluginRecord.fromJson(json);
  }

  Future<CsPluginRecord> installPluginBundle(
    Uint8List bytes, {
    required String fileName,
  }) async {
    final json = await _post('/api/v1/plugins/install-bundle', {
      'file_name': fileName,
      'bundle_base64': base64Encode(bytes),
    });
    return CsPluginRecord.fromJson(json);
  }

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

  Future<CsPluginConfig> pluginConfig(String pluginId) async {
    final json = await _get(
      '/api/v1/plugins/${Uri.encodeComponent(pluginId)}/config',
    );
    return CsPluginConfig.fromJson(json);
  }

  Future<CsPluginConfig> updatePluginConfig(
    String pluginId,
    Map<String, dynamic> config, {
    int? expectedRevision,
  }) async {
    final json = await _patch(
      '/api/v1/plugins/${Uri.encodeComponent(pluginId)}/config',
      {'config': config, 'expected_revision': expectedRevision},
    );
    return CsPluginConfig.fromJson(json);
  }

  Future<Map<String, dynamic>> searchPlugin({
    required String pluginId,
    required String keyword,
    int page = 1,
    Map<String, dynamic> extern = const {},
  }) {
    return _post('/api/v1/plugins/${Uri.encodeComponent(pluginId)}/search', {
      'core': {'keyword': keyword, 'page': page},
      'extern': extern,
    });
  }

  Future<Map<String, dynamic>> getPluginDetail({
    required String pluginId,
    required String comicId,
    Map<String, dynamic> extern = const {},
  }) {
    return _post(
      '/api/v1/plugins/${Uri.encodeComponent(pluginId)}/comic/${Uri.encodeComponent(comicId)}/detail',
      {'core': {}, 'extern': extern},
    );
  }

  Future<Map<String, dynamic>> getPluginChapter({
    required String pluginId,
    required String comicId,
    required String chapterId,
    Map<String, dynamic> extern = const {},
  }) {
    return _post(
      '/api/v1/plugins/${Uri.encodeComponent(pluginId)}/comic/${Uri.encodeComponent(comicId)}/chapter/${Uri.encodeComponent(chapterId)}',
      {'core': {}, 'extern': extern},
    );
  }

  Future<Map<String, dynamic>> getPluginReadSnapshot({
    required String pluginId,
    required String comicId,
    String? chapterId,
    Map<String, dynamic> extern = const {},
  }) {
    return _post(
      '/api/v1/plugins/${Uri.encodeComponent(pluginId)}/comic/${Uri.encodeComponent(comicId)}/read',
      {
        'core': {
          if (chapterId != null && chapterId.trim().isNotEmpty)
            'chapterId': chapterId,
        },
        'extern': extern,
      },
    );
  }

  Future<CsDownloadTask> createServerDownload({
    required String pluginId,
    required String comicId,
    required List<String> chapterIds,
    Map<String, dynamic> options = const {},
  }) async {
    final json = await _post('/api/v1/downloads/tasks', {
      'plugin_id': pluginId,
      'comic_id': comicId,
      'chapter_ids': chapterIds,
      'options': options,
    });
    return CsDownloadTask.fromJson(json);
  }

  Future<List<CsDownloadTask>> listServerDownloads() async {
    final json = await _get('/api/v1/downloads/tasks');
    final items = json['items'];
    if (items is! List) {
      throw const FormatException('CS download response has no items');
    }
    return items
        .map(
          (item) =>
              CsDownloadTask.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<CsDownloadTask> cancelServerDownload(String taskId) async {
    final json = await _post(
      '/api/v1/downloads/tasks/${Uri.encodeComponent(taskId)}/cancel',
      const {},
    );
    return CsDownloadTask.fromJson(json);
  }

  Future<Map<String, dynamic>> serverDownloadManifest(String comicKey) {
    return _get(
      '/api/v1/downloads/comics/${Uri.encodeComponent(comicKey)}/manifest',
    );
  }

  Future<Uint8List> serverAsset(String assetId) async {
    final response = await _httpClient.fetch(
      _url('/api/v1/downloads/assets/${Uri.encodeComponent(assetId)}'),
      headers: _headers(),
    );
    if (!response.ok) {
      _decodeAny(response);
    }
    return response.body;
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
