import 'package:flutter/services.dart';

/// 获取应传入 worker isolate 的 RootIsolateToken。
///
/// 必须在主 Isolate 中调用（例如 `RootIsolateToken.instance` 可用的位置）。
/// 返回的 token 需要作为参数传递给在 worker isolate 中执行的任务，
/// 并在任务开头调用 [ensureWorkerIsolateInitialized]。
RootIsolateToken? captureWorkerIsolateToken() => RootIsolateToken.instance;

/// 在 worker isolate 中初始化平台通道 BinaryMessenger。
///
/// 在 worker isolate 中调用平台插件（如 `path_provider`）前必须先调用此方法。
/// [token] 为从主 Isolate 通过 [captureWorkerIsolateToken] 获取的 token。
void ensureWorkerIsolateInitialized(RootIsolateToken? token) {
  if (token != null) {
    BackgroundIsolateBinaryMessenger.ensureInitialized(token);
  }
}
