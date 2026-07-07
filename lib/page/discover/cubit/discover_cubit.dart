import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/plugin/plugin_registry_service.dart';
import 'package:zephyr/widgets/toast.dart';

/// 单个插件 info 的加载状态。
class DiscoverPluginInfoState {
  const DiscoverPluginInfoState({this.loading = true, this.error, this.data});

  final bool loading;
  final String? error;
  final Map<String, dynamic>? data;

  DiscoverPluginInfoState copyWith({
    bool? loading,
    String? error,
    Map<String, dynamic>? data,
  }) {
    return DiscoverPluginInfoState(
      loading: loading ?? this.loading,
      error: error,
      data: data ?? this.data,
    );
  }
}

/// Discover 页状态：插件列表 + 每个插件的 info 加载状态 + 开关状态。
class DiscoverState {
  const DiscoverState({
    this.plugins = const {},
    this.infoStates = const {},
    this.togglingUuids = const {},
  });

  final Map<String, PluginRuntimeState> plugins;
  final Map<String, DiscoverPluginInfoState> infoStates;
  final Set<String> togglingUuids;

  DiscoverState copyWith({
    Map<String, PluginRuntimeState>? plugins,
    Map<String, DiscoverPluginInfoState>? infoStates,
    Set<String>? togglingUuids,
  }) {
    return DiscoverState(
      plugins: plugins ?? this.plugins,
      infoStates: infoStates ?? this.infoStates,
      togglingUuids: togglingUuids ?? this.togglingUuids,
    );
  }
}

class DiscoverCubit extends Cubit<DiscoverState> {
  DiscoverCubit({PluginRegistryService? service})
    : _service = service ?? PluginRegistryService.I,
      super(const DiscoverState()) {
    _subscription = _service.stream.listen((_) => _syncPluginsAndLoad());
    _syncPluginsAndLoad();
  }

  final PluginRegistryService _service;
  late final StreamSubscription<Map<String, PluginRuntimeState>> _subscription;

  final Set<String> _loadingUuids = <String>{};
  final Set<String> _togglingUuids = <String>{};
  final Map<String, String> _cacheKeys = <String, String>{};

  /// 当前默认插件源：优先已启用，否则取首个可见插件。
  String get currentFrom {
    final active = state.plugins.values.where((s) => s.isActive).toList();
    if (active.isNotEmpty) {
      return active.first.uuid;
    }
    final first = state.plugins.values.firstOrNull;
    return first?.uuid ?? '';
  }

  /// 切换插件启用状态。
  ///
  /// 开启时会初始化插件运行时并执行 [init]；关闭时会立即销毁当前运行时。
  Future<void> toggleEnabled(String uuid, bool enabled) async {
    if (_togglingUuids.contains(uuid)) {
      return;
    }

    _togglingUuids.add(uuid);
    _emitToggling();

    try {
      await _service.setEnabled(uuid, enabled);
    } catch (e) {
      showErrorToast('插件${enabled ? '启用' : '关闭'}失败: $e');
    } finally {
      _togglingUuids.remove(uuid);
      _emitToggling();
    }
  }

  void _emitToggling() {
    if (isClosed) {
      return;
    }
    emit(state.copyWith(togglingUuids: Set<String>.from(_togglingUuids)));
  }

  /// 初始加载，与 [reload] 区别是不清空缓存，仅补齐缺失的 info。
  void load() => _syncPluginsAndLoad();

  /// 重新加载所有可见插件的 info。
  Future<void> reload() async {
    _cacheKeys.clear();
    emit(state.copyWith(infoStates: const {}));
    _syncPluginsAndLoad();
  }

  /// 强制重新加载指定插件的 info。
  Future<void> retryLoadInfo(String uuid) async {
    _cacheKeys.remove(uuid);
    final infoStates = Map<String, DiscoverPluginInfoState>.from(
      state.infoStates,
    )..remove(uuid);
    emit(state.copyWith(infoStates: infoStates));
    await _loadPluginInfo(uuid);
  }

  void _syncPluginsAndLoad() {
    final snapshot = _service.snapshot;
    final visibleEntries =
        snapshot.entries.where((e) => !e.value.isDeleted).toList()
          ..sort((a, b) => a.value.insertedAt.compareTo(b.value.insertedAt));
    final plugins = Map<String, PluginRuntimeState>.fromEntries(visibleEntries);

    final newInfoStates = Map<String, DiscoverPluginInfoState>.from(
      state.infoStates,
    );
    final newCacheKeys = <String, String>{};

    for (final entry in plugins.entries) {
      final uuid = entry.key;
      final pluginState = entry.value;
      final cacheKey = _pluginInfoCacheKey(pluginState);
      final previousCacheKey = _cacheKeys[uuid];

      if (previousCacheKey != null && previousCacheKey != cacheKey) {
        newInfoStates.remove(uuid);
      }
      newCacheKeys[uuid] = cacheKey;

      if (!newInfoStates.containsKey(uuid) && !_loadingUuids.contains(uuid)) {
        final cached = _service.getCachedPluginInfo(uuid);
        if (cached != null) {
          newInfoStates[uuid] = DiscoverPluginInfoState(
            loading: false,
            data: cached,
          );
        } else {
          newInfoStates[uuid] = const DiscoverPluginInfoState(loading: true);
          _loadPluginInfo(uuid);
        }
      }
    }

    // 清理已删除插件的 info 状态。
    for (final uuid in state.infoStates.keys.toList()) {
      if (!plugins.containsKey(uuid)) {
        newInfoStates.remove(uuid);
      }
    }

    _cacheKeys
      ..clear()
      ..addAll(newCacheKeys);

    emit(state.copyWith(plugins: plugins, infoStates: newInfoStates));
  }

  Future<void> _loadPluginInfo(String uuid) async {
    if (_loadingUuids.contains(uuid)) {
      return;
    }
    _loadingUuids.add(uuid);

    try {
      final data = await _service.fetchPluginInfo(
        uuid: uuid,
        runtimeName: uuid,
      );
      if (!isClosed) {
        final infoStates = Map<String, DiscoverPluginInfoState>.from(
          state.infoStates,
        )..[uuid] = DiscoverPluginInfoState(loading: false, data: data);
        emit(state.copyWith(infoStates: infoStates));
      }
    } catch (e) {
      final pluginState = _service.getByUuid(uuid);
      if (pluginState?.debug == true) {
        showErrorToast('插件调试加载失败，已回退数据库: $e');
      }
      if (!isClosed) {
        final infoStates =
            Map<String, DiscoverPluginInfoState>.from(state.infoStates)
              ..[uuid] = DiscoverPluginInfoState(
                loading: false,
                error: e.toString(),
              );
        emit(state.copyWith(infoStates: infoStates));
      }
    } finally {
      _loadingUuids.remove(uuid);
    }
  }

  String _pluginInfoCacheKey(PluginRuntimeState state) {
    return '${state.isDeleted}|${state.debug}|${state.debugUrl ?? ''}';
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
