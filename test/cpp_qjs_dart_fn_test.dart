// C++ 插件 QJS 运行时 Dart 回调（register_function）通路测试。
//
// 运行：puro flutter test test/cpp_qjs_dart_fn_test.dart
//
// 插件 bundle 来自 example 工程（testBridgeCall/testBridgeCallSync 透传
// bridge.call/bridge.callSync）：
//   D:\Project\web\Breeze-plugin\Breeze-plugin-example\dist\
//
// 覆盖：
// - 同步 Dart 回调（立即返回的 Future）经 bridge.call / bridge.callSync 调用；
// - 异步 Dart 回调（Future.delayed）经 bridge.call 调用，多轮 + 并发；
// - 输入协议 "[runtime, ...args]"、返回协议（空串 → null，非空 → 字符串）；
// - Dart 注册覆盖内建内存 stub（flutter.showToast），注销后回落 stub；
// - 未注册路由报 bridge route not found。
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/src/native_gen/api/bridge_api.dart';
import 'package:zephyr/src/native_gen/api/init.dart';

const _bundlePath =
    r'D:\Project\web\Breeze-plugin\Breeze-plugin-example\dist\breeze-plugin-example.bundle.cjs';

void main() {
  late String bundle;

  setUpAll(() async {
    await DcbLib.init();
    bundle = await File(_bundlePath).readAsString();
  });

  Future<dynamic> call(
    String rt,
    String fn,
    Map<String, dynamic> args,
  ) async {
    final bytes = await qjsTaskCall(
      runtimeName: rt,
      taskGroupKey: '',
      isOnce: false,
      fnPath: fn,
      argsJson: jsonEncode(args),
    );
    return jsonDecode(utf8.decode(bytes, allowMalformed: true));
  }

  test('Dart 回调：同步/异步/多轮/并发/覆盖 stub/注销', () async {
    const rt = 'example-dartfn';
    await qjsBuildRuntime(runtimeName: rt, bundleName: 'example', bundleJs: bundle);

    // ---- 同步回调（立即完成的 Future）：bridge.call 与 bridge.callSync ----
    var syncCount = 0;
    expect(
      qjsRegisterFunction(
        functionName: 'test.syncEcho',
        callback: (input) async {
          syncCount++;
          final args = jsonDecode(input) as List<dynamic>;
          expect(args[0], rt); // 输入协议：[runtime, ...args]
          return 'echo:${jsonEncode(args.sublist(1))}';
        },
      ),
      isTrue,
    );

    // 多轮（异步路由 bridge.call）
    for (var i = 0; i < 5; i++) {
      final r = await call(rt, 'testBridgeCall', {
        'name': 'test.syncEcho',
        'args': ['round$i', i],
      });
      expect(r, 'echo:["round$i",$i]');
    }
    // 多轮（同步路由 bridge.callSync）
    for (var i = 0; i < 5; i++) {
      final r = await call(rt, 'testBridgeCallSync', {
        'name': 'test.syncEcho',
        'args': ['sync$i'],
      });
      expect(r, 'echo:["sync$i"]');
    }
    expect(syncCount, 10);

    // ---- 异步回调（Future.delayed）：多轮 + 并发 ----
    var asyncCount = 0;
    qjsRegisterFunction(
      functionName: 'test.asyncEcho',
      callback: (input) async {
        asyncCount++;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        final args = jsonDecode(input) as List<dynamic>;
        return 'async:${args[1]}';
      },
    );
    for (var i = 0; i < 3; i++) {
      final r = await call(rt, 'testBridgeCall', {
        'name': 'test.asyncEcho',
        'args': ['seq$i'],
      });
      expect(r, 'async:seq$i');
    }
    // 并发：多个 qjsTaskCall 同时等 Dart 回复
    final results = await Future.wait([
      for (var i = 0; i < 4; i++)
        call(rt, 'testBridgeCall', {
          'name': 'test.asyncEcho',
          'args': ['par$i'],
        }),
    ]);
    expect(results, ['async:par0', 'async:par1', 'async:par2', 'async:par3']);
    expect(asyncCount, 7);

    // ---- 返回协议：空串 → null ----
    qjsRegisterFunction(
      functionName: 'test.empty',
      callback: (_) async => '',
    );
    expect(await call(rt, 'testBridgeCall', {'name': 'test.empty'}), isNull);

    // ---- 覆盖内建 stub：flutter.showToast ----
    final toastMessages = <String>[];
    qjsRegisterFunction(
      functionName: 'flutter.showToast',
      callback: (input) async {
        final args = jsonDecode(input) as List<dynamic>;
        toastMessages.add(jsonEncode(args.sublist(1)));
        return '';
      },
    );
    await call(rt, 'testBridgeCall', {
      'name': 'flutter.showToast',
      'args': ['hello-dart'],
    });
    expect(toastMessages, ['["hello-dart"]']);

    // 注销后回落到内建 stub（记日志，不再触达 Dart）
    expect(qjsUnregisterFunction(functionName: 'flutter.showToast'), isTrue);
    await call(rt, 'testBridgeCall', {
      'name': 'flutter.showToast',
      'args': ['hello-stub'],
    });
    expect(toastMessages, hasLength(1)); // 未被 Dart 回调收到

    // ---- 注销后未注册路由报错 ----
    expect(qjsUnregisterFunction(functionName: 'test.syncEcho'), isTrue);
    expect(qjsUnregisterFunction(functionName: 'test.asyncEcho'), isTrue);
    expect(qjsUnregisterFunction(functionName: 'test.empty'), isTrue);
    expect(qjsUnregisterFunction(functionName: 'test.syncEcho'), isFalse);
    await expectLater(
      call(rt, 'testBridgeCall', {'name': 'test.syncEcho', 'args': []}),
      throwsA(
        predicate(
          (Object e) => e.toString().contains('bridge route not found'),
        ),
      ),
    );

    expect(await qjsDropRuntime(runtimeName: rt), isTrue);
  });
}
