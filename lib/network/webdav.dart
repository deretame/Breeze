import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/cupertino.dart';
import 'package:xml/xml.dart' as xml;

import '../../../main.dart';
import '../object_box/model.dart';

// 测试 WebDAV 服务是否可用
Future<void> testWebDavServer() async {
  if (globalSetting.webdavHost.isEmpty ||
      globalSetting.webdavUsername.isEmpty ||
      globalSetting.webdavPassword.isEmpty) {
    throw Exception('WebDAV 配置不完整');
  }

  final dio = Dio(BaseOptions(
    baseUrl: globalSetting.webdavHost, // WebDAV 服务器地址
    headers: {
      'Authorization': 'Basic ${base64Encode(
        utf8.encode(
            '${globalSetting.webdavUsername}:${globalSetting.webdavPassword}'),
      )}',
    },
    connectTimeout: const Duration(seconds: 10), // 连接超时时间
    receiveTimeout: const Duration(seconds: 10), // 接收超时时间
  ));

  try {
    // 发送 HEAD 请求测试服务是否可用
    final response = await dio.head('/');

    // 检查状态码
    if (response.statusCode == 200) {
      debugPrint('WebDAV 服务可用');
    } else {
      throw Exception('WebDAV 服务返回异常状态码: ${response.statusCode}');
    }
  } on DioException catch (e) {
    // 捕获 Dio 的错误
    if (e.response != null) {
      // 如果服务器返回了响应，将错误信息和返回值合并后抛出
      throw Exception(
          'WebDAV 服务返回错误: ${e.response?.statusCode}\n${e.response?.data}');
    } else {
      // 如果只是 Dio 的错误（如网络连接失败、超时等），直接抛出错误
      throw Exception('连接失败: ${e.message}');
    }
  } catch (e) {
    // 捕获其他未知错误
    throw Exception('未知错误: $e');
  }
}

Dio? getWebDavDio() {
  if (globalSetting.webdavHost.isEmpty ||
      globalSetting.webdavUsername.isEmpty ||
      globalSetting.webdavPassword.isEmpty) {
    throw Exception('WebDAV 配置不完整');
  }

  final dio = Dio(BaseOptions(
    baseUrl: globalSetting.webdavHost, // WebDAV服务器地址
    headers: {
      'Authorization': 'Basic ${base64Encode(
        utf8.encode(
          '${globalSetting.webdavUsername}:${globalSetting.webdavPassword}',
        ),
      )}',
    },
  ));

  return dio;
}

// 创建目录（如果不存在）
Future<void> createParentDirectory(String path) async {
  Dio? dio = getWebDavDio();
  if (dio == null) {
    throw Exception('WebDAV 配置不完整');
  }

  try {
    // 检查目录是否已经存在
    Response response = await dio.request(
      path,
      options: Options(method: 'PROPFIND'),
    );

    // 如果目录存在（返回 207 状态码），则跳过创建
    if (response.statusCode == 207) {
      debugPrint('目录已存在: $path');
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
          debugPrint('目录创建成功: $path');
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
  Dio? dio = getWebDavDio();
  if (dio == null) {
    throw Exception('WebDAV 配置不完整');
  }

  try {
    // 发送 PROPFIND 请求获取路径属性
    Response response = await dio.request(
      path,
      options: Options(method: 'PROPFIND'),
    );

    // 解析响应，检查是否是文件夹
    if (response.statusCode == 207) {
      debugPrint('路径是文件夹: $path');
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
  const String dirPath = '/Breeze/';

  // 获取 Dio 实例
  Dio? dio = getWebDavDio();
  if (dio == null) {
    throw Exception('WebDAV 配置不完整');
  }

  try {
    // 发送 HEAD 请求检查目录是否存在
    Response headResponse = await dio.head(dirPath);

    // 如果目录存在
    if (headResponse.statusCode == 200) {
      debugPrint('目录已存在，无需创建');
      return;
    }
  } on DioException catch (e) {
    // 如果目录不存在（状态码为 404）
    if (e.response?.statusCode == 404) {
      debugPrint('目录不存在，尝试创建新目录');

      try {
        // 发送 MKCOL 请求创建新目录
        Response mkcolResponse = await dio.request(
          dirPath,
          options: Options(method: 'MKCOL'),
        );

        // 检查 MKCOL 请求是否成功
        if (mkcolResponse.statusCode == 201 ||
            mkcolResponse.statusCode == 204) {
          debugPrint('目录创建成功');
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
      debugPrint('路径冲突，可能是父目录不存在');

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
          debugPrint('目录创建成功');
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
bool xmlIsDirectory(xml.XmlElement prop) {
  // 检查 <D:resourcetype> 节点下是否有 <D:collection />
  var resourceType = prop.findElements('D:resourcetype').firstOrNull;
  if (resourceType != null) {
    return resourceType.findElements('D:collection').isNotEmpty;
  }
  return false;
}

Future<List<String>> fetchWebDAVFiles() async {
  List<String> urlList = [];

  try {
    // 获取 Dio 实例
    final dio = getWebDavDio();

    if (dio == null) {
      throw Exception('WebDAV 配置不完整');
    }

    // 发送 PROPFIND 请求
    Response response = await dio.request(
      '/Breeze/',
      options: Options(method: 'PROPFIND'),
    );

    // 解析 XML 响应
    if (response.statusCode == 207) {
      xml.XmlDocument xmlDoc = xml.XmlDocument.parse(response.data);

      try {
        var elements = xmlDoc.findAllElements('D:response');

        for (var element in elements) {
          var href = element.findElements('D:href').first.innerText;
          var propstat = element.findElements('D:propstat').first;
          var prop = propstat.findElements('D:prop').first;

          var isDir = xmlIsDirectory(prop); // 判断是否是文件夹

          if (!isDir) {
            urlList.add(href);
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

Future<void> uploadFile2WebDav() async {
  // 获取数据并转换为 JSON
  var allHistory = await objectbox.bikaHistoryBox.getAllAsync();
  allHistory.sort((a, b) => b.history.compareTo(a.history));
  var comicHistoriesJson = allHistory.map((comic) => comic.toJson()).toList();
  String comicHistoriesJsonString = jsonEncode(comicHistoriesJson);

  // 命令行解密方式
  // gunzip history.gz
  // base64 --decode history > encrypted.bin
  // openssl enc -d -aes-256-ctr -iv 37714677547877482669797577333566 -K 5859214578336a3368505e42475046616e59456a4241214c216f44326b6b434e -in encrypted.bin -out decrypted.json

  final key = encrypt.Key.fromUtf8("XY!Ex3j3hP^BGPFanYEjBA!L!oD2kkCN");
  final iv = encrypt.IV.fromUtf8("7qFwTxwH&iyuw35f");
  final encrypter =
      encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.ctr));

  final encrypted = encrypter.encrypt(comicHistoriesJsonString, iv: iv);

  // 将 JSON 字符串转换为字节数据
  final jsonBytes = utf8.encode(encrypted.base64);

  // 压缩数据
  final compressedBytes = GZipEncoder().encode(jsonBytes);

  var time = DateTime.now().toUtc().millisecondsSinceEpoch;

  // 上传数据到 WebDAV
  await _uploadDataToWebDav(compressedBytes, '/Breeze/BK_$time.gz');
}

Future<void> _uploadDataToWebDav(List<int> data, String remotePath) async {
  final dio = getWebDavDio();
  if (dio == null) {
    throw Exception('WebDAV 配置不完整');
  }

  try {
    // 发送 PUT 请求上传数据
    final response = await dio.put(
      remotePath,
      data: Stream.fromIterable([data]), // 将字节数据转换为流
      options: Options(
        headers: {
          'Content-Type': 'application/octet-stream', // 通用二进制类型
        },
      ),
    );

    // 检查状态码
    if (response.statusCode == 201 || response.statusCode == 204) {
      debugPrint('文件上传成功');
    } else {
      throw Exception('文件上传失败，状态码: ${response.statusCode}');
    }
  } on DioException catch (e) {
    if (e.response != null) {
      throw Exception(
          '文件上传失败: ${e.message}\n${e.response?.statusCode}\n${e.response?.data}');
    } else {
      throw Exception('文件上传失败: ${e.message}');
    }
  } catch (e) {
    throw Exception('未知错误: $e');
  }
}

Future<String> getNeedDownloadUrl(List<String> urlList) async {
  List<String> timestampList = [];

  // 正则表达式
  final regex = RegExp(r'BK_(\d+)\.gz');

  for (var url in urlList) {
    // 匹配正则表达式
    var match = regex.firstMatch(url);
    if (match != null) {
      // 提取时间戳
      String timestamp = match.group(1)!;
      timestampList.add(timestamp);
    }
  }

  // 确保时间戳列表不为空
  if (timestampList.isEmpty) {
    throw Exception('No valid URLs found');
  }

  // 按时间戳排序（升序）
  timestampList.sort((a, b) => a.compareTo(b));

  // 获取最晚时间戳（最小的时间戳）
  String latestTimestamp = timestampList.first;

  // 找到最新时间戳对应的 URL
  String latestUrl = '';
  for (var url in urlList) {
    if (url.contains('BK_$latestTimestamp.gz')) {
      latestUrl = url;
      break;
    }
  }

  // 确保找到对应的 URL
  if (latestUrl.isEmpty) {
    throw Exception('No URL found for the latest timestamp');
  }

  return latestUrl;
}

Future<List<BikaComicHistory>> getHistoryFromWebdav(String remotePath) async {
  // 下载文件
  final compressedBytes = await _downloadFromWebDav(remotePath);

  // 解压缩数据
  final jsonBytes = GZipDecoder().decodeBytes(compressedBytes);

  // 将字节数据转换为字符串
  final encryptedBase64 = utf8.decode(jsonBytes);

  // 解密数据
  final key = encrypt.Key.fromUtf8("XY!Ex3j3hP^BGPFanYEjBA!L!oD2kkCN");
  final iv = encrypt.IV.fromUtf8("7qFwTxwH&iyuw35f");
  final encrypter =
      encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.ctr));

  // 解密
  final encrypted = encrypt.Encrypted.fromBase64(encryptedBase64);
  final decrypted = encrypter.decrypt(encrypted, iv: iv);

  // 将解密后的 JSON 字符串转换为对象
  final temp = jsonDecode(decrypted) as List<dynamic>;

  // 将 List<dynamic> 转换为 List<Map<String, dynamic>>
  final comicHistoriesJson = temp.cast<Map<String, dynamic>>().map((comic) {
    return BikaComicHistory.fromJson(comic);
  }).toList();

  debugPrint('解密后的数据条数: ${comicHistoriesJson.length}');

  return comicHistoriesJson;
}

Future<List<int>> _downloadFromWebDav(String remotePath) async {
  final dio = getWebDavDio();
  if (dio == null) {
    throw Exception('WebDAV 配置不完整');
  }

  try {
    // 发送 GET 请求下载文件
    final response = await dio.get(
      remotePath,
      options: Options(
        responseType: ResponseType.bytes, // 以字节数组形式接收数据
      ),
    );

    // 检查状态码
    if (response.statusCode == 200) {
      debugPrint('文件下载成功');
      return response.data as List<int>;
    } else {
      throw Exception('文件下载失败，状态码: ${response.statusCode}');
    }
  } on DioException catch (e) {
    if (e.response != null) {
      throw Exception(
          '文件下载失败: ${e.message}\n${e.response?.statusCode}\n${e.response?.data}');
    } else {
      throw Exception('文件下载失败: ${e.message}');
    }
  } catch (e) {
    throw Exception('未知错误: $e');
  }
}

Future<void> updateHistory(List<BikaComicHistory> comicHistories) async {
  List<BikaComicHistory> needUpdateList = [];
  List<int> needDeleteIdList = [];
  var historyBox = objectbox.bikaHistoryBox.query().build().find();
  // 获取当前设备的时区偏移量
  Duration timeZoneOffset = DateTime.now().timeZoneOffset;

  for (var comicHistory in comicHistories) {
    var temp = historyBox
        .where((history) => history.comicId == comicHistory.comicId)
        .firstOrNull;

    if (temp != null) {
      if (temp.history.compareTo(comicHistory.history) < 0) {
        needDeleteIdList.add(temp.id);
        comicHistory.id = 0;
        comicHistory.history.add(timeZoneOffset);
        needUpdateList.add(comicHistory);
      }
    } else {
      comicHistory.id = 0;
      comicHistory.history.add(timeZoneOffset);
      needUpdateList.add(comicHistory);
    }
  }

  objectbox.bikaHistoryBox.removeMany(needDeleteIdList);
  objectbox.bikaHistoryBox.putMany(needUpdateList);

  debugPrint('更新历史记录成功');
}

Future<void> deleteFileFromWebDav(List<String> remotePath) async {
  final dio = getWebDavDio();
  if (dio == null) {
    throw Exception('WebDAV 配置不完整');
  }

  for (var path in remotePath) {
    try {
      // 发送 DELETE 请求删除文件
      final response = await dio.delete(path);

      // 检查状态码
      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('文件删除成功: $path');
      } else {
        throw Exception('文件删除失败，状态码: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            '文件删除失败: ${e.message}\n${e.response?.statusCode}\n${e.response?.data}');
      } else {
        throw Exception('文件删除失败: ${e.message}');
      }
    } catch (e) {
      throw Exception('未知错误: $e');
    }
  }
}
