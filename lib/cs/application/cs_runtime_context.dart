import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:zephyr/cs/data/cs_api_client.dart';
import 'package:zephyr/cs/domain/cs_connection_settings.dart';
import 'package:zephyr/cs/data/cs_plugin_bridge_channel.dart';

/// 给现有插件调用链提供一个不依赖 Flutter UI 的 CS dispatch 点。
///
/// 本地模式下它保持关闭，调用方继续使用原有 QuickJS；CS 模式下才把
/// 统一插件调用转发到服务端。后续可在这里继续接入能力协商和重连策略。
class CsRuntimeContext {
  CsRuntimeContext._();

  static final CsRuntimeContext I = CsRuntimeContext._();

  CsConnectionSettings _settings = const CsConnectionSettings();
  CsApiClient? _client;
  final CsPluginBridgeChannel _bridgeChannel = CsPluginBridgeChannel();
  String? _bridgeConnectionKey;

  /// 一旦选择 CS 模式就不静默回退到本地插件；未登录时由服务端返回 401，
  /// 由上层连接流程处理重新登录。
  bool get isCsMode => _settings.isCsMode;

  bool get isServerDownload =>
      isCsMode && _settings.downloadMode == CsDownloadMode.server;

  CsApiClient? get client => isCsMode ? _client : null;

  Stream<CsRealtimeEvent> get events => _bridgeChannel.events;

  void update(CsConnectionSettings settings) {
    _settings = settings;
    _client = settings.hasServer
        ? CsApiClient(
            baseUrl: settings.serverUrl,
            accessToken: settings.accessToken,
          )
        : null;
    _updateBridgeChannel(settings);
  }

  void _updateBridgeChannel(CsConnectionSettings settings) {
    final accessToken = settings.accessToken?.trim();
    final shouldConnect =
        settings.isCsMode &&
        settings.hasServer &&
        accessToken != null &&
        accessToken.isNotEmpty;
    if (!shouldConnect) {
      if (_bridgeConnectionKey != null) {
        _bridgeConnectionKey = null;
        unawaited(_bridgeChannel.close());
      }
      return;
    }

    final connectionKey = '${settings.serverUrl}\n$accessToken';
    if (_bridgeConnectionKey == connectionKey) return;
    _bridgeConnectionKey = connectionKey;
    unawaited(
      _bridgeChannel.connect(
        serverUrl: settings.serverUrl,
        accessToken: accessToken,
      ),
    );
  }

  Future<Map<String, dynamic>> invokePlugin({
    required String pluginId,
    required String function,
    required Map<String, dynamic> payload,
    String? taskGroupKey,
  }) {
    final client = _client;
    if (!isCsMode || client == null) {
      throw StateError('CS runtime is not active');
    }
    return client.invokePlugin(
      pluginId: pluginId,
      function: function,
      args: [payload],
      taskGroupKey: taskGroupKey,
    );
  }

  Future<Uint8List> invokePluginBytes({
    required String pluginId,
    required String function,
    required String argsJson,
    String? taskGroupKey,
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
      taskGroupKey: taskGroupKey,
    );
  }

  Future<void> cancelPluginTaskGroup({
    required String pluginId,
    required String taskGroupKey,
  }) {
    final client = _client;
    if (!isCsMode || client == null) {
      throw StateError('CS runtime is not active');
    }
    return client.cancelPluginTaskGroup(
      pluginId: pluginId,
      taskGroupKey: taskGroupKey,
    );
  }

  Future<CsDownloadTask> createServerDownload({
    required String pluginId,
    required String comicId,
    required List<String> chapterIds,
    Map<String, dynamic> options = const {},
  }) {
    final activeClient = client;
    if (activeClient == null ||
        _settings.downloadMode != CsDownloadMode.server) {
      throw StateError('服务端下载未启用');
    }
    return activeClient.createServerDownload(
      pluginId: pluginId,
      comicId: comicId,
      chapterIds: chapterIds,
      options: options,
    );
  }

  Future<List<CsDownloadTask>> serverDownloads() {
    final activeClient = client;
    if (activeClient == null) {
      throw StateError('CS runtime is not active');
    }
    return activeClient.listServerDownloads();
  }
}
