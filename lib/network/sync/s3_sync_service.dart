import 'dart:convert';
import 'dart:typed_data';

import 'package:minio/minio.dart';
import 'package:zephyr/config/global/global.dart';
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
    return settings.s3Setting.endpoint.trim().isNotEmpty &&
        settings.s3Setting.accessKey.trim().isNotEmpty &&
        settings.s3Setting.secretKey.isNotEmpty &&
        settings.s3Setting.bucket.trim().isNotEmpty;
  }

  @override
  Future<void> testConnection() async {
    final exists = await _minio.bucketExists(_settings.s3Setting.bucket);
    if (!exists) {
      throw Exception('S3 Bucket 不存在或没有访问权限: ${_settings.s3Setting.bucket}');
    }
  }

  @override
  Future<void> ensureRemoteReady() async {}

  @override
  Future<String> downloadRemoteMd5() async {
    try {
      final stream = await _minio.getObject(
        _settings.s3Setting.bucket,
        _md5ObjectKey,
      );
      final bytes = await _collectStream(stream);
      return utf8.decode(bytes).trim();
    } on MinioS3Error catch (e) {
      final code = e.error?.code;
      if (code == 'NoSuchKey' || code == 'NotFound' || code == 'NoSuchObject') {
        return '';
      }
      throw Exception('S3 md5 下载失败: ${e.message}');
    }
  }

  @override
  Future<void> uploadRemoteMd5(String value) async {
    final bytes = utf8.encode(value);
    await _minio.putObject(
      _settings.s3Setting.bucket,
      _md5ObjectKey,
      Stream<Uint8List>.value(Uint8List.fromList(bytes)),
      size: bytes.length,
    );
  }

  @override
  Future<List<String>> listRemoteDataFiles() async {
    final result = await _minio.listAllObjects(
      _settings.s3Setting.bucket,
      prefix: _prefix,
      recursive: true,
    );

    final files = <String>[];
    for (final object in result.objects) {
      final key = object.key;
      if (key == null || key.isEmpty || key == _md5ObjectKey) {
        continue;
      }
      final fileName = key.split('/').last;
      if (!ComicSyncCore.isSyncDataFileName(fileName)) {
        continue;
      }
      files.add(key);
    }
    return files;
  }

  @override
  Future<List<int>> downloadRemoteFile(String remotePath) async {
    final stream = await _minio.getObject(
      _settings.s3Setting.bucket,
      remotePath,
    );
    return _collectStream(stream);
  }

  @override
  Future<void> uploadRemoteFile(
    String remotePath,
    List<int> data, {
    String contentType = 'application/octet-stream',
  }) async {
    final remoteObject = remotePath.startsWith(_prefix)
        ? remotePath
        : '$_prefix$remotePath';

    await _minio.putObject(
      _settings.s3Setting.bucket,
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

    await _minio.removeObjects(_settings.s3Setting.bucket, remotePaths);
  }

  String get _prefix => '$appName/';

  String get _md5ObjectKey => '$_prefix${ComicSyncCore.md5FileName}';

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
    settings.s3Setting.endpoint,
    settings.s3Setting.port,
  );
  return Minio(
    endPoint: resolved.host,
    port: resolved.port,
    accessKey: settings.s3Setting.accessKey,
    secretKey: settings.s3Setting.secretKey,
    useSSL: settings.s3Setting.useSSL,
    region: settings.s3Setting.region.isEmpty
        ? null
        : settings.s3Setting.region,
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
