import 'dart:collection';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:encrypter_plus/encrypter_plus.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:xml/xml.dart';
import 'package:zephyr/config/global/global.dart';

import '../../../main.dart';
import '../object_box/model.dart';

final String version = "2.3.0";
final String _webDavMd5FileName = '$appName.md5';
String get _webDavMd5RemotePath => '/$appName/$_webDavMd5FileName';

// 测试 WebDAV 服务是否可用
Future<void> testWebDavServer() async {
  final settings = objectbox.userSettingBox.get(1)!.globalSetting;
  if (settings.webdavHost.isEmpty ||
      settings.webdavUsername.isEmpty ||
      settings.webdavPassword.isEmpty) {
    throw Exception('WebDAV 配置不完整');
  }

  final dio = Dio(
    BaseOptions(
      baseUrl: settings.webdavHost, // WebDAV 服务器地址
      headers: {
        'Authorization':
            'Basic ${base64Encode(utf8.encode('${settings.webdavUsername}:${settings.webdavPassword}'))}',
      },
      connectTimeout: const Duration(seconds: 10), // 连接超时时间
      receiveTimeout: const Duration(seconds: 10), // 接收超时时间
    ),
  );

  try {
    // 发送 OPTIONS 请求测试服务是否可用
    final response = await dio.request(
      '/',
      options: Options(method: 'OPTIONS'),
    );

    // 检查状态码
    if (response.statusCode == 200) {
      logger.d('WebDAV 服务可用');
    } else {
      throw Exception('WebDAV 服务返回异常状态码: ${response.statusCode}');
    }
  } on DioException catch (e) {
    // 捕获 Dio 的错误
    if (e.response != null) {
      // 如果服务器返回了响应，将错误信息和返回值合并后抛出
      throw Exception(
        'WebDAV 服务返回错误: ${e.response?.statusCode}\n${e.response?.data}',
      );
    } else {
      // 如果只是 Dio 的错误（如网络连接失败、超时等），直接抛出错误
      throw Exception('连接失败: ${e.message}');
    }
  } catch (e) {
    // 捕获其他未知错误
    throw Exception('未知错误: $e');
  }
}

Dio getWebDavDio() {
  final settings = objectbox.userSettingBox.get(1)!.globalSetting;
  if (settings.webdavHost.isEmpty ||
      settings.webdavUsername.isEmpty ||
      settings.webdavPassword.isEmpty) {
    throw Exception('WebDAV 配置不完整');
  }

  final dio = Dio(
    BaseOptions(
      baseUrl: settings.webdavHost, // WebDAV服务器地址
      headers: {
        'Authorization':
            'Basic ${base64Encode(utf8.encode('${settings.webdavUsername}:${settings.webdavPassword}'))}',
      },
    ),
  );

  return dio;
}

// 创建目录（如果不存在）
Future<void> createParentDirectory(String path) async {
  Dio? dio = getWebDavDio();

  try {
    // 检查目录是否已经存在
    Response response = await dio.request(
      path,
      options: Options(method: 'PROPFIND'),
    );

    // 如果目录存在（返回 207 状态码），则跳过创建
    if (response.statusCode == 207) {
      logger.d('目录已存在: $path');
      return;
    }
  } on DioException catch (e) {
    // 如果目录不存在（返回 404 状态码），则创建目录
    if (e.response?.statusCode == 404) {
      try {
        // 发送 MKCOL 请求创建目录
        Response mkcolResponse = await dio.request(
          path,
          options: Options(method: 'MKCOL'),
        );

        if (mkcolResponse.statusCode == 201) {
          logger.d('目录创建成功: $path');
        } else {
          throw Exception('目录创建失败，状态码: ${mkcolResponse.statusCode}');
        }
      } on DioException catch (e) {
        throw Exception('目录创建失败: ${e.message}');
      }
    } else {
      throw Exception('目录检查失败: ${e.message}');
    }
  }
}

// 检查路径是否是文件夹
Future<bool> isDirectory(String path) async {
  Dio dio = getWebDavDio();

  try {
    // 发送 PROPFIND 请求获取路径属性
    Response response = await dio.request(
      path,
      options: Options(method: 'PROPFIND'),
    );

    // 解析响应，检查是否是文件夹
    if (response.statusCode == 207) {
      logger.d('路径是文件夹: $path');
      return true;
    } else {
      throw Exception('路径不是文件夹，状态码: ${response.statusCode}');
    }
  } on DioException catch (e) {
    if (e.response != null) {
      throw Exception(
        '检查路径失败: ${e.message}\n${e.response?.statusCode}\n${e.response?.data}',
      );
    } else {
      throw Exception('检查路径失败: ${e.message}');
    }
  }
}

// 检查固定目录是否存在，如果不存在则创建
Future<void> checkOrCreateFixedDirectory() async {
  // 固定目录路径
  String dirPath = '/$appName/';

  // 获取 Dio 实例
  Dio dio = getWebDavDio();

  try {
    // 发送 HEAD 请求检查目录是否存在
    Response headResponse = await dio.head(dirPath);

    // 如果目录存在
    if (headResponse.statusCode == 200) {
      logger.d('目录已存在，无需创建');
      return;
    }
  } on DioException catch (e) {
    // 如果目录不存在（状态码为 404）
    if (e.response?.statusCode == 404) {
      logger.d('目录不存在，尝试创建新目录');

      try {
        // 发送 MKCOL 请求创建新目录
        Response mkcolResponse = await dio.request(
          dirPath,
          options: Options(method: 'MKCOL'),
        );

        // 检查 MKCOL 请求是否成功
        if (mkcolResponse.statusCode == 201 ||
            mkcolResponse.statusCode == 204) {
          logger.d('目录创建成功');
        } else {
          throw Exception('目录创建失败，状态码: ${mkcolResponse.statusCode}');
        }
      } on DioException catch (e) {
        if (e.response != null) {
          throw Exception(
            '目录创建失败: ${e.message}\n${e.response?.statusCode}\n${e.response?.data}',
          );
        } else {
          throw Exception('目录创建失败: ${e.message}');
        }
      }
    } else if (e.response?.statusCode == 409) {
      logger.e('路径冲突，可能是父目录不存在');

      // 获取父目录路径
      String parentDir = dirPath
          .split('/')
          .sublist(0, dirPath.split('/').length - 1)
          .join('/');

      // 检查父目录是否存在
      if (parentDir.isNotEmpty) {
        await checkOrCreateFixedDirectory(); // 递归创建父目录
      }

      // 再次尝试创建目录
      try {
        Response mkcolResponse = await dio.request(
          dirPath,
          options: Options(method: 'MKCOL'),
        );

        if (mkcolResponse.statusCode == 201 ||
            mkcolResponse.statusCode == 204) {
          logger.d('目录创建成功');
        } else {
          throw Exception('目录创建失败，状态码: ${mkcolResponse.statusCode}');
        }
      } on DioException catch (e) {
        if (e.response != null) {
          throw Exception(
            '目录创建失败: ${e.message}\n${e.response?.statusCode}\n${e.response?.data}',
          );
        } else {
          throw Exception('目录创建失败: ${e.message}');
        }
      }
    } else {
      if (e.response != null) {
        throw Exception(
          '请求失败: ${e.message}\n${e.response?.statusCode}\n${e.response?.data}',
        );
      } else {
        throw Exception('请求失败: ${e.message}');
      }
    }
  }
}

// 判断是否是文件夹
bool xmlIsDirectory(XmlElement prop, String namespacePrefix) {
  // 动态构建元素名称
  var resourceTypeElement = '$namespacePrefix:resourcetype';
  var collectionElement = '$namespacePrefix:collection';

  // 检查 <resourcetype> 节点下是否有 <collection />
  var resourceType = prop.findElements(resourceTypeElement).firstOrNull;
  if (resourceType != null) {
    return resourceType.findElements(collectionElement).isNotEmpty;
  }
  return false;
}

// 获取 WebDAV 文件列表
Future<List<String>> fetchWebDAVFiles() async {
  List<String> urlList = [];

  try {
    final remoteMd5 = await _downloadMd5FromWebDav();
    final localMd5 = objectbox.userSettingBox.get(1)!.globalSetting.md5;

    if (remoteMd5.isNotEmpty && remoteMd5 == localMd5) {
      logger.d('云端与本地 md5 一致，跳过同步');
      return urlList;
    }

    // 获取 Dio 实例
    final dio = getWebDavDio();

    // 发送 PROPFIND 请求
    Response response = await dio.request(
      '/$appName/',
      options: Options(method: 'PROPFIND'),
    );

    // 解析 XML 响应
    if (response.statusCode == 207) {
      var xmlDoc = XmlDocument.parse(response.data);

      try {
        // 获取命名空间前缀
        var namespacePrefix = _getNamespacePrefix(xmlDoc);

        // 动态构建元素名称
        var responseElement = '$namespacePrefix:response';
        var propstatElement = '$namespacePrefix:propstat';
        var propElement = '$namespacePrefix:prop';
        var displayNameElement = '$namespacePrefix:displayname';

        var elements = xmlDoc.findAllElements(responseElement);

        for (var element in elements) {
          var propstat = element.findElements(propstatElement).first;
          var prop = propstat.findElements(propElement).first;

          // 获取 displayname
          var displayName = prop
              .findElements(displayNameElement)
              .firstOrNull
              ?.innerText;

          if (displayName != null &&
              displayName != _webDavMd5FileName &&
              !xmlIsDirectory(prop, namespacePrefix)) {
            urlList.add("/$appName/$displayName");
          }
        }
      } catch (e) {
        throw Exception('解析 XML 响应失败: $e');
      }
    } else {
      throw Exception('WebDAV 服务返回异常状态码: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('WebDAV 服务请求失败: $e');
  }

  return urlList;
}

// 获取命名空间前缀
String _getNamespacePrefix(XmlDocument xmlDoc) {
  var rootElement = xmlDoc.rootElement;
  var namespacePrefix = rootElement.name.prefix;

  // 如果未找到前缀，默认使用 'd'
  return namespacePrefix ?? 'd';
}

Future<void> uploadFile2WebDav() async {
  final localMd5 = objectbox.userSettingBox.get(1)!.globalSetting.md5;
  final remoteMd5 = await _downloadMd5FromWebDav();

  if (remoteMd5.isNotEmpty && remoteMd5 == localMd5) {
    logger.d('云端与本地 md5 一致，跳过上传');
    return;
  }

  var allHistory = await objectbox.bikaHistoryBox.getAllAsync();
  allHistory.sort((a, b) => b.history.compareTo(a.history));

  final comicHistoriesJsonString = allHistory
      .map((comic) => comic.toJson())
      .toList();

  final jmFavorite = await objectbox.jmFavoriteBox.getAllAsync();

  final jmFavoritesJsonString = jmFavorite.map((jm) => jm.toJson()).toList();

  final jmHistory = await objectbox.jmHistoryBox.getAllAsync();

  final jmHistoriesJsonString = jmHistory.map((jm) => jm.toJson()).toList();

  final data = {
    'comicHistories': comicHistoriesJsonString,
    'jmFavorites': jmFavoritesJsonString,
    'jmHistories': jmHistoriesJsonString,
  };

  // 使用 compute 在后台执行加密和压缩
  final compressedBytes = await compute(_encryptAndCompress, jsonEncode(data));

  if (compressedBytes == null) {
    throw Exception('加密压缩失败');
  }

  final currentMd5 = _calculateMd5(compressedBytes);

  if (remoteMd5.isNotEmpty && remoteMd5 == currentMd5) {
    logger.d('云端数据已是最新，仅更新本地 md5');
    _updateLocalMd5(currentMd5);
    return;
  }

  var time = DateTime.now().toUtc().millisecondsSinceEpoch;

  await _uploadDataToWebDav(
    compressedBytes,
    '/$appName/${appName}_${time}_$version.gz',
  );

  await _uploadMd5ToWebDav(currentMd5);
  _updateLocalMd5(currentMd5);
}

List<int>? _encryptAndCompress(String data) {
  // 命令行解密方式
  // gunzip history.gz
  // base64 --decode history > encrypted.bin
  // openssl enc -d -aes-256-ctr -iv 37714677547877482669797577333566 -K 5859214578336a3368505e42475046616e59456a4241214c216f44326b6b434e -in encrypted.bin -out decrypted.json

  try {
    final key = Key.fromUtf8("XY!Ex3j3hP^BGPFanYEjBA!L!oD2kkCN");
    final iv = IV.fromUtf8("7qFwTxwH&iyuw35f");
    final encrypter = Encrypter(AES(key, mode: AESMode.ctr));
    final encrypted = encrypter.encrypt(data, iv: iv);
    final jsonBytes = utf8.encode(encrypted.base64);
    return GZipEncoder().encode(jsonBytes);
  } catch (e) {
    return null;
  }
}

Future<void> _uploadDataToWebDav(
  List<int> data,
  String remotePath, {
  String contentType = 'application/octet-stream',
}) async {
  final dio = getWebDavDio();

  try {
    // 发送 PUT 请求上传数据
    final response = await dio.put(
      remotePath,
      data: Stream.fromIterable([data]), // 将字节数据转换为流
      options: Options(headers: {'Content-Type': contentType}),
    );

    // 检查状态码
    if (response.statusCode == 201 || response.statusCode == 204) {
      logger.d('文件上传成功');
    } else {
      throw Exception('文件上传失败，状态码: ${response.statusCode}');
    }
  } on DioException catch (e) {
    if (e.response != null) {
      throw Exception(
        '文件上传失败: ${e.message}\n${e.response?.statusCode}\n${e.response?.data}',
      );
    } else {
      throw Exception('文件上传失败: ${e.message}');
    }
  } catch (e) {
    throw Exception('未知错误: $e');
  }
}

String _calculateMd5(List<int> data) {
  return md5.convert(data).toString();
}

Future<String> _downloadMd5FromWebDav() async {
  final dio = getWebDavDio();

  try {
    final response = await dio.get(
      _webDavMd5RemotePath,
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
  } catch (e) {
    throw Exception('md5 下载失败: $e');
  }
}

Future<void> _uploadMd5ToWebDav(String value) async {
  await _uploadDataToWebDav(
    utf8.encode(value),
    _webDavMd5RemotePath,
    contentType: 'text/plain; charset=utf-8',
  );
}

void _updateLocalMd5(String value) {
  final userSettings = objectbox.userSettingBox.get(1);
  if (userSettings == null || userSettings.globalSetting.md5 == value) {
    return;
  }

  userSettings.globalSetting = userSettings.globalSetting.copyWith(md5: value);
  objectbox.userSettingBox.put(userSettings);
}

Future<String> getNeedDownloadUrl(List<String> urlList) async {
  String latestUrl = '';
  int latestTimestamp = -1;
  final regex = RegExp(
    '${RegExp.escape(appName)}_(\\d+)_${RegExp.escape(version)}\\.gz',
  );

  for (var url in urlList) {
    final match = regex.firstMatch(url);
    if (match == null) {
      continue;
    }

    final timestamp = int.tryParse(match.group(1)!);
    if (timestamp == null) {
      continue;
    }

    if (timestamp > latestTimestamp) {
      latestTimestamp = timestamp;
      latestUrl = url;
    }
  }

  return latestUrl;
}

Future<Map<String, dynamic>> getHistoryFromWebdav(String remotePath) async {
  // 下载文件
  final compressedBytes = await _downloadFromWebDav(remotePath);

  // 使用 compute 在后台执行解压和解密操作
  final comicHistoriesJson = await compute(
    _decompressAndDecrypt,
    compressedBytes,
  );

  if (comicHistoriesJson.isEmpty) {
    throw Exception('下载数据为空');
  }

  final data = jsonDecode(comicHistoriesJson) as Map<String, dynamic>;

  return data;
}

String _decompressAndDecrypt(List<int> compressedBytes) {
  try {
    // 解压缩数据
    final jsonBytes = GZipDecoder().decodeBytes(compressedBytes);

    // 将字节数据转换为字符串
    final encryptedBase64 = utf8.decode(jsonBytes);

    // 解密数据
    final key = Key.fromUtf8("XY!Ex3j3hP^BGPFanYEjBA!L!oD2kkCN");
    final iv = IV.fromUtf8("7qFwTxwH&iyuw35f");
    final encrypter = Encrypter(AES(key, mode: AESMode.ctr));

    // 解密
    final encrypted = Encrypted.fromBase64(encryptedBase64);
    final decrypted = encrypter.decrypt(encrypted, iv: iv);

    return decrypted;
  } catch (e) {
    logger.d('解压或解密失败: $e');
    return ''; // 发生错误时返回空列表
  }
}

Future<List<int>> _downloadFromWebDav(String remotePath) async {
  final dio = getWebDavDio();

  const maxRetries = 3;
  const retryDelay = Duration(seconds: 2);

  for (var i = 0; i < maxRetries; i++) {
    try {
      final response = await dio.get(
        remotePath,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        logger.d('文件下载成功');
        return response.data as List<int>;
      } else if (response.statusCode == 409) {
        logger.d('冲突，重试中...');
        await Future.delayed(retryDelay);
        continue;
      } else {
        throw Exception('文件下载失败，状态码: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        logger.d('冲突，重试中...');
        await Future.delayed(retryDelay);
        continue;
      } else {
        throw Exception('文件下载失败: ${e.message}');
      }
    } catch (e) {
      throw Exception('未知错误: $e');
    }
  }

  throw Exception('文件下载失败，重试次数用尽');
}

Future<void> updateHistory(Map<String, dynamic> data) async {
  // 合并本地和云端历史记录
  final localHistories = await objectbox.bikaHistoryBox.getAllAsync();
  final cloudHistories = (data['comicHistories'] as List<dynamic>)
      .map((comic) => BikaComicHistory.fromJson(comic))
      .toList();
  final combined = [...cloudHistories, ...localHistories];

  // 按时间降序排序（最新的在前）
  combined.sort((a, b) => b.history.compareTo(a.history));

  // 使用 LinkedHashMap 去重（保留最先出现的记录，即最新记录）
  final uniqueMap = LinkedHashMap<String, BikaComicHistory>(
    equals: (a, b) => a == b,
    hashCode: (e) => e.hashCode,
  );
  for (var item in combined) {
    uniqueMap.putIfAbsent(item.comicId, () => item);
  }

  // 准备最终列表并重置 ID
  final finalList = uniqueMap.values.toList();
  for (var item in finalList) {
    item.id = 0; // ObjectBox 插入需要 ID 为 0
  }

  // 更新数据库
  await objectbox.bikaHistoryBox.removeAllAsync();
  await objectbox.bikaHistoryBox.putManyAsync(finalList);

  final jmLocalFavorites = await objectbox.jmFavoriteBox.getAllAsync();
  final jmCloudFavorites = (data['jmFavorites'] as List<dynamic>)
      .map((jm) => JmFavorite.fromJson(jm))
      .toList();

  final jmCombinedFavorites = [...jmCloudFavorites, ...jmLocalFavorites];

  jmCombinedFavorites.sort((a, b) => b.history.compareTo(a.history));

  final jmFavoriteUniqueMap = LinkedHashMap<String, JmFavorite>(
    equals: (a, b) => a == b,
    hashCode: (e) => e.hashCode,
  );
  for (var item in jmCombinedFavorites) {
    jmFavoriteUniqueMap.putIfAbsent(item.comicId, () => item);
  }

  // 准备最终列表并重置 ID
  final jmFavoriteFinalList = jmFavoriteUniqueMap.values.toList();
  for (var item in jmFavoriteFinalList) {
    item.id = 0; // ObjectBox 插入需要 ID 为 0
  }

  // 更新数据库
  await objectbox.jmFavoriteBox.removeAllAsync();
  await objectbox.jmFavoriteBox.putManyAsync(jmFavoriteFinalList);

  final jmLocalHistories = await objectbox.jmHistoryBox.getAllAsync();
  final jmCloudHistories = (data['jmHistories'] as List<dynamic>)
      .map((jm) => JmHistory.fromJson(jm))
      .toList();

  final jmCombinedHistories = [...jmCloudHistories, ...jmLocalHistories];

  jmCombinedHistories.sort((a, b) => b.history.compareTo(a.history));

  final jmHistoryUniqueMap = LinkedHashMap<String, JmHistory>(
    equals: (a, b) => a == b,
    hashCode: (e) => e.hashCode,
  );
  for (var item in jmCombinedHistories) {
    jmHistoryUniqueMap.putIfAbsent(item.comicId, () => item);
  }

  // 准备最终列表并重置 ID
  final jmHistoryFinalList = jmHistoryUniqueMap.values.toList();
  for (var item in jmHistoryFinalList) {
    item.id = 0; // ObjectBox 插入需要 ID 为 0
  }

  // 更新数据库
  await objectbox.jmHistoryBox.removeAllAsync();
  await objectbox.jmHistoryBox.putManyAsync(jmHistoryFinalList);

  logger.d(
    '更新历史记录成功，共 ${finalList.length + jmFavoriteFinalList.length + jmHistoryFinalList.length} 条记录',
  );
}

Future<void> deleteFileFromWebDav(List<String> remotePath) async {
  final dio = getWebDavDio();

  for (var path in remotePath) {
    if (path == _webDavMd5RemotePath || path.endsWith('/$_webDavMd5FileName')) {
      continue;
    }

    try {
      final response = await dio.delete(path);

      if (response.statusCode != 200 && response.statusCode != 204) {
        logger.e('文件删除失败，状态码: ${response.statusCode}');
        continue; // 或者 throw 根据你的需求
      }

      logger.d('文件删除成功: $path');
    } on DioException catch (e) {
      final errorMessage = e.response != null
          ? '文件删除失败: ${e.message}\n${e.response?.statusCode}\n${e.response?.data}'
          : '文件删除失败: ${e.message}';

      throw Exception(errorMessage);
    } catch (e, stackTrace) {
      Error.throwWithStackTrace(Exception('未知错误: $e'), stackTrace);
    }
  }
}
