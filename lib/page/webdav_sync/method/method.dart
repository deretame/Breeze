import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

// 测试 WebDAV 服务是否可用
Future<void> testWebDavServer(
  String host,
  String username,
  String password,
) async {
  final dio = Dio(
    BaseOptions(
      baseUrl: host, // WebDAV 服务器地址
      headers: {
        'Authorization':
            'Basic ${base64Encode(utf8.encode('$username:$password'))}',
      },
      connectTimeout: const Duration(seconds: 10), // 连接超时时间
      receiveTimeout: const Duration(seconds: 10), // 接收超时时间
    ),
  );

  try {
    // 打印请求信息
    debugPrint('请求 URL: ${dio.options.baseUrl}');
    debugPrint('请求头: ${dio.options.headers}');

    // 发送 OPTIONS 请求测试服务是否可用
    final response = await dio.request(
      '/',
      options: Options(method: 'OPTIONS'),
    );

    // 检查状态码
    if (response.statusCode == 200) {
      debugPrint('WebDAV 服务可用');
      debugPrint('支持的 HTTP 方法: ${response.headers['allow']}');
    } else {
      throw Exception('WebDAV 服务返回异常状态码: ${response.statusCode}');
    }
  } on DioException catch (e) {
    // 捕获 Dio 的错误
    if (e.response != null) {
      // 打印完整响应信息
      debugPrint('响应状态码: ${e.response?.statusCode}');
      debugPrint('响应头: ${e.response?.headers}');
      debugPrint('响应体: ${e.response?.data}');
      throw Exception('WebDAV 服务返回错误: ${e.response?.statusCode}');
    } else {
      // 如果只是 Dio 的错误（如网络连接失败、超时等）
      throw Exception('连接失败: ${e.message}');
    }
  } catch (e) {
    // 捕获其他未知错误
    throw Exception('未知错误: $e');
  }
}
