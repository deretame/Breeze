// C++ fetch（wind_core_cpp / fetchcore）冒烟测试。
//
// 运行：puro flutter test test/cpp_fetch_smoke_test.dart
//
// 覆盖：GET/POST/重定向/query/baseUrl/下载进度/TLS（真实 HTTPS 非致命）。
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/network/http/wind_http.dart';
import 'package:zephyr/src/native_gen/api/init.dart';

Future<HttpServer> _startServer(List<int> downloadBytes) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    final resp = request.response;
    switch (request.uri.path) {
      case '/get':
        resp.headers.set('x-test-header', 'hello');
        resp.headers.contentType = ContentType.json;
        resp.write(jsonEncode({'path': '/get', 'query': request.uri.query}));
      case '/echo':
        final body = await request.fold<List<int>>(
          [],
          (acc, chunk) => acc..addAll(chunk),
        );
        resp.headers.set('content-type', 'application/octet-stream');
        resp.add(body);
      case '/redirect':
        resp.statusCode = HttpStatus.found;
        resp.headers.set('location', '/get');
      case '/query':
        resp.write(jsonEncode(request.uri.queryParameters));
      case '/download':
        resp.headers.contentType = ContentType.binary;
        resp.headers.contentLength = downloadBytes.length;
        resp.add(downloadBytes);
      default:
        resp.statusCode = HttpStatus.notFound;
    }
    await resp.close();
  });
  return server;
}

void main() {
  HttpServer? server;
  late String base;
  final downloadBytes = List<int>.generate(
    1024 * 1024,
    (i) => i % 251,
  ); // 1 MiB 确定性内容

  setUpAll(() async {
    await DcbLib.init();
    server = await _startServer(downloadBytes);
    base = 'http://${server!.address.host}:${server!.port}';
  });

  tearDownAll(() async {
    await server?.close(force: true);
  });

  test('GET：状态 / JSON body / 自定义响应头', () async {
    final res = await fetch('$base/get');
    expect(res.status, 200);
    expect(res.ok, isTrue);
    expect(res.header('X-Test-Header'), 'hello');
    expect((res.json as Map)['path'], '/get');
  });

  test('POST：字符串 body 回显 + JSON body 自动 Content-Type', () async {
    final text = await fetch('$base/echo', method: 'POST', body: '你好 echo');
    expect(text.text, '你好 echo');

    final json = await fetch(
      '$base/echo',
      method: 'POST',
      body: {'a': 1},
    );
    expect((json.json as Map)['a'], 1);

    // 二进制 body 完整性（u8vec 批量编码路径）
    final bin = Uint8List.fromList(List.generate(256, (i) => i));
    final echoed = await fetch('$base/echo', method: 'POST', body: bin);
    expect(echoed.body, bin);
  });

  test('重定向：默认跟随 / 手动模式返回 302', () async {
    final followed = await fetch('$base/redirect');
    expect(followed.status, 200);
    expect(followed.redirected, isTrue);
    expect(followed.url, endsWith('/get'));

    final manual = await fetch('$base/redirect', followRedirects: false);
    expect(manual.status, 302);
    expect(manual.redirected, isFalse);
    expect(manual.header('location'), '/get');
  });

  test('query 参数拼接到 URL', () async {
    final res = await fetch('$base/query?a=1', query: {'b': '两', 'c': 3});
    final q = res.json as Map;
    expect(q['a'], '1');
    expect(q['b'], '两');
    expect(q['c'], '3');
  });

  test('baseUrl 拼接相对路径', () async {
    final client = WindHttp(baseUrl: base);
    expect(client.baseUrl, base);
    final res = await client.fetch('/get');
    expect(res.ok, isTrue);
  });

  test('download：进度回调递增、文件内容一致', () async {
    final tmp = await Directory.systemTemp.createTemp('cpp_fetch_dl');
    addTearDown(() => tmp.delete(recursive: true));
    final savePath = '${tmp.path}/dl.bin';

    final progress = <List<int>>[];
    await WindHttp().download(
      '$base/download',
      savePath,
      onReceiveProgress: (received, total) => progress.add([received, total]),
    );

    final file = File(savePath);
    expect(await file.exists(), isTrue);
    expect(await file.readAsBytes(), downloadBytes);
    expect(progress, isNotEmpty);
    expect(progress.last[0], downloadBytes.length);
    expect(progress.last[1], downloadBytes.length);
    // 递增
    for (var i = 1; i < progress.length; i++) {
      expect(progress[i][0], greaterThan(progress[i - 1][0]));
    }
    // 临时文件已 rename
    expect(await File('$savePath.part').exists(), isFalse);
  });

  test('真实 HTTPS（网络不可用时跳过）', () async {
    try {
      final res = await fetch(
        'https://example.com/',
        timeout: const Duration(seconds: 10),
      ).timeout(const Duration(seconds: 15));
      expect(res.status, 200);
      expect(res.text, contains('Example Domain'));
    } catch (e) {
      // 网络受限环境下不判失败，仅提示
      // ignore: avoid_print
      print('[skip] 真实 HTTPS 请求失败（可能无网络）: $e');
    }
  });
}
