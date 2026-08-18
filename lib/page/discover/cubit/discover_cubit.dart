import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/cs/application/cs_runtime_context.dart';
import 'package:zephyr/cubit/plugin_registry_cubit.dart';
import 'package:zephyr/plugin/plugin_registry_service.dart';
import 'package:zephyr/i18n/strings.g.dart';
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

/// Discover 页状态：每个插件的 info 加载状态和临时交互状态。
class DiscoverState {
  const DiscoverState({
    this.infoStates = const {},
    this.togglingUuids = const {},
  });

  final Map<String, DiscoverPluginInfoState> infoStates;
  final Set<String> togglingUuids;

  DiscoverState copyWith({
    Map<String, DiscoverPluginInfoState>? infoStates,
    Set<String>? togglingUuids,
  }) {
    return DiscoverState(
      infoStates: infoStates ?? this.infoStates,
      togglingUuids: togglingUuids ?? this.togglingUuids,
    );
  }
}

class DiscoverCubit extends Cubit<DiscoverState> {
  DiscoverCubit({
    required PluginRegistryCubit registry,
    PluginRegistryService? service,
  }) : _registry = registry,
       _service = service ?? PluginRegistryService.I,
       super(const DiscoverState()) {
    _subscription = _registry.stream.listen(_syncPluginsAndLoad);
    _syncPluginsAndLoad(_registry.state);
  }

  final PluginRegistryCubit _registry;
  final PluginRegistryService _service;
  late final StreamSubscription<Map<String, PluginRuntimeState>> _subscription;

  final Set<String> _loadingUuids = <String>{};
  final Set<String> _togglingUuids = <String>{};
  final Map<String, String> _cacheKeys = <String, String>{};

  /// 当前默认插件源：优先已启用，否则取首个可见插件。
  String get currentFrom {
    final active = _registry.state.values.where((s) => s.isActive).toList();
    if (active.isNotEmpty) {
      return active.first.uuid;
    }
    final first = _registry.state.values.firstOrNull;
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
      if (CsRuntimeContext.I.isCsMode) {
        final client = CsRuntimeContext.I.client;
        if (client == null) {
          throw StateError('CS 服务端连接尚未建立');
        }
        final plugin = await client.updatePluginState(uuid, enabled: enabled);
        _registry.applyRemoteRecord(plugin);
        return;
      }
      await _service.setEnabled(uuid, enabled);
    } catch (e) {
      showErrorToast(
        enabled
            ? t.discover.pluginEnableFailed(error: e)
            : t.discover.pluginCloseFailed(error: e),
      );
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
  void load() => _syncPluginsAndLoad(_registry.state);

  /// 重新加载所有可见插件的 info。
  Future<void> reload() async {
    _cacheKeys.clear();
    emit(state.copyWith(infoStates: const {}));
    _syncPluginsAndLoad(_registry.state);
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

  void _syncPluginsAndLoad(Map<String, PluginRuntimeState> snapshot) {
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

    emit(state.copyWith(infoStates: newInfoStates));
  }

  Future<void> _loadPluginInfo(String uuid) async {
    if (_loadingUuids.contains(uuid)) {
      return;
    }
    _loadingUuids.add(uuid);

    try {
      final data = CsRuntimeContext.I.isCsMode
          ? await _loadServerPluginInfo(uuid)
          : await _service.fetchPluginInfo(uuid: uuid, runtimeName: uuid);
      if (!isClosed) {
        final infoStates = Map<String, DiscoverPluginInfoState>.from(
          state.infoStates,
        )..[uuid] = DiscoverPluginInfoState(loading: false, data: data);
        emit(state.copyWith(infoStates: infoStates));
      }
    } catch (e) {
      final pluginState = _registry.state[uuid];
      if (pluginState?.debug == true) {
        showErrorToast(t.discover.pluginDebugLoadFailed(error: e));
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

  Future<Map<String, dynamic>> _loadServerPluginInfo(String uuid) async {
    final client = CsRuntimeContext.I.client;
    if (client == null) {
      throw StateError('CS 服务端连接尚未建立');
    }
    final record = await client.pluginDetail(uuid);
    return record.info;
  }

  String _pluginInfoCacheKey(PluginRuntimeState state) {
    return '${state.version}|${state.isDeleted}|${state.debug}|${state.debugUrl ?? ''}';
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
