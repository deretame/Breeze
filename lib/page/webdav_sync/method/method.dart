import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

// 测试 WebDAV 服务是否可用
Future<void> testWebDavServer(
  String host,
  String username,
  String password,
) async {
  final dio = Dio(BaseOptions(
    baseUrl: host, // WebDAV 服务器地址
    headers: {
      'Authorization': 'Basic ${base64Encode(
        utf8.encode('$username:$password'),
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
      debugPrint('WebDAV 服务返回异常状态码: ${response.statusCode}');
    }
  } on DioException catch (e) {
    // 捕获 Dio 的错误
    if (e.response != null) {
      // 如果服务器返回了响应
      debugPrint('WebDAV 服务返回错误: ${e.response?.statusCode}');
    } else {
      // 如果只是 Dio 的错误（如网络连接失败、超时等）
      debugPrint('连接失败: ${e.message}');
    }
  } catch (e) {
    // 捕获其他未知错误
    debugPrint('未知错误: $e');
  }
}
