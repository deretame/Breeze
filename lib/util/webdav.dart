import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:xml/xml.dart' as xml;

import '../../../main.dart';

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
    // 发送 MKCOL 请求创建目录
    Response response = await dio.request(
      path,
      options: Options(method: 'MKCOL'),
    );

    if (response.statusCode == 201 || response.statusCode == 405) {
      debugPrint('目录已存在或创建成功: $path');
    } else {
      throw Exception('目录创建失败，状态码: ${response.statusCode}');
    }
  } on DioException catch (e) {
    if (e.response != null) {
      throw Exception(
          '目录创建失败: ${e.message}\n${e.response?.statusCode}\n${e.response?.data}');
    } else {
      throw Exception('目录创建失败: ${e.message}');
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

// 检查文件是否存在，如果不存在则创建
Future<void> checkOrCreateFile(String filePath) async {
  // 获取 Dio 实例
  Dio? dio = getWebDavDio();
  if (dio == null) {
    throw Exception('WebDAV 配置不完整');
  }

  // 确保路径是绝对路径
  if (!filePath.startsWith('/')) {
    filePath = '/$filePath';
  }

  try {
    // 发送 HEAD 请求检查文件是否存在
    Response headResponse = await dio.head(filePath);

    // 如果文件存在
    if (headResponse.statusCode == 200) {
      debugPrint('文件已存在，无需创建');
      return;
    }
  } on DioException catch (e) {
    // 如果文件不存在（状态码为 404）
    if (e.response?.statusCode == 404) {
      debugPrint('文件不存在，尝试创建新文件');

      // 获取父目录路径
      String parentDir = filePath
          .split('/')
          .sublist(0, filePath.split('/').length - 1)
          .join('/');

      // 检查父目录是否存在
      if (parentDir.isNotEmpty) {
        await createParentDirectory(parentDir);
      }

      try {
        // 发送 PUT 请求创建新文件
        Response putResponse = await dio.put(
          filePath,
          data: '', // 可以是一个空文件，或者传入初始内容
        );

        // 检查 PUT 请求是否成功
        if (putResponse.statusCode == 201 || putResponse.statusCode == 204) {
          debugPrint('文件创建成功');
        } else {
          throw Exception('文件创建失败，状态码: ${putResponse.statusCode}');
        }
      } on DioException catch (e) {
        if (e.response != null) {
          throw Exception(
            '文件创建失败: ${e.message}\n${e.response?.statusCode}\n${e.response?.data}',
          );
        } else {
          throw Exception('文件创建失败: ${e.message}');
        }
      }
    } else if (e.response?.statusCode == 409) {
      debugPrint('路径冲突，可能是父目录不存在或路径已存在同名文件夹');

      // 直接尝试创建父目录
      String parentDir = filePath
          .split('/')
          .sublist(0, filePath.split('/').length - 1)
          .join('/');
      if (parentDir.isNotEmpty) {
        await createParentDirectory(parentDir);
      }

      // 再次尝试创建文件
      try {
        Response putResponse = await dio.put(
          filePath,
          data: '', // 可以是一个空文件，或者传入初始内容
        );

        if (putResponse.statusCode == 201 || putResponse.statusCode == 204) {
          debugPrint('文件创建成功');
        } else {
          throw Exception('文件创建失败，状态码: ${putResponse.statusCode}');
        }
      } on DioException catch (e) {
        if (e.response != null) {
          throw Exception(
            '文件创建失败: ${e.message}\n${e.response?.statusCode}\n${e.response?.data}',
          );
        } else {
          throw Exception('文件创建失败: ${e.message}');
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

// 获取文件的最后修改时间
Future<DateTime?> getLastModifiedTime(String filePath) async {
  Dio? dio = getWebDavDio();
  if (dio == null) {
    throw Exception('WebDAV 配置不完整');
  }

  try {
    // 发送 PROPFIND 请求
    final response = await dio.request(
      filePath,
      options: Options(
        method: 'PROPFIND', // 指定请求方法
        headers: {
          'Depth': '0', // 只查询当前资源
        },
      ),
      data: '''<?xml version="1.0" encoding="utf-8" ?>
<D:propfind xmlns:D="DAV:">
  <D:prop>
    <D:getlastmodified/>
  </D:prop>
</D:propfind>''',
    );

    // 检查状态码
    if (response.statusCode == 207) {
      // 解析 XML 响应
      final document = xml.XmlDocument.parse(response.data);

      // 定义命名空间
      final davNamespace = 'DAV:';

      // 查找 <d:getlastmodified> 节点
      final lastModifiedString = document
          .findAllElements('response', namespace: davNamespace)
          .expand((response) =>
              response.findElements('propstat', namespace: davNamespace))
          .expand((propstat) =>
              propstat.findElements('prop', namespace: davNamespace))
          .expand((prop) =>
              prop.findElements('getlastmodified', namespace: davNamespace))
          .map((element) => element.innerText)
          .firstOrNull;

      if (lastModifiedString != null) {
        debugPrint('文件的最后修改时间 (字符串): $lastModifiedString');

        // 解析 RFC 1123 格式的时间字符串
        final lastModifiedDateTime = parseRfc1123DateTime(lastModifiedString);
        if (lastModifiedDateTime != null) {
          debugPrint('文件的最后修改时间 (DateTime): $lastModifiedDateTime');
          return lastModifiedDateTime;
        } else {
          throw Exception('时间解析失败');
        }
      } else {
        throw Exception('未找到最后修改时间');
      }
    } else {
      throw Exception('请求失败，状态码: ${response.statusCode}');
    }
  } on DioException catch (e) {
    if (e.response != null) {
      throw Exception(
          '请求失败: ${e.message}\n${e.response?.statusCode}\n${e.response?.data}');
    } else {
      throw Exception('请求失败: ${e.message}');
    }
  } catch (e) {
    throw Exception('未知错误: $e');
  }
}

// 解析 RFC 1123 格式的时间字符串
DateTime? parseRfc1123DateTime(String dateString) {
  try {
    // RFC 1123 格式：Sun, 19 Jan 2025 11:18:13 GMT
    final months = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };

    // 分割字符串
    final parts = dateString.split(' ');
    if (parts.length != 6) {
      throw Exception('时间格式不正确: $dateString');
    }

    // 解析日期和时间
    final day = int.parse(parts[1]);
    final month = months[parts[2]];
    final year = int.parse(parts[3]);
    final time = parts[4].split(':');
    final hour = int.parse(time[0]);
    final minute = int.parse(time[1]);
    final second = int.parse(time[2]);

    if (month == null) {
      throw Exception('月份解析失败: ${parts[2]}');
    }

    // 创建 DateTime 对象
    return DateTime.utc(year, month, day, hour, minute, second);
  } catch (e) {
    throw Exception('解析时间失败: $e');
  }
}
