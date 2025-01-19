import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

import '../../../main.dart';

Future<void> testWebDavServer(
  String host,
  String username,
  String password,
) async {
  final dio = Dio(BaseOptions(
    baseUrl: host, // WebDAV服务器地址
    headers: {
      'Authorization': 'Basic ${base64Encode(
        utf8.encode('$username:$password'),
      )}',
    },
    connectTimeout: const Duration(seconds: 10), // 连接超时时间
    receiveTimeout: const Duration(seconds: 10), // 接收超时时间
  ));

  try {
    // 测试 PROPFIND 请求
    final response = await dio.request(
      '',
      options: Options(
        method: 'PROPFIND', // 指定请求方法
        headers: {
          'Depth': '1', // 查询根目录及其直接子资源
        },
      ),
      data: '''<?xml version="1.0" encoding="utf-8" ?>
<D:propfind xmlns:D="DAV:">
  <D:prop>
    <D:getlastmodified/>
    <D:getcontentlength/>
    <D:resourcetype/>
  </D:prop>
</D:propfind>''',
    );

    // 检查状态码
    if (response.statusCode == 207) {
      debugPrint('WebDAV server is accessible.');
      debugPrint('Response data: ${response.data}');
    } else {
      // 如果状态码不是 207，抛出包含响应信息的异常
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        error: '服务器返回错误: ${response.statusCode}',
      );
    }
  } on DioException catch (e) {
    // 捕获 Dio 的错误
    if (e.response != null) {
      // 如果服务器返回了响应，抛出包含响应信息的异常
      throw DioException(
        requestOptions: e.requestOptions,
        response: e.response,
        type: DioExceptionType.badResponse,
        error: '服务器返回错误: ${e.response?.statusCode}\n${e.response?.data}',
      );
    } else {
      // 如果只是 Dio 的错误（如网络连接失败、超时等），抛出 Dio 的错误
      throw DioException(
        requestOptions: e.requestOptions,
        type: e.type,
        error: '连接失败: ${e.message}',
      );
    }
  } catch (e) {
    // 捕获其他未知错误
    debugPrint('未知错误: $e');
    throw Exception('未知错误: $e');
  }
}

Dio? getWebDavDio() {
  if (globalSetting.webdavHost.isEmpty ||
      globalSetting.webdavUsername.isEmpty ||
      globalSetting.webdavPassword.isEmpty) {
    return null;
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
