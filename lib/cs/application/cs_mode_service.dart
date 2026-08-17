import 'package:flutter/foundation.dart';
import 'package:zephyr/cs/data/cs_api_client.dart';
import 'package:zephyr/cs/data/cs_connection_store.dart';
import 'package:zephyr/cs/data/cs_migration_exporter.dart';
import 'package:zephyr/cs/data/cs_migration_importer.dart';
import 'package:zephyr/cs/domain/cs_connection_settings.dart';

/// 管理 CS 连接配置和当前运行模式。
///
/// 这里只负责模式、连接状态和会话，不启动插件、不切换本地下载队列，也不修改页面。
/// 本地模式仍走原路径；CS 模式由 [CsRuntimeContext] 将插件请求转发到服务端。
class CsModeService extends ChangeNotifier {
  CsModeService({
    CsConnectionStore? store,
    CsMigrationExporter? migrationExporter,
    CsMigrationImporter? migrationImporter,
  }) : _store = store ?? const CsConnectionStore(),
       _migrationExporter = migrationExporter,
       _migrationImporter = migrationImporter;

  final CsConnectionStore _store;
  final CsMigrationExporter? _migrationExporter;
  final CsMigrationImporter? _migrationImporter;
  CsConnectionSettings _settings = const CsConnectionSettings();
  bool _loaded = false;

  CsConnectionSettings get settings => _settings;

  bool get isLoaded => _loaded;

  Future<void> load() async {
    _settings = await _store.load();
    if (_settings.pendingMode != null) {
      _settings = _settings.copyWith(
        mode: _settings.pendingMode,
        clearPendingMode: true,
      );
    }
    if (_settings.isCsMode &&
        _settings.accessToken?.trim().isNotEmpty != true) {
      // 令牌被系统安全存储清理后，不能让应用停留在一个必然 401 的半连接状态。
      _settings = _settings.copyWith(
        mode: CsRunMode.local,
        clearPendingMode: true,
      );
    }
    await _store.save(_settings);
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
    _settings = _settings.copyWith(mode: mode, clearPendingMode: true);
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

  /// 完成“登录后的 CS 启用”流程。
  ///
  /// 迁移通过服务端事务导入 JSON 快照，成功后才会将设备模式保存为 CS；
  /// 因此导入失败时不会留下一个已经切换、但数据尚未完成的半连接状态。
  Future<void> enableCsMode({
    required bool migrateData,
    required bool migrateDownloads,
  }) async {
    if (migrateDownloads && !migrateData) {
      throw StateError('迁移下载数据前必须先迁移本地数据');
    }
    if (!_settings.hasServer ||
        _settings.accessToken?.trim().isNotEmpty != true) {
      throw StateError('启用 CS 模式前必须先配置服务端并登录');
    }

    if (migrateData) {
      final exporter = _migrationExporter;
      if (exporter == null) {
        throw StateError('本地数据迁移服务尚未初始化');
      }
      final snapshot = exporter.exportSnapshot(
        includeDownloads: migrateDownloads,
      );
      final client = CsApiClient(
        baseUrl: _settings.serverUrl,
        accessToken: _settings.accessToken,
      );
      await client.importMigrationSnapshot(snapshot);
      if (migrateDownloads) {
        await for (final asset in exporter.exportDownloadAssets()) {
          final bytes = await asset.readBytes();
          await client.uploadMigrationAsset(
            comicUniqueKey: asset.comicUniqueKey,
            relativePath: asset.relativePath,
            mediaType: asset.mediaType,
            bytes: Uint8List.fromList(bytes),
          );
        }
      }
    }

    await requestMode(CsRunMode.cs, downloadDataMigrated: migrateDownloads);
  }

  /// 关闭 CS 模式；需要覆盖本地数据时，从服务端导出后再写入本地。
  ///
  /// [downloadDataMigrated] 只由进入 CS 时的迁移结果决定，而不是由当前
  /// 下载位置下拉框决定，避免用户后来改了下载偏好后覆盖错误的数据范围。
  Future<void> closeCsMode({required bool overwriteRemoteData}) async {
    if (!_settings.isCsMode && _settings.pendingMode != CsRunMode.cs) {
      await requestMode(CsRunMode.local, downloadDataMigrated: false);
      return;
    }
    if (overwriteRemoteData) {
      final importer = _migrationImporter;
      if (importer == null) {
        throw StateError('本地数据恢复服务尚未初始化');
      }
      if (!_settings.hasServer ||
          _settings.accessToken?.trim().isNotEmpty != true) {
        throw StateError('覆盖本地数据前必须保持 CS 登录状态');
      }
      final client = CsApiClient(
        baseUrl: _settings.serverUrl,
        accessToken: _settings.accessToken,
      );
      final includeDownloads = _settings.downloadDataMigrated;
      final snapshot = await client.exportMigrationSnapshot(
        includeDownloads: includeDownloads,
      );
      await importer.importSnapshot(
        snapshot,
        includeDownloads: includeDownloads,
        readAsset: client.serverAsset,
      );
    }
    await requestMode(CsRunMode.local, downloadDataMigrated: false);
  }

  /// 保存下次启动时要采用的模式，不改变当前运行时模式。
  Future<void> requestMode(CsRunMode mode, {bool? downloadDataMigrated}) async {
    if (mode == CsRunMode.cs &&
        (!_settings.hasServer ||
            _settings.accessToken?.trim().isNotEmpty != true)) {
      throw StateError('启用 CS 模式前必须先配置服务端并登录');
    }
    _settings = _settings.copyWith(
      pendingMode: mode,
      downloadDataMigrated: downloadDataMigrated,
    );
    await _persist();
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
