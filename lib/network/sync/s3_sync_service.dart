import 'dart:convert';
import 'dart:typed_data';

import 'package:minio/minio.dart';
import 'package:zephyr/config/global/global_setting.dart';

import 'comic_sync_core.dart';

class S3SyncService implements ComicSyncRemoteAdapter {
  S3SyncService(this._settings) : _minio = _createMinio(_settings) {
    if (!isConfigured(_settings)) {
      throw Exception('S3 配置不完整');
    }
  }

  final GlobalSettingState _settings;
  final Minio _minio;

  static bool isConfigured(GlobalSettingState settings) {
    return settings.syncSetting.s3Setting.endpoint.trim().isNotEmpty &&
        settings.syncSetting.s3Setting.accessKey.trim().isNotEmpty &&
        settings.syncSetting.s3Setting.secretKey.isNotEmpty &&
        settings.syncSetting.s3Setting.bucket.trim().isNotEmpty;
  }

  @override
  Future<void> testConnection() async {
    final exists = await _minio.bucketExists(
      _settings.syncSetting.s3Setting.bucket,
    );
    if (!exists) {
      throw Exception(
        'S3 Bucket 不存在或没有访问权限: ${_settings.syncSetting.s3Setting.bucket}',
      );
    }
  }

  @override
  Future<void> ensureRemoteReady() async {}

  @override
  Future<String> downloadRemoteMd5() async {
    for (final candidate in _md5ObjectKeyCandidates) {
      try {
        final stream = await _minio.getObject(
          _settings.syncSetting.s3Setting.bucket,
          candidate,
        );
        final bytes = await _collectStream(stream);
        final value = utf8.decode(bytes).trim();
        if (value.isNotEmpty) {
          return value;
        }
      } on MinioS3Error catch (e) {
        final code = e.error?.code;
        if (code == 'NoSuchKey' ||
            code == 'NotFound' ||
            code == 'NoSuchObject') {
          continue;
        }
        throw Exception('S3 md5 下载失败: ${e.message}');
      }
    }
    return '';
  }

  @override
  Future<void> uploadRemoteMd5(String value) async {
    final bytes = utf8.encode(value);
    final data = Uint8List.fromList(bytes);
    await _minio.putObject(
      _settings.syncSetting.s3Setting.bucket,
      _md5ObjectKey,
      Stream<Uint8List>.value(data),
      size: bytes.length,
    );
  }

  @override
  Future<List<String>> listRemoteDataFiles() async {
    final files = <String>[];
    final seen = <String>{};
    for (final prefix in _listPrefixes) {
      final result = await _minio.listAllObjects(
        _settings.syncSetting.s3Setting.bucket,
        prefix: prefix,
        recursive: true,
      );
      for (final object in result.objects) {
        final key = object.key;
        if (key == null || key.isEmpty) {
          continue;
        }

        final normalized = _normalizeObjectKey(key);
        if (!seen.add(normalized)) {
          continue;
        }
        files.add(normalized);
      }
    }
    return files;
  }

  @override
  Future<List<int>> downloadRemoteFile(String remotePath) async {
    final objectKey = _toManagedObjectKey(remotePath);
    final stream = await _minio.getObject(
      _settings.syncSetting.s3Setting.bucket,
      objectKey,
    );
    return _collectStream(stream);
  }

  @override
  Future<void> uploadRemoteFile(
    String remotePath,
    List<int> data, {
    String contentType = 'application/octet-stream',
  }) async {
    final remoteObject = _toManagedObjectKey(remotePath);

    await _minio.putObject(
      _settings.syncSetting.s3Setting.bucket,
      remoteObject,
      Stream<Uint8List>.value(Uint8List.fromList(data)),
      size: data.length,
    );
  }

  @override
  Future<void> deleteRemoteFiles(List<String> remotePaths) async {
    if (remotePaths.isEmpty) {
      return;
    }

    final normalizedPaths = remotePaths
        .map(_toManagedObjectKey)
        .where((path) => path.isNotEmpty)
        .toSet()
        .toList();

    if (normalizedPaths.isEmpty) {
      return;
    }

    for (final path in normalizedPaths) {
      try {
        await _minio.removeObject(_settings.syncSetting.s3Setting.bucket, path);
      } on MinioS3Error catch (e) {
        final code = e.error?.code;
        if (code == 'NoSuchKey' ||
            code == 'NotFound' ||
            code == 'NoSuchObject') {
          continue;
        }
        throw Exception('S3 文件删除失败: ${e.message}');
      }
    }
  }

  String get _syncRootPrefix => '${ComicSyncCore.syncRemoteRootName}/';

  String get _legacyDataPrefix => '${ComicSyncCore.legacyDataRootName}/';

  String get _legacySettingsPrefix =>
      '${ComicSyncCore.legacySettingsRootName}/';

  List<String> get _listPrefixes => [
    _syncRootPrefix,
    _legacyDataPrefix,
    _legacySettingsPrefix,
  ];

  String get _md5ObjectKey =>
      '$_syncRootPrefix${ComicSyncCore.comicMd5FileName}';

  List<String> get _md5ObjectKeyCandidates => [_md5ObjectKey];

  String _toManagedObjectKey(String key) {
    final normalized = _normalizeObjectKey(key);
    if (normalized.isEmpty) {
      return _syncRootPrefix;
    }
    if (normalized.startsWith(_syncRootPrefix) ||
        normalized.startsWith(_legacyDataPrefix) ||
        normalized.startsWith(_legacySettingsPrefix)) {
      return normalized;
    }
    return '$_syncRootPrefix$normalized';
  }

  String _normalizeObjectKey(String key) {
    return key.replaceFirst(RegExp(r'^/+'), '');
  }

  Future<List<int>> _collectStream(Stream<List<int>> stream) async {
    final data = <int>[];
    await for (final chunk in stream) {
      data.addAll(chunk);
    }
    return data;
  }
}

Minio _createMinio(GlobalSettingState settings) {
  final resolved = _resolveEndpoint(
    settings.syncSetting.s3Setting.endpoint,
    settings.syncSetting.s3Setting.port,
  );
  return Minio(
    endPoint: resolved.host,
    port: resolved.port,
    accessKey: settings.syncSetting.s3Setting.accessKey,
    secretKey: settings.syncSetting.s3Setting.secretKey,
    useSSL: settings.syncSetting.s3Setting.useSSL,
    region: settings.syncSetting.s3Setting.region.isEmpty
        ? null
        : settings.syncSetting.s3Setting.region,
  );
}

class _S3Endpoint {
  const _S3Endpoint({required this.host, required this.port});

  final String host;
  final int? port;
}

_S3Endpoint _resolveEndpoint(String endpoint, int configuredPort) {
  final trimmed = endpoint.trim();
  if (trimmed.isEmpty) {
    throw Exception('S3 Endpoint 不能为空');
  }

  final raw = trimmed.startsWith('http://') || trimmed.startsWith('https://')
      ? trimmed
      : 'https://$trimmed';
  final uri = Uri.tryParse(raw);

  if (uri == null || uri.host.isEmpty) {
    throw Exception('S3 Endpoint 格式错误: $endpoint');
  }

  final port = configuredPort > 0
      ? configuredPort
      : (uri.hasPort ? uri.port : null);

  return _S3Endpoint(host: uri.host, port: port);
}
