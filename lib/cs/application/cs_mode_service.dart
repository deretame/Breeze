import 'package:flutter/foundation.dart';

import 'package:zephyr/cs/data/cs_connection_store.dart';
import 'package:zephyr/cs/domain/cs_connection_settings.dart';

/// 管理 CS 连接配置和当前运行模式。
///
/// 这里只负责模式与连接状态，不启动插件、不切换下载队列，也不修改页面。
/// 这些动作由后续的应用启动协调器根据状态决定，保证本地模式继续走原路径。
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
    _loaded = true;
    notifyListeners();
  }

  Future<void> configure({
    required String serverUrl,
    CsDownloadMode? downloadMode,
  }) async {
    _settings = _settings.copyWith(
      serverUrl: serverUrl.trim(),
      downloadMode: downloadMode,
      clearLastServerRevision: true,
    );
    await _persist();
  }

  Future<void> setMode(CsRunMode mode) async {
    if (mode == CsRunMode.cs && !_settings.hasServer) {
      throw StateError('启用 CS 模式前必须先配置服务端地址');
    }
    _settings = _settings.copyWith(mode: mode);
    await _persist();
  }

  void attachSession({required String userId, required String accessToken}) {
    _settings = _settings.copyWith(
      userId: userId,
      accessToken: accessToken,
      clearLastServerRevision: true,
    );
    notifyListeners();
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
