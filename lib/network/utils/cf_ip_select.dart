import 'package:html/parser.dart' as html_parser;
import 'package:zephyr/main.dart';

Future<String> downloadHtmlBody(String url) async {
  try {
    final response = await fetch(url);

    if (response.ok) {
      final document = html_parser.parse(response.text);
      return document.body?.innerHtml ?? '';
    } else {
      throw Exception('Failed to load page: ${response.status}');
    }
  } catch (e) {
    throw Exception('Error downloading HTML: $e');
  }
}

Future<void> initCfIpList(String url) async {
  final htmlBody = await downloadHtmlBody(url);
  final ips = htmlBody
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .where((e) => RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$').hasMatch(e))
      .toList();
  cfIpList.addAll(ips);
  logger.d('cfIpList: $cfIpList');
}
