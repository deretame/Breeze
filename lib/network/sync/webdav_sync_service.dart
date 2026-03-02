import 'dart:convert';

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
    final dirPath = '/$appName/';

    try {
      final response = await _dio.request(
        dirPath,
        options: Options(method: 'PROPFIND'),
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
    final urlList = <String>[];

    try {
      final response = await _dio.request(
        '/$appName/',
        options: Options(method: 'PROPFIND'),
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
        final displayName = prop.findElements(displayNameElement).isEmpty
            ? null
            : prop.findElements(displayNameElement).first.innerText;

        if (displayName == null ||
            displayName == ComicSyncCore.md5FileName ||
            _xmlIsDirectory(prop, namespacePrefix) ||
            !ComicSyncCore.isSyncDataFileName(displayName)) {
          continue;
        }

        urlList.add('/$appName/$displayName');
      }
    } catch (e) {
      throw Exception('WebDAV 服务请求失败: $e');
    }

    return urlList;
  }

  @override
  Future<List<int>> downloadRemoteFile(String remotePath) async {
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);

    for (var i = 0; i < maxRetries; i++) {
      try {
        final response = await _dio.get(
          remotePath,
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
    final normalized = remotePath.startsWith('/')
        ? remotePath
        : '/$appName/$remotePath';
    await _uploadData(normalized, data, contentType: contentType);
  }

  @override
  Future<void> deleteRemoteFiles(List<String> remotePaths) async {
    for (final path in remotePaths) {
      try {
        final response = await _dio.delete(path);
        if (response.statusCode != 200 && response.statusCode != 204) {
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

  String get _remoteMd5Path => '/$appName/${ComicSyncCore.md5FileName}';

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
}
