import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/object_box.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/plugin/models/plugin_runtime_state.dart';
import 'package:zephyr/src/rust/api/qjs.dart';
import 'package:zephyr/src/rust/qjs.dart';
import 'package:zephyr/network/utils/direct_dio.dart';
import 'package:zephyr/util/get_path.dart';
import 'package:zephyr/util/json/json_value.dart';

export 'package:zephyr/plugin/models/plugin_runtime_state.dart';

class PluginRegistryService {
  PluginRegistryService._();

  static final PluginRegistryService I = PluginRegistryService._();

  final Map<String, PluginRuntimeState> _states = {};
  final _streamController =
      StreamController<Map<String, PluginRuntimeState>>.broadcast();
  ObjectBox? _objectbox;
  final Map<String, Map<String, dynamic>> _pluginInfoCache = {};
  final Set<String> _pluginInitDone = <String>{};

  Stream<Map<String, PluginRuntimeState>> get stream =>
      _streamController.stream;

  Map<String, PluginRuntimeState> get snapshot => Map.unmodifiable(_states);

  PluginRuntimeState? getByUuid(String uuid) => _states[uuid];

  Map<String, dynamic>? getCachedPluginInfo(String uuid) =>
      _pluginInfoCache[uuid];

  Future<void> init() async {
    _objectbox = objectbox;
    await refreshFromDb();
  }

  Future<void> refreshFromDb() async {
    final objectbox = _objectbox;
    if (objectbox == null) {
      return;
    }

    final list = objectbox.pluginInfoBox.getAll();
    _states
      ..clear()
      ..addEntries(list.map((item) => MapEntry(item.uuid, _toState(item))));
    _emit();
  }

  Future<void> reconcileAfterExternalSync({
    Map<String, PluginRuntimeState>? previousSnapshot,
  }) async {
    final previous = Map<String, PluginRuntimeState>.from(
      previousSnapshot ?? snapshot,
    );
    logger.d('[plugin-sync] reconcile_start previous=${previous.length}');

    await refreshFromDb();

    final current = snapshot;
    final affected = <String>{...previous.keys, ...current.keys}.where((uuid) {
      final before = previous[uuid];
      final after = current[uuid];
      if (before == null || after == null) {
        return true;
      }
      return before.version != after.version ||
          before.originScript != after.originScript ||
          before.isEnabled != after.isEnabled ||
          before.isDeleted != after.isDeleted ||
          before.debug != after.debug ||
          before.debugUrl != after.debugUrl;
    }).toList();
    logger.d(
      '[plugin-sync] reconcile_diff current=${current.length} '
      'affected=${affected.length} uuids=${affected.join(',')}',
    );

    for (final uuid in affected) {
      _pluginInfoCache.remove(uuid);
      _pluginInitDone.remove(uuid);

      final runtimeName = resolveRuntimeName(uuid);
      try {
        final runtimeReady = await isQjsRuntimeInitialized(name: runtimeName);
        if (runtimeReady) {
          await qjsDropRuntime(runtimeName: runtimeName);
        }
      } catch (e, st) {
        logger.w('同步后清理插件 runtime 失败: $uuid', error: e, stackTrace: st);
      }
    }

    for (final uuid in affected) {
      final plugin = current[uuid];
      if (plugin == null || !plugin.isActive) {
        continue;
      }

      final runtimeName = resolveRuntimeName(uuid);
      try {
        await ensurePluginRuntimeReady(plugin, runtimeName: runtimeName);
        await runPluginInitIfNeeded(plugin, runtimeName: runtimeName);
      } catch (e, st) {
        logger.w('同步后重建插件 runtime 失败: $uuid', error: e, stackTrace: st);
      }
    }
    logger.d(
      '[plugin-sync] reconcile_done active=${current.values.where((e) => e.isActive).length}',
    );
  }

  Future<void> initializeGlobalRuntime() async {
    const globalRuntimeName = 'global';
    final ready = await isQjsRuntimeInitialized(name: globalRuntimeName);
    if (!ready) {
      await buildQjsRuntime(
        request: const QjsRuntimeBuildRequest(
          runtimeName: globalRuntimeName,
          injectFilesystem: false,
        ),
      );
    }
  }

  Future<void> initializeActivePluginRuntimes() async {
    final plugins = updateCheckTargets();
    await Future.wait(
      plugins.map((plugin) async {
        final runtimeName = resolveRuntimeName(plugin.uuid);
        await ensurePluginRuntimeReady(plugin, runtimeName: runtimeName);
      }),
      eagerError: false,
    );

    await Future.wait(
      plugins.map((plugin) async {
        final runtimeName = resolveRuntimeName(plugin.uuid);
        await runPluginInitIfNeeded(plugin, runtimeName: runtimeName);
      }),
      eagerError: false,
    );
  }

  Future<void> warmupPluginInfos() async {
    await initializeGlobalRuntime();
    final plugins = updateCheckTargets();
    await Future.wait(
      plugins.map((plugin) async {
        final runtimeName = resolveRuntimeName(plugin.uuid);
        try {
          await fetchPluginInfo(uuid: plugin.uuid, runtimeName: runtimeName);
        } catch (e) {
          await updateLoadResult(
            plugin.uuid,
            success: false,
            error: e.toString(),
          );
        }
      }),
      eagerError: false,
    );
  }

  Future<Map<String, dynamic>> fetchPluginInfo({
    required String uuid,
    required String runtimeName,
  }) async {
    final plugin = _states[uuid];
    if (plugin == null || plugin.isDeleted) {
      throw StateError('插件不可用: $uuid');
    }

    final onceRuntimeName = 'plugin_info_${uuid.replaceAll('-', '_')}';
    final bundleJs = await _resolveBundleJs(plugin);
    final raw = await qjsCallOnce(
      runtimeName: onceRuntimeName,
      bundleJs: bundleJs,
      fnPath: 'getInfo',
      argsJson: '{}',
    );
    final decoded = requireJsonMap(jsonDecode(raw));
    _pluginInfoCache[uuid] = decoded;
    await updateLoadResult(uuid, success: true, error: null);
    return decoded;
  }

  List<PluginRuntimeState> activePlugins() {
    return _states.values.where((item) => item.isActive).toList()
      ..sort((a, b) => a.insertedAt.compareTo(b.insertedAt));
  }

  List<PluginRuntimeState> updateCheckTargets() {
    return activePlugins();
  }

  Future<void> runForUpdateTargets(
    Future<void> Function(PluginRuntimeState plugin) task,
  ) async {
    final targets = updateCheckTargets();
    for (final plugin in targets) {
      await task(plugin);
    }
  }

  List<String> getEnabledUuids() {
    return _states.values
        .where((item) => item.isEnabled && !item.isDeleted)
        .map((item) => item.uuid)
        .toList();
  }

  int getActivePluginCount() {
    return _states.values.where((item) => item.isActive).length;
  }

  bool isAnyPluginEnabled() {
    return _states.values.any((item) => item.isActive);
  }

  List<PluginRuntimeState> getSortedActivePlugins() {
    return activePlugins();
  }

  Future<void> upsert(PluginInfo info) async {
    final objectbox = _objectbox;
    if (objectbox == null) {
      return;
    }

    objectbox.pluginInfoBox.put(info);
    _states[info.uuid] = _toState(info);
    _pluginInfoCache.remove(info.uuid);
    _pluginInitDone.remove(info.uuid);
    _emit();
  }

  Future<void> setEnabled(String uuid, bool enabled) async {
    final objectbox = _objectbox;
    if (objectbox == null) {
      return;
    }
    final found = objectbox.pluginInfoBox
        .query(PluginInfo_.uuid.equals(uuid))
        .build()
        .findFirst();
    if (found == null) {
      return;
    }
    found.isEnabled = enabled;
    found.updatedAt = DateTime.now().toUtc();
    objectbox.pluginInfoBox.put(found);
    _states[uuid] = _toState(found);
    _pluginInfoCache.remove(uuid);
    _pluginInitDone.remove(uuid);
    _emit();

    final runtimeName = resolveRuntimeName(uuid);
    if (enabled) {
      await ensurePluginRuntimeReady(_states[uuid]!, runtimeName: runtimeName);
      await runPluginInitIfNeeded(_states[uuid]!, runtimeName: runtimeName);
    } else {
      try {
        final runtimeReady = await isQjsRuntimeInitialized(name: runtimeName);
        if (runtimeReady) {
          await qjsDropRuntime(runtimeName: runtimeName);
        }
      } catch (e, st) {
        logger.w('禁用插件时释放 runtime 失败: $uuid', error: e, stackTrace: st);
      }
    }
  }

  Future<void> updateLoadResult(
    String uuid, {
    required bool success,
    String? error,
  }) async {
    final objectbox = _objectbox;
    if (objectbox == null) {
      return;
    }
    final found = objectbox.pluginInfoBox
        .query(PluginInfo_.uuid.equals(uuid))
        .build()
        .findFirst();
    if (found == null) {
      return;
    }
    found.lastLoadSuccess = success;
    found.lastLoadError = error;
    found.updatedAt = DateTime.now().toUtc();
    objectbox.pluginInfoBox.put(found);
    _states[uuid] = _toState(found);
    _emit();
  }

  Future<void> updateDebugConfig(
    String uuid, {
    required bool debug,
    String? debugUrl,
  }) async {
    final objectbox = _objectbox;
    if (objectbox == null) {
      return;
    }
    final found = objectbox.pluginInfoBox
        .query(PluginInfo_.uuid.equals(uuid))
        .build()
        .findFirst();
    if (found == null) {
      return;
    }
    found.debug = debug;
    found.debugUrl = debugUrl?.trim().isEmpty == true ? null : debugUrl?.trim();
    found.updatedAt = DateTime.now().toUtc();
    objectbox.pluginInfoBox.put(found);
    _states[uuid] = _toState(found);
    _pluginInfoCache.remove(uuid);
    _pluginInitDone.remove(uuid);
    _emit();
  }

  Future<void> deletePlugin(String uuid) async {
    final objectbox = _objectbox;
    if (objectbox == null) {
      return;
    }
    final found = objectbox.pluginInfoBox
        .query(PluginInfo_.uuid.equals(uuid))
        .build()
        .findFirst();
    if (found == null) {
      throw StateError('插件不存在: $uuid');
    }

    final runtimeName = resolveRuntimeName(uuid);
    try {
      final runtimeReady = await isQjsRuntimeInitialized(name: runtimeName);
      if (runtimeReady) {
        await qjsDropRuntime(runtimeName: runtimeName);
      }
    } catch (_) {
      // runtime 失败不阻断删除主流程
    }

    await _deletePluginDownloadFolders(uuid);
    _deletePluginConfigs(objectbox, uuid);
    _deletePluginRelatedData(objectbox, uuid);

    final now = DateTime.now().toUtc();
    found
      ..originScript = ''
      ..isEnabled = false
      ..isDeleted = true
      ..deletedAt = now
      ..updatedAt = now
      ..lastLoadSuccess = false
      ..lastLoadError = null;
    objectbox.pluginInfoBox.put(found);
    _states[uuid] = _toState(found);
    _pluginInfoCache.remove(uuid);
    _pluginInitDone.remove(uuid);
    _emit();
  }

  Future<void> _deletePluginDownloadFolders(String uuid) async {
    final downloadRoot = await getDownloadPath();
    final root = p.join(downloadRoot, uuid);
    final directory = Directory(root);
    final exists = await directory.exists();
    if (!exists) {
      return;
    }
    try {
      await directory.delete(recursive: true);
    } catch (e) {
      throw StateError('删除下载目录失败: $root, error: $e');
    }
  }

  void _deletePluginRelatedData(ObjectBox objectbox, String uuid) {
    objectbox.unifiedFavoriteBox
        .query(UnifiedComicFavorite_.source.equals(uuid))
        .build()
        .remove();
    objectbox.unifiedHistoryBox
        .query(UnifiedComicHistory_.source.equals(uuid))
        .build()
        .remove();
    objectbox.unifiedDownloadBox
        .query(UnifiedComicDownload_.source.equals(uuid))
        .build()
        .remove();
  }

  void _deletePluginConfigs(ObjectBox objectbox, String uuid) {
    final candidateNames = _buildPluginConfigNameCandidates(uuid);
    if (candidateNames.isEmpty) {
      return;
    }

    final idsToDelete = objectbox.pluginConfigBox
        .getAll()
        .where((item) => candidateNames.contains(item.name.trim()))
        .map((item) => item.id)
        .toList();
    if (idsToDelete.isEmpty) {
      return;
    }
    objectbox.pluginConfigBox.removeMany(idsToDelete);
  }

  Set<String> _buildPluginConfigNameCandidates(String uuid) {
    final candidates = <String>{};
    for (final raw in <String>{uuid, resolveRuntimeName(uuid)}) {
      for (final normalized in _normalizePluginNameCandidates(raw)) {
        candidates.add(normalized);
        candidates.add('($normalized)');
        final onceRuntime = 'plugin_info_${normalized.replaceAll('-', '_')}';
        candidates.add(onceRuntime);
        candidates.add('($onceRuntime)');
      }
    }
    return candidates.where((item) => item.trim().isNotEmpty).toSet();
  }

  Set<String> _normalizePluginNameCandidates(String raw) {
    final names = <String>{};
    var value = raw.trim();
    if (value.isEmpty) {
      return names;
    }
    names.add(value);

    while (value.length >= 2 && value.startsWith('(') && value.endsWith(')')) {
      value = value.substring(1, value.length - 1).trim();
      if (value.isEmpty) {
        break;
      }
      names.add(value);
    }

    return names;
  }

  String resolveRuntimeName(String uuid) {
    return uuid;
  }

  Future<void> ensurePluginRuntimeReady(
    PluginRuntimeState plugin, {
    required String runtimeName,
  }) async {
    final bundleJs = await _resolveBundleJs(plugin);
    await buildQjsRuntime(
      request: QjsRuntimeBuildRequest(
        runtimeName: runtimeName,
        injectFilesystem: false,
        bundle: QjsRuntimeBundleBuild(
          bundleName: runtimeName,
          bundleJs: bundleJs,
        ),
      ),
    );
    _pluginInitDone.remove(plugin.uuid);
  }

  Future<void> runPluginInitIfNeeded(
    PluginRuntimeState plugin, {
    required String runtimeName,
  }) async {
    if (_pluginInitDone.contains(plugin.uuid)) {
      return;
    }

    try {
      await callUnifiedComicPlugin(
        pluginId: runtimeName,
        fnPath: 'init',
        core: {},
      );
      _pluginInitDone.add(plugin.uuid);
      await updateLoadResult(plugin.uuid, success: true, error: null);
    } catch (e) {
      final err = e.toString();
      if (err.contains('target is not function: init')) {
        _pluginInitDone.add(plugin.uuid);
        logger.w('插件未实现 init，已跳过: ${plugin.uuid}');
        return;
      }
      await updateLoadResult(
        plugin.uuid,
        success: false,
        error: 'init 执行失败: $e',
      );
      logger.w('插件 init 执行失败: ${plugin.uuid}', error: e);
    }
  }

  Future<String> _resolveBundleJs(PluginRuntimeState plugin) async {
    if (plugin.debug && (plugin.debugUrl?.trim().isNotEmpty ?? false)) {
      try {
        final response = await directDio.get(plugin.debugUrl!.trim());
        final debugBundle = response.data?.toString() ?? '';
        if (debugBundle.trim().isNotEmpty) {
          logger.d('[plugin-bundle] source=debugUrl plugin=${plugin.uuid}');
          return debugBundle;
        }
        throw StateError('debug bundle 为空');
      } catch (e) {
        await updateLoadResult(
          plugin.uuid,
          success: false,
          error: 'debug bundle 拉取失败: $e',
        );
        logger.w('debug bundle 拉取失败，回退数据库: ${plugin.uuid}', error: e);
      }
    }

    final dbBundle = _loadPluginBundleFromDb(plugin.uuid);
    if (dbBundle != null) {
      logger.d('[plugin-bundle] source=db plugin=${plugin.uuid}');
      return dbBundle;
    }

    throw StateError('bundle_js不能为空: ${plugin.uuid}');
  }

  String? _loadPluginBundleFromDb(String pluginId) {
    final text = _states[pluginId]?.originScript ?? '';
    if (text.trim().isEmpty) {
      return null;
    }
    return text;
  }

  PluginRuntimeState _toState(PluginInfo item) {
    return PluginRuntimeState(
      uuid: item.uuid,
      version: item.version,
      originScript: item.originScript,
      isEnabled: item.isEnabled,
      isDeleted: item.isDeleted,
      debug: item.debug,
      debugUrl: item.debugUrl,
      lastLoadSuccess: item.lastLoadSuccess,
      lastLoadError: item.lastLoadError,
      insertedAt: item.insertedAt,
      updatedAt: item.updatedAt,
      deletedAt: item.deletedAt,
    );
  }

  void _emit() {
    _streamController.add(snapshot);
  }
}
