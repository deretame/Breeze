import 'dart:async';
import 'dart:convert';

import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/object_box.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/src/rust/api/qjs.dart';
import 'package:zephyr/util/direct_dio.dart';
import 'package:zephyr/util/json/json_value.dart';

class PluginRuntimeState {
  const PluginRuntimeState({
    required this.uuid,
    required this.version,
    required this.originScript,
    required this.isEnabled,
    required this.isDeleted,
    required this.debug,
    required this.debugUrl,
    required this.lastLoadSuccess,
    required this.lastLoadError,
    required this.insertedAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  final String uuid;
  final String version;
  final String originScript;
  final bool isEnabled;
  final bool isDeleted;
  final bool debug;
  final String? debugUrl;
  final bool lastLoadSuccess;
  final String? lastLoadError;
  final DateTime insertedAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isActive => isEnabled && !isDeleted;

  PluginRuntimeState copyWith({
    String? version,
    String? originScript,
    bool? isEnabled,
    bool? isDeleted,
    bool? debug,
    String? debugUrl,
    bool? lastLoadSuccess,
    String? lastLoadError,
    DateTime? insertedAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return PluginRuntimeState(
      uuid: uuid,
      version: version ?? this.version,
      originScript: originScript ?? this.originScript,
      isEnabled: isEnabled ?? this.isEnabled,
      isDeleted: isDeleted ?? this.isDeleted,
      debug: debug ?? this.debug,
      debugUrl: debugUrl ?? this.debugUrl,
      lastLoadSuccess: lastLoadSuccess ?? this.lastLoadSuccess,
      lastLoadError: lastLoadError,
      insertedAt: insertedAt ?? this.insertedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt,
    );
  }
}

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

  Future<void> init(ObjectBox objectbox) async {
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

  Future<void> initializeGlobalRuntime() async {
    const globalRuntimeName = 'global';
    final ready = await isQjsRuntimeInitialized(name: globalRuntimeName);
    if (!ready) {
      await initQjsRuntime(name: globalRuntimeName);
    }
  }

  Future<void> initializeActivePluginRuntimes() async {
    final plugins = updateCheckTargets();
    await Future.wait(
      plugins.map((plugin) async {
        final runtimeName = resolveRuntimeName(plugin.uuid);
        await _ensurePluginRuntimeReady(plugin, runtimeName: runtimeName);
      }),
      eagerError: false,
    );

    await Future.wait(
      plugins.map((plugin) async {
        final runtimeName = resolveRuntimeName(plugin.uuid);
        await _runPluginInitIfNeeded(plugin, runtimeName: runtimeName);
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

  Future<void> upsert(PluginInfo info) async {
    final objectbox = _objectbox;
    if (objectbox == null) {
      return;
    }

    objectbox.pluginInfoBox.put(info);
    _states[info.uuid] = _toState(info);
    if (info.isDeleted) {
      _pluginInfoCache.remove(info.uuid);
    }
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
    if (enabled) {
      final runtimeName = resolveRuntimeName(uuid);
      await _ensurePluginRuntimeReady(_states[uuid]!, runtimeName: runtimeName);
      await _runPluginInitIfNeeded(_states[uuid]!, runtimeName: runtimeName);
    }
    _emit();
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
      return;
    }

    final now = DateTime.now().toUtc();
    found.isDeleted = true;
    found.isEnabled = false;
    found.deletedAt = now;
    found.updatedAt = now;

    final runtimeName = resolveRuntimeName(uuid);
    try {
      final runtimeReady = await isQjsRuntimeInitialized(name: runtimeName);
      if (runtimeReady) {
        await qjsDropRuntime(runtimeName: runtimeName);
      }
    } catch (e) {
      found.lastLoadError = 'runtime 销毁失败: $e';
    }

    objectbox.pluginInfoBox.put(found);
    _states[uuid] = _toState(found);
    _pluginInfoCache.remove(uuid);
    _pluginInitDone.remove(uuid);
    _emit();
  }

  String resolveRuntimeName(String uuid) {
    return uuid;
  }

  Future<void> _ensurePluginRuntimeReady(
    PluginRuntimeState plugin, {
    required String runtimeName,
  }) async {
    final ready = await isQjsRuntimeInitialized(name: runtimeName);
    if (ready) {
      return;
    }
    final bundleJs = await _resolveBundleJs(plugin);
    await initQjsRuntimeWithBundle(
      runtimeName: runtimeName,
      bundleName: runtimeName,
      bundleJs: bundleJs,
    );
  }

  Future<void> _runPluginInitIfNeeded(
    PluginRuntimeState plugin, {
    required String runtimeName,
  }) async {
    if (_pluginInitDone.contains(plugin.uuid)) {
      return;
    }

    try {
      await qjsCall(runtimeName: runtimeName, fnPath: 'init', argsJson: '{}');
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
