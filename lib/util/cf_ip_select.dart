import 'dart:async';

import 'package:html/parser.dart' as html_parser;

import '../main.dart';

Future<String> downloadHtmlBody(String url) async {
  try {
    final response = await dio.get(url);

    if (response.statusCode == 200) {
      // 使用 html 包解析文档
      final document = html_parser.parse(response.data);

      // 获取 body 内容
      final body = document.body?.innerHtml ?? '';
      return body;
    } else {
      throw Exception('Failed to load page: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error downloading HTML: $e');
  }
}

Future<void> initCfIpList(String url) async {
  // 获取 HTML body 内容
  final htmlBody = await downloadHtmlBody(url);
  // 处理返回的内容
  final ips =
      htmlBody
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty) // 过滤空字符串
          .where(
            (e) => RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$').hasMatch(e),
          ) // 验证 IP 格式
          .toList(); // 转换为列表以执行操作
  // 添加到 cfIpList
  cfIpList.addAll(ips);
  logger.d('cfIpList: $cfIpList');
}
