import 'dart:convert';
import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:xml/xml.dart';
import 'package:zephyr/config/global/global.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/main.dart';

import 'comic_sync_core.dart';

class WebDavSyncService implements ComicSyncRemoteAdapter {
  WebDavSyncService(this._settings)
    : _dio = Dio(
        BaseOptions(
          baseUrl: _settings.webdavHost,
          headers: {
            'Authorization':
                'Basic ${base64Encode(utf8.encode('${_settings.webdavUsername}:${_settings.webdavPassword}'))}',
          },
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      ) {
    if (!isConfigured(_settings)) {
      throw Exception('WebDAV 配置不完整');
    }
  }

  final GlobalSettingState _settings;
  final Dio _dio;

  static bool isConfigured(GlobalSettingState settings) {
    return settings.webdavHost.trim().isNotEmpty &&
        settings.webdavUsername.trim().isNotEmpty &&
        settings.webdavPassword.isNotEmpty;
  }

  @override
  Future<void> testConnection() async {
    try {
      final response = await _dio.request(
        '/',
        options: Options(method: 'OPTIONS'),
      );
      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300) {
        return;
      }
      throw Exception('WebDAV 服务返回异常状态码: $code');
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          'WebDAV 服务返回错误: ${e.response?.statusCode}\n${e.response?.data}',
        );
      }
      throw Exception('连接失败: ${e.message}');
    }
  }

  @override
  Future<void> ensureRemoteReady() async {
    await _ensureDirectory(_dataRootDirPath);
    await _ensureDirectory(_settingsRootDirPath);
  }

  @override
  Future<String> downloadRemoteMd5() async {
    try {
      final response = await _dio.get(
        _remoteMd5Path,
        options: Options(responseType: ResponseType.plain),
      );

      if (response.statusCode == 200) {
        return (response.data ?? '').toString().trim();
      }

      throw Exception('md5 下载失败，状态码: ${response.statusCode}');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return '';
      }

      if (e.response != null) {
        throw Exception(
          'md5 下载失败: ${e.message}\n${e.response?.statusCode}\n${e.response?.data}',
        );
      }
      throw Exception('md5 下载失败: ${e.message}');
    }
  }

  @override
  Future<void> uploadRemoteMd5(String value) async {
    await _uploadData(
      _remoteMd5Path,
      utf8.encode(value),
      contentType: 'text/plain; charset=utf-8',
    );
  }

  @override
  Future<List<String>> listRemoteDataFiles() async {
    final paths = <String>{};
    final pendingDirs = Queue<String>()..add(_dataRootPath);
    final visitedDirs = <String>{};

    while (pendingDirs.isNotEmpty) {
      final currentDir = _normalizeRemotePath(pendingDirs.removeFirst());
      if (currentDir.isEmpty || !visitedDirs.add(currentDir)) {
        continue;
      }

      final entries = await _listDirectoryEntries(currentDir);
      for (final entry in entries) {
        if (entry.path == _dataRootPath) {
          continue;
        }

        paths.add(entry.path);
        if (entry.isDirectory) {
          pendingDirs.add(entry.path);
        }
      }
    }

    return paths.toList();
  }

  @override
  Future<List<int>> downloadRemoteFile(String remotePath) async {
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);
    final requestPath = _toManagedRemotePath(remotePath);

    for (var i = 0; i < maxRetries; i++) {
      try {
        final response = await _dio.get(
          requestPath,
          options: Options(responseType: ResponseType.bytes),
        );

        if (response.statusCode == 200) {
          return response.data as List<int>;
        }

        if (response.statusCode == 409) {
          await Future.delayed(retryDelay);
          continue;
        }

        throw Exception('文件下载失败，状态码: ${response.statusCode}');
      } on DioException catch (e) {
        if (e.response?.statusCode == 409) {
          await Future.delayed(retryDelay);
          continue;
        }
        throw Exception('文件下载失败: ${e.message}');
      }
    }

    throw Exception('文件下载失败，重试次数用尽');
  }

  @override
  Future<void> uploadRemoteFile(
    String remotePath,
    List<int> data, {
    String contentType = 'application/octet-stream',
  }) async {
    final normalized = _toManagedRemotePath(remotePath);
    await _uploadData(normalized, data, contentType: contentType);
  }

  @override
  Future<void> deleteRemoteFiles(List<String> remotePaths) async {
    final normalizedPaths = remotePaths
        .map(_toManagedRemotePath)
        .where((path) => path != _dataRootPath && _isManagedPath(path))
        .toSet()
        .toList();

    normalizedPaths.sort((a, b) {
      final aDepth = _pathDepth(a);
      final bDepth = _pathDepth(b);
      if (aDepth == bDepth) {
        return b.compareTo(a);
      }
      return bDepth.compareTo(aDepth);
    });

    for (final path in normalizedPaths) {
      try {
        final response = await _dio.delete(path);
        if (response.statusCode != 200 &&
            response.statusCode != 202 &&
            response.statusCode != 204) {
          logger.e('文件删除失败，状态码: ${response.statusCode}');
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          continue;
        }
        throw Exception(
          '文件删除失败: ${e.message}\n${e.response?.statusCode}\n${e.response?.data}',
        );
      }
    }
  }

  String get _dataRootPath => '/$appName';

  String get _dataRootDirPath => '$_dataRootPath/';

  String get _settingsRootPath => '/${appName}_setting';

  String get _settingsRootDirPath => '$_settingsRootPath/';

  String get _remoteMd5Path => '/$appName/${ComicSyncCore.md5FileName}';

  Future<void> _ensureDirectory(String dirPath) async {
    try {
      final response = await _dio.request(
        dirPath,
        options: Options(method: 'PROPFIND', headers: {'Depth': '0'}),
      );

      if (response.statusCode == 207) {
        return;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) {
        throw Exception('目录检查失败: ${e.message}');
      }
    }

    try {
      final mkcolResponse = await _dio.request(
        dirPath,
        options: Options(method: 'MKCOL'),
      );

      if (mkcolResponse.statusCode == 201 || mkcolResponse.statusCode == 204) {
        return;
      }

      throw Exception('目录创建失败，状态码: ${mkcolResponse.statusCode}');
    } on DioException catch (e) {
      if (e.response?.statusCode == 405) {
        return;
      }
      throw Exception('目录创建失败: ${e.message}');
    }
  }

  Future<List<_WebDavEntry>> _listDirectoryEntries(String directoryPath) async {
    final requestPath = _asDirectoryRequestPath(
      _toManagedRemotePath(directoryPath),
    );
    try {
      final response = await _dio.request(
        requestPath,
        options: Options(method: 'PROPFIND', headers: {'Depth': '1'}),
      );

      if (response.statusCode != 207) {
        throw Exception('WebDAV 服务返回异常状态码: ${response.statusCode}');
      }

      final xmlDoc = XmlDocument.parse(response.data.toString());
      final namespacePrefix = _getNamespacePrefix(xmlDoc);
      final responseElement = '$namespacePrefix:response';
      final propstatElement = '$namespacePrefix:propstat';
      final propElement = '$namespacePrefix:prop';
      final displayNameElement = '$namespacePrefix:displayname';
      final hrefElement = '$namespacePrefix:href';

      final entries = <_WebDavEntry>[];
      final elements = xmlDoc.findAllElements(responseElement);
      for (final element in elements) {
        final propstat = element.findElements(propstatElement);
        if (propstat.isEmpty) {
          continue;
        }

        final props = propstat.first.findElements(propElement);
        if (props.isEmpty) {
          continue;
        }

        final prop = props.first;
        final displayName = _findFirstInnerText(prop, displayNameElement);
        final href = _findFirstInnerText(element, hrefElement);
        final remotePath = _resolveRemoteFilePath(
          href: href,
          displayName: displayName,
        );
        final normalizedPath = _normalizeRemotePath(remotePath);

        if (normalizedPath.isEmpty || !_isManagedPath(normalizedPath)) {
          continue;
        }

        entries.add(
          _WebDavEntry(
            path: normalizedPath,
            isDirectory: _xmlIsDirectory(prop, namespacePrefix),
          ),
        );
      }

      return entries;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return [];
      }
      if (e.response != null) {
        throw Exception(
          'WebDAV 服务请求失败: ${e.message}\n${e.response?.statusCode}\n${e.response?.data}',
        );
      }
      throw Exception('WebDAV 服务请求失败: ${e.message}');
    } catch (e) {
      throw Exception('WebDAV 服务请求失败: $e');
    }
  }

  Future<void> _uploadData(
    String remotePath,
    List<int> data, {
    String contentType = 'application/octet-stream',
  }) async {
    try {
      final response = await _dio.put(
        remotePath,
        data: Stream.fromIterable([data]),
        options: Options(headers: {'Content-Type': contentType}),
      );

      if (response.statusCode == 201 ||
          response.statusCode == 204 ||
          response.statusCode == 200) {
        return;
      }

      throw Exception('文件上传失败，状态码: ${response.statusCode}');
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          '文件上传失败: ${e.message}\n${e.response?.statusCode}\n${e.response?.data}',
        );
      }
      throw Exception('文件上传失败: ${e.message}');
    }
  }

  String _getNamespacePrefix(XmlDocument xmlDoc) {
    final rootElement = xmlDoc.rootElement;
    final namespacePrefix = rootElement.name.prefix;
    return namespacePrefix ?? 'd';
  }

  bool _xmlIsDirectory(XmlElement prop, String namespacePrefix) {
    final resourceTypeElement = '$namespacePrefix:resourcetype';
    final collectionElement = '$namespacePrefix:collection';
    final resourceType = prop.findElements(resourceTypeElement);
    if (resourceType.isEmpty) {
      return false;
    }
    return resourceType.first.findElements(collectionElement).isNotEmpty;
  }

  String? _findFirstInnerText(XmlElement parent, String elementName) {
    final elements = parent.findElements(elementName);
    if (elements.isEmpty) {
      return null;
    }
    final value = elements.first.innerText.trim();
    return value.isEmpty ? null : value;
  }

  String _resolveRemoteFilePath({String? href, String? displayName}) {
    if (href != null && href.isNotEmpty) {
      final uri = Uri.tryParse(href);
      final path = uri?.path.isNotEmpty == true ? uri!.path : href;
      if (path.isEmpty) {
        return '';
      }
      return path.startsWith('/') ? path : '/$path';
    }

    if (displayName == null || displayName.isEmpty) {
      return '';
    }

    return '/$appName/${Uri.encodeComponent(displayName)}';
  }

  String _toManagedRemotePath(String remotePath) {
    final normalized = _normalizeRemotePath(remotePath);
    if (normalized.isEmpty) {
      throw Exception('远端路径不能为空');
    }

    if (_isManagedPath(normalized)) {
      return normalized;
    }

    final joined = '$_dataRootPath/$normalized';
    return joined.replaceAll(RegExp(r'/+'), '/');
  }

  bool _isManagedPath(String remotePath) {
    return remotePath == _dataRootPath ||
        remotePath.startsWith('$_dataRootPath/') ||
        remotePath == _settingsRootPath ||
        remotePath.startsWith('$_settingsRootPath/');
  }

  String _normalizeRemotePath(String remotePath) {
    final trimmed = remotePath.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final uri = Uri.tryParse(trimmed);
    final rawPath = uri?.path.isNotEmpty == true ? uri!.path : trimmed;
    var normalized = rawPath
        .replaceAll('\\', '/')
        .replaceAll(RegExp(r'/+'), '/');
    if (!normalized.startsWith('/')) {
      normalized = '/$normalized';
    }
    if (normalized.length > 1 && normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  String _asDirectoryRequestPath(String remotePath) {
    final normalized = _normalizeRemotePath(remotePath);
    if (normalized.isEmpty) {
      return _dataRootDirPath;
    }
    return '$normalized/';
  }

  int _pathDepth(String remotePath) {
    return _normalizeRemotePath(
      remotePath,
    ).split('/').where((item) => item.isNotEmpty).length;
  }
}

class _WebDavEntry {
  const _WebDavEntry({required this.path, required this.isDirectory});

  final String path;
  final bool isDirectory;
}
