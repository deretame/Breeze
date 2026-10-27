import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/cubit/plugin_registry_cubit.dart';
import 'package:zephyr/plugin/plugin_registry_service.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/widgets/toast.dart';
import 'package:zephyr/main.dart';

/// Discover 页状态：插件列表 + 全局 info 快照引用 + 开关状态。
///
/// info 数据与失败态都来自全局 [PluginRegistryCubit]，本页只做热切换，
/// 不再各自 fetch + 本地缓存。插件更新后新功能自动显示，无需手动刷新。
class DiscoverState {
  const DiscoverState({
    this.plugins = const {},
    this.infos = const {},
    this.infoErrors = const {},
    this.togglingUuids = const {},
  });

  final Map<String, PluginRuntimeState> plugins;
  final Map<String, Map<String, dynamic>> infos;
  final Map<String, String> infoErrors;
  final Set<String> togglingUuids;

  DiscoverState copyWith({
    Map<String, PluginRuntimeState>? plugins,
    Map<String, Map<String, dynamic>>? infos,
    Map<String, String>? infoErrors,
    Set<String>? togglingUuids,
  }) {
    return DiscoverState(
      plugins: plugins ?? this.plugins,
      infos: infos ?? this.infos,
      infoErrors: infoErrors ?? this.infoErrors,
      togglingUuids: togglingUuids ?? this.togglingUuids,
    );
  }
}

class DiscoverCubit extends Cubit<DiscoverState> {
  DiscoverCubit({
    PluginRegistryService? service,
    required PluginRegistryCubit registry,
  }) : _service = service ?? PluginRegistryService.I,
       super(
         DiscoverState(
           plugins: _visiblePlugins(registry.state.plugins),
           infos: _withDbFallback(
             service ?? PluginRegistryService.I,
             registry.state.infos,
           ),
           infoErrors: registry.state.infoErrors,
         ),
       ) {
    _registrySubscription = registry.stream.listen((registryState) {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          plugins: _visiblePlugins(registryState.plugins),
          infos: _withDbFallback(_service, registryState.infos),
          infoErrors: registryState.infoErrors,
        ),
      );
    });
  }

  /// 内存 info 缺失时用 DB 持久化的 getInfoJson 兜底（旧 _syncPluginsAndLoad
  /// 的 getCachedPluginInfo 逻辑）：禁用清内存缓存后卡片照样显示变灰，不转圈。
  static Map<String, Map<String, dynamic>> _withDbFallback(
    PluginRegistryService service,
    Map<String, Map<String, dynamic>> infos,
  ) {
    final merged = Map<String, Map<String, dynamic>>.from(infos);
    for (final uuid in _visiblePlugins(service.snapshot).keys) {
      if (!merged.containsKey(uuid)) {
        final cached = service.getCachedPluginInfo(uuid);
        if (cached != null) {
          merged[uuid] = cached;
        }
      }
    }
    return merged;
  }

  /// 已删除的不显示（逻辑删除后立即消失）。以前在 _syncPluginsAndLoad 里过滤，
  /// 改全局化时漏了，导致已删插件残留成无限加载。
  static Map<String, PluginRuntimeState> _visiblePlugins(
    Map<String, PluginRuntimeState> all,
  ) {
    return {
      for (final entry in all.entries)
        if (!entry.value.isDeleted) entry.key: entry.value,
    };
  }

  late final StreamSubscription<PluginRegistryState> _registrySubscription;

  final PluginRegistryService _service;

  final Set<String> _togglingUuids = <String>{};

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
      logger.e(e);
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

  /// 初始加载：全量刷新 getInfo（后台 warmup，成功即热切换）。
  void load() => _service.warmupPluginInfos();

  /// 下拉刷新：同 load。
  Future<void> reload() => _service.warmupPluginInfos();

  /// 重试指定插件：后台拉取该插件 getInfo，成功即热切换。
  Future<void> retryLoadInfo(String uuid) =>
      _service.fetchPluginInfo(uuid: uuid, runtimeName: uuid).then((_) {});

  @override
  Future<void> close() async {
    await _registrySubscription.cancel();
    return super.close();
  }
}
