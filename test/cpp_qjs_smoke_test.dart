// C++ 插件 QJS 运行时（wind_core_cpp / qjs::HostRuntime）冒烟测试。
//
// 运行：puro flutter test test/cpp_qjs_smoke_test.dart
//
// 插件 bundle 来自 example 工程（已预构建，改动后可 pnpm build 重新生成）：
//   D:\Project\web\Breeze-plugin\Breeze-plugin-example\dist\
//
// 覆盖：build → init/getInfo/searchComic(走 opencc+cache 路由)/
// getComicDetail(走 pluginConfig 路由)/getChapter/fetchImageBytes(本地
// HttpServer) → debug once 热重载 → current/snapshot → replace/clear →
// drop；以及 JS 异常传播。
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/src/native_gen/api/bridge_api.dart';
import 'package:zephyr/src/native_gen/api/init.dart';

const _bundlePath =
    r'D:\Project\web\Breeze-plugin\Breeze-plugin-example\dist\breeze-plugin-example.bundle.cjs';

void main() {
  HttpServer? server;
  late String base;
  late String bundle;
  final imageBytes = Uint8List.fromList(
    List<int>.generate(256 * 1024, (i) => (i * 7) % 253),
  );

  setUpAll(() async {
    await DcbLib.init();
    bundle = await File(_bundlePath).readAsString();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server!.listen((request) async {
      final resp = request.response;
      if (request.uri.path == '/img') {
        resp.headers.contentType = ContentType.binary;
        resp.headers.contentLength = imageBytes.length;
        resp.add(imageBytes);
      } else {
        resp.statusCode = HttpStatus.notFound;
      }
      await resp.close();
    });
    base = 'http://${server!.address.host}:${server!.port}';
  });

  tearDownAll(() async {
    await server?.close(force: true);
  });

  test('插件基础流程：build → 调用 → debug/replace/clear → drop', () async {
    const rt = 'example-smoke';

    Future<dynamic> call(String fn, Map<String, dynamic> args) async {
      final bytes = await qjsTaskCall(
        runtimeName: rt,
        taskGroupKey: '',
        isOnce: false,
        fnPath: fn,
        argsJson: jsonEncode(args),
      );
      return jsonDecode(utf8.decode(bytes, allowMalformed: true));
    }

    // ---- build / isInitialized ----
    await qjsBuildRuntime(
      runtimeName: rt,
      bundleName: 'example',
      bundleJs: bundle,
    );
    expect(await qjsIsInitialized(runtimeName: rt), isTrue);
    // 重复 build 幂等
    await qjsBuildRuntime(
      runtimeName: rt,
      bundleName: 'example',
      bundleJs: bundle,
    );

    // ---- init（走 pluginConfig 内存 stub + console）----
    final initRet = await call('init', {});
    expect(initRet['data']['ok'], isTrue);

    // ---- getInfo ----
    final info = await call('getInfo', {});
    expect(info['name'], 'Example Plugin');

    // ---- searchComic（走 opencc.convert + cache.get/set 路由）----
    final search = await call('searchComic', {
      'keyword': '測試',
      'page': 1,
      'extern': <String, dynamic>{},
    });
    // opencc t2s：繁体关键字转简体后出现在标题里
    expect(jsonEncode(search), contains('测试'));
    // 第二次命中 cache（结果一致即说明 cache.set/get 通路正常）
    final search2 = await call('searchComic', {
      'keyword': '測試',
      'page': 1,
      'extern': <String, dynamic>{},
    });
    expect(jsonEncode(search2), jsonEncode(search));

    // ---- getComicDetail（走 pluginConfig.load 路由）----
    final detail = await call('getComicDetail', {
      'comicId': '10001',
      'extern': <String, dynamic>{},
    });
    expect(jsonEncode(detail), contains('示例漫画 #10001'));

    // ---- getChapter ----
    final chapter = await call('getChapter', {
      'comicId': '10001',
      'chapterId': 'ep-1',
      'extern': <String, dynamic>{},
    });
    expect(jsonEncode(chapter), contains('ep-1'));

    // ---- fetchImageBytes（JS fetch → 本地 HttpServer，二进制返回通道）----
    final img = await qjsTaskCall(
      runtimeName: rt,
      taskGroupKey: '',
      isOnce: false,
      fnPath: 'fetchImageBytes',
      argsJson: jsonEncode({
        'url': '$base/img',
        'timeoutMs': 10000,
        'taskGroupKey': '',
        'extern': <String, dynamic>{},
      }),
    );
    expect(img, imageBytes);

    // ---- debug once：携带改名后的 bundle 热重载调用 ----
    final debugBundle = bundle.replaceAll(
      'Example Plugin',
      'Example Plugin Debug',
    );
    final debugInfoBytes = await qjsTaskCall(
      runtimeName: rt,
      taskGroupKey: '',
      isOnce: true,
      bundleJs: debugBundle,
      fnPath: 'getInfo',
      argsJson: '{}',
    );
    expect(
      utf8.decode(debugInfoBytes, allowMalformed: true),
      contains('Example Plugin Debug'),
    );
    // registry 记录的常驻 bundle 名不受 debug 调用影响
    expect(await qjsCurrentBundle(runtimeName: rt), '"example"');

    // ---- debug snapshot ----
    final snap = await qjsDebugSnapshot(runtimeName: rt);
    expect(snap, contains(rt));

    // ---- replace bundle ----
    final v2Bundle = bundle.replaceAll('Example Plugin', 'Example Plugin V2');
    await qjsReplaceBundle(
      runtimeName: rt,
      bundleName: 'example-v2',
      bundleJs: v2Bundle,
    );
    expect(await qjsCurrentBundle(runtimeName: rt), '"example-v2"');
    final infoV2 = await call('getInfo', {});
    expect(infoV2['name'], 'Example Plugin V2');

    // ---- clear bundle：之后调用应报 function_not_found ----
    expect(await qjsClearBundle(runtimeName: rt), isTrue);
    expect(await qjsCurrentBundle(runtimeName: rt), 'null');
    await expectLater(call('getInfo', {}), throwsA(anything));

    // ---- drop ----
    expect(await qjsDropRuntime(runtimeName: rt), isTrue);
    expect(await qjsIsInitialized(runtimeName: rt), isFalse);
    expect(await qjsDropRuntime(runtimeName: rt), isFalse);
  });

  test('JS 异常传播：错误文本带 JS 消息', () async {
    const rt = 'example-err';
    await qjsBuildRuntime(
      runtimeName: rt,
      bundleName: 'example',
      bundleJs: bundle,
    );
    // getComicDetail 缺 comicId → JS throw new Error("comicId 不能为空")
    await expectLater(
      qjsTaskCall(
        runtimeName: rt,
        taskGroupKey: '',
        isOnce: false,
        fnPath: 'getComicDetail',
        argsJson: '{}',
      ),
      throwsA(predicate((Object e) => e.toString().contains('comicId 不能为空'))),
    );
    expect(await qjsDropRuntime(runtimeName: rt), isTrue);
  });
}
