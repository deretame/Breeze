import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/plugin/plugin_registry_service.dart';

/// 全局插件状态：runtime 列表 + getInfo 缓存。
///
/// getInfo 由 service 广播（fetch 成功 / 缓存失效），这里只收快照。
/// 各页订阅本 cubit 做热切换，不再各自 fetch + 本地缓存。
class PluginRegistryState {
  const PluginRegistryState({
    this.plugins = const {},
    this.infos = const {},
    this.infoErrors = const {},
    this.initOk = const {},
  });

  final Map<String, PluginRuntimeState> plugins;
  final Map<String, Map<String, dynamic>> infos;

  /// 最近一次 getInfo 失败的错误文案（成功即清除）。
  final Map<String, String> infoErrors;

  /// init 已成功跑完的插件 uuid 集合（内存态，service 广播）。
  /// 云收藏等需登录态的功能可用它判断“插件真的就绪了”。
  final Set<String> initOk;

  String pluginName(String uuid) {
    final name = infos[uuid]?['name']?.toString().trim() ?? '';
    return name.isNotEmpty ? name : uuid;
  }

  String? pluginIconUrl(String uuid) =>
      infos[uuid]?['iconUrl']?.toString().trim();

  bool hasCapability(String uuid, String flag) => infos[uuid]?[flag] == true;

  List<String> capablePlugins(String flag) {
    return PluginRegistryService.I
        .sortPlugins(
          plugins.values.where(
            (p) => p.isActive && hasCapability(p.uuid, flag),
          ),
        )
        .map((p) => p.uuid)
        .toList();
  }

  /// 插件是否真的就绪：已启用 + init 成功跑完。
  bool isReady(String uuid) {
    final plugin = plugins[uuid];
    return plugin != null && plugin.isActive && initOk.contains(uuid);
  }

  /// 就绪且有对应能力的插件（云收藏等入口用这个）。
  List<String> readyCapablePlugins(String flag) {
    return capablePlugins(flag).where((uuid) => initOk.contains(uuid)).toList();
  }
}

class PluginRegistryCubit extends Cubit<PluginRegistryState> {
  PluginRegistryCubit({PluginRegistryService? service})
    : _service = service ?? PluginRegistryService.I,
      super(
        PluginRegistryState(
          plugins: (service ?? PluginRegistryService.I).snapshot,
          infos: (service ?? PluginRegistryService.I).infoSnapshot,
          infoErrors: (service ?? PluginRegistryService.I).infoErrorSnapshot,
          initOk: (service ?? PluginRegistryService.I).initOkSnapshot,
        ),
      ) {
    _pluginSubscription = _service.stream.listen((plugins) {
      if (isClosed) {
        return;
      }
      emit(
        PluginRegistryState(
          plugins: plugins,
          infos: state.infos,
          infoErrors: state.infoErrors,
          initOk: state.initOk,
        ),
      );
    });
    _infoSubscription = _service.infoStream.listen((infos) {
      if (isClosed) {
        return;
      }
      emit(
        PluginRegistryState(
          plugins: state.plugins,
          infos: infos,
          infoErrors: state.infoErrors,
          initOk: state.initOk,
        ),
      );
    });
    _infoErrorSubscription = _service.infoErrorStream.listen((errors) {
      if (isClosed) {
        return;
      }
      emit(
        PluginRegistryState(
          plugins: state.plugins,
          infos: state.infos,
          infoErrors: errors,
          initOk: state.initOk,
        ),
      );
    });
    _initOkSubscription = _service.initOkStream.listen((ok) {
      if (isClosed) {
        return;
      }
      emit(
        PluginRegistryState(
          plugins: state.plugins,
          infos: state.infos,
          infoErrors: state.infoErrors,
          initOk: ok,
        ),
      );
    });
    // 启动时 info 可能只有 DB 兜底：后台全量拉取一次，成功即热切换。
    _service.warmupPluginInfos();
  }

  final PluginRegistryService _service;
  late final StreamSubscription<Map<String, PluginRuntimeState>>
  _pluginSubscription;
  late final StreamSubscription<Map<String, Map<String, dynamic>>>
  _infoSubscription;
  late final StreamSubscription<Map<String, String>> _infoErrorSubscription;
  late final StreamSubscription<Set<String>> _initOkSubscription;

  Future<void> refresh() => _service.refreshFromDb();

  @override
  Future<void> close() async {
    await _pluginSubscription.cancel();
    await _infoSubscription.cancel();
    await _infoErrorSubscription.cancel();
    await _initOkSubscription.cancel();
    return super.close();
  }
}
