import 'dart:convert';
import 'dart:typed_data';

import 'package:zephyr/cs/data/cs_api_client.dart';
import 'package:zephyr/cs/domain/cs_connection_settings.dart';

/// 给现有插件调用链提供一个不依赖 Flutter UI 的 CS dispatch 点。
///
/// 本地模式下它保持关闭，调用方继续使用原有 QuickJS；CS 模式下才把
/// 统一插件调用转发到服务端。后续可在这里继续接入能力协商和重连策略。
class CsRuntimeContext {
  CsRuntimeContext._();

  static final CsRuntimeContext I = CsRuntimeContext._();

  CsConnectionSettings _settings = const CsConnectionSettings();
  CsApiClient? _client;

  /// 一旦选择 CS 模式就不静默回退到本地插件；未登录时由服务端返回 401，
  /// 由上层连接流程处理重新登录。
  bool get isCsMode => _settings.isCsMode;

  void update(CsConnectionSettings settings) {
    _settings = settings;
    _client = settings.hasServer
        ? CsApiClient(
            baseUrl: settings.serverUrl,
            accessToken: settings.accessToken,
          )
        : null;
  }

  Future<Map<String, dynamic>> invokePlugin({
    required String pluginId,
    required String function,
    required Map<String, dynamic> payload,
  }) {
    final client = _client;
    if (!isCsMode || client == null) {
      throw StateError('CS runtime is not active');
    }
    return client.invokePlugin(
      pluginId: pluginId,
      function: function,
      args: [payload],
    );
  }

  Future<Uint8List> invokePluginBytes({
    required String pluginId,
    required String function,
    required String argsJson,
  }) {
    final client = _client;
    if (!isCsMode || client == null) {
      throw StateError('CS runtime is not active');
    }
    final decoded = jsonDecode(argsJson);
    final args = decoded is Map
        ? [Map<String, dynamic>.from(decoded)]
        : [decoded];
    return client.invokePluginBytes(
      pluginId: pluginId,
      function: function,
      args: args,
    );
  }
}
