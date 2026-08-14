import 'dart:convert';

import 'package:zephyr/src/native_gen/api/bridge_api.dart' as native;
import 'package:zephyr/src/rust/api/qjs.dart' as rust_qjs;
import 'package:zephyr/src/rust/qjs.dart' as rust_qjs_req;

/// QJS 运行时后端开关：true = C++（wind_core_cpp / qjs::HostRuntime），
/// false = Rust（rquickjs）。灰度期间两套并存；全量切走后删除 Rust 分支。
///
/// C++ 后端当前差异（docs/cpp_plugin_runtime_design.md 后续补全清单）：
/// - 任务组取消未实现（cancelTrackedQjsTasks 仅清 Dart 侧追踪表）；
/// - save/load_plugin_config 是内存 stub（不持久化到 ObjectBox）；
/// - flutter.showToast / dart.getAppVersion 等 Dart 回调是占位实现；
/// - 代理/TLS 配置仅对之后新建的 runtime 生效。
bool useCppQjsRuntime = true;

Future<bool> qjsBackendIsInitialized(String runtimeName) {
  return useCppQjsRuntime
      ? native.qjsIsInitialized(runtimeName: runtimeName)
      : rust_qjs.isQjsRuntimeInitialized(name: runtimeName);
}

/// 建 runtime。bundleJs 为空/null = 空 runtime（无插件函数）。
/// C++ 端重复调用幂等；Rust 端同名重复 build 会报错，调用方需先查 initialized。
Future<void> qjsBackendBuildRuntime(
  String runtimeName, {
  String? bundleJs,
}) {
  if (useCppQjsRuntime) {
    return native.qjsBuildRuntime(
      runtimeName: runtimeName,
      bundleName: runtimeName,
      bundleJs: bundleJs ?? '',
    );
  }
  return rust_qjs.buildQjsRuntime(
    request: rust_qjs_req.QjsRuntimeBuildRequest(
      runtimeName: runtimeName,
      injectFilesystem: false,
      bundle: bundleJs == null
          ? null
          : rust_qjs_req.QjsRuntimeBundleBuild(
              bundleName: runtimeName,
              bundleJs: bundleJs,
            ),
    ),
  );
}

/// 热替换常驻 bundle。C++ 端为原子替换；Rust 端用 replace_bundle。
Future<void> qjsBackendReplaceBundle(String runtimeName, String bundleJs) {
  return useCppQjsRuntime
      ? native.qjsReplaceBundle(
          runtimeName: runtimeName,
          bundleName: runtimeName,
          bundleJs: bundleJs,
        )
      : rust_qjs.qjsReplaceBundle(
          runtimeName: runtimeName,
          bundleName: runtimeName,
          bundleJs: bundleJs,
        );
}

Future<bool> qjsBackendDropRuntime(String runtimeName) {
  return useCppQjsRuntime
      ? native.qjsDropRuntime(runtimeName: runtimeName)
      : rust_qjs.qjsDropRuntime(runtimeName: runtimeName);
}

/// 当前 bundle 名（JSON 文本："null" 或带引号的名字）。
Future<String> qjsBackendCurrentBundle(String runtimeName) {
  return useCppQjsRuntime
      ? native.qjsCurrentBundle(runtimeName: runtimeName)
      : rust_qjs.qjsCurrentBundle(runtimeName: runtimeName);
}

Future<String> qjsBackendDebugSnapshot(String runtimeName) {
  return useCppQjsRuntime
      ? native.qjsDebugSnapshot(runtimeName: runtimeName)
      : rust_qjs.qjsDebugSnapshot(runtimeName: runtimeName);
}

/// 进程级 fetch 配置（C++ 后端；仅对之后新建的 runtime 生效）。
/// Rust 后端的对应设置在 main.dart 原路径上保留（QJS 插件运行时之外
/// 的 Rust reqwest 用户仍在用）。
void qjsBackendSetHttpProxy(String proxy) {
  if (useCppQjsRuntime) native.qjsSetHttpProxy(proxy: proxy);
}

void qjsBackendSetSocks5Proxy(String proxy) {
  if (useCppQjsRuntime) native.qjsSetSocks5Proxy(proxy: proxy);
}

void qjsBackendSetTlsVerify(bool enabled) {
  if (useCppQjsRuntime) native.qjsSetTlsVerifyEnabled(enabled: enabled);
}

/// 注册 Dart 回调为 JS bridge 路由（对齐 Rust registerFunction）。
/// C++ 端 bridge.call（异步）/ bridge.callSync（同步）均可触达；
/// 与内建内存 stub 同名时 Dart 注册优先。
void qjsBackendRegisterFunction(
  String functionName,
  Future<String> Function(String) dartCallback,
) {
  if (useCppQjsRuntime) {
    native.qjsRegisterFunction(
      functionName: functionName,
      callback: dartCallback,
    );
    return;
  }
  rust_qjs.registerFunction(
    functionName: functionName,
    dartCallback: dartCallback,
  );
}

/// once 调用（独立 runtime + 热重载语义，用于 fetchPluginInfo 等场景）。
/// C++ 端要求 runtime 已存在：缺失时先带 bundle 建实例，随后调用走
/// debug 屏障 + 源码哈希跳过（与 Rust once 池的缓存语义对应）。
Future<String> qjsBackendCallOnce({
  required String runtimeName,
  required String bundleJs,
  required String fnPath,
  required String argsJson,
}) async {
  if (useCppQjsRuntime) {
    if (!await native.qjsIsInitialized(runtimeName: runtimeName)) {
      await native.qjsBuildRuntime(
        runtimeName: runtimeName,
        bundleName: runtimeName,
        bundleJs: bundleJs,
      );
    }
    final bytes = await native.qjsTaskCall(
      runtimeName: runtimeName,
      taskGroupKey: '',
      isOnce: true,
      bundleJs: bundleJs,
      fnPath: fnPath,
      argsJson: argsJson,
    );
    return utf8.decode(bytes, allowMalformed: true);
  }
  return rust_qjs.qjsCallOnce(
    runtimeName: runtimeName,
    bundleJs: bundleJs,
    fnPath: fnPath,
    argsJson: argsJson,
  );
}
