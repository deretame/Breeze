import 'package:flutter/foundation.dart';

import 'package:zephyr/cs/data/cs_api_client.dart';
import 'package:zephyr/cs/data/cs_connection_store.dart';
import 'package:zephyr/cs/domain/cs_connection_settings.dart';

/// 管理 CS 连接配置和当前运行模式。
///
/// 这里只负责模式、连接状态和会话，不启动插件、不切换本地下载队列，也不修改页面。
/// 本地模式仍走原路径；CS 模式由 [CsRuntimeContext] 将插件请求转发到服务端。
class CsModeService extends ChangeNotifier {
  CsModeService({CsConnectionStore? store})
    : _store = store ?? const CsConnectionStore();

  final CsConnectionStore _store;
  CsConnectionSettings _settings = const CsConnectionSettings();
  bool _loaded = false;

  CsConnectionSettings get settings => _settings;

  bool get isLoaded => _loaded;

  Future<void> load() async {
    _settings = await _store.load();
    if (_settings.isCsMode &&
        _settings.accessToken?.trim().isNotEmpty != true) {
      // 令牌被系统安全存储清理后，不能让应用停留在一个必然 401 的半连接状态。
      _settings = _settings.copyWith(mode: CsRunMode.local);
      await _store.save(_settings);
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> configure({
    required String serverUrl,
    CsDownloadMode? downloadMode,
  }) async {
    final normalizedServerUrl = serverUrl.trim();
    final serverChanged = normalizedServerUrl != _settings.serverUrl;
    _settings = _settings.copyWith(
      serverUrl: normalizedServerUrl,
      downloadMode: downloadMode,
      clearLastServerRevision: true,
      clearUserId: serverChanged,
      clearAccessToken: serverChanged,
    );
    await _persist();
  }

  Future<void> setMode(CsRunMode mode) async {
    if (mode == CsRunMode.cs &&
        (!_settings.hasServer ||
            _settings.accessToken?.trim().isNotEmpty != true)) {
      throw StateError('启用 CS 模式前必须先配置服务端并登录');
    }
    _settings = _settings.copyWith(mode: mode);
    await _persist();
  }

  Future<CsSession> login({
    required String username,
    required String password,
    bool register = false,
  }) async {
    if (!_settings.hasServer) {
      throw StateError('登录 CS 前必须先配置服务端地址');
    }
    final client = CsApiClient(baseUrl: _settings.serverUrl);
    final session = register
        ? await client.register(username: username, password: password)
        : await client.login(username: username, password: password);
    await attachSession(
      userId: session.userId,
      accessToken: session.accessToken,
    );
    return session;
  }

  Future<void> attachSession({
    required String userId,
    required String accessToken,
  }) async {
    _settings = _settings.copyWith(
      userId: userId,
      accessToken: accessToken,
      clearLastServerRevision: true,
    );
    await _persist();
  }

  void updateServerRevision(int revision) {
    _settings = _settings.copyWith(lastServerRevision: revision);
    notifyListeners();
  }

  Future<void> signOut() async {
    _settings = _settings.copyWith(clearUserId: true, clearAccessToken: true);
    await _persist();
  }

  Future<void> _persist() async {
    await _store.save(_settings);
    notifyListeners();
  }
}
