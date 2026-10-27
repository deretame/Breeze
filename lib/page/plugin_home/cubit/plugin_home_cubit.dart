import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/cubit/plugin_registry_cubit.dart';
import 'package:zephyr/plugin/plugin_registry_service.dart';
import 'package:zephyr/network/http/plugin/unauthorized_payload.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/network/http/plugin/unified_plugin_envelope.dart';
import 'package:zephyr/page/plugin_home/plugin_home_bundle.dart';
import 'package:zephyr/page/plugin_home/plugin_home_memory.dart';
import 'package:zephyr/util/error_filter.dart';
import 'package:zephyr/util/json/json_value.dart';
import 'package:zephyr/main.dart';

/// 插件首页 / 云端收藏 bundle 加载 cubit。
///
/// [capabilityFlag] 为 getInfo 标准位：`haveHome` / `haveCloudFavorite`，
/// 选择器与默认插件都只看已启用且该位为 true 的插件。
/// [memoryKey] 决定读写 [PluginHomeMemory] 的哪一项。
class PluginHomeState {
  const PluginHomeState({
    this.loading = true,
    this.error = '',
    this.loginPluginId = '',
    this.pluginId = '',
    this.bundle,
    this.candidates = const [],
    this.reloadSignal = 0,
  });

  final bool loading;
  final String error;

  /// 登录错误对应的插件 uuid（空 = 非登录错误）。
  /// 错误页为它显示“登录/刷新”按钮，不走全局 NeedLogin 跳转。
  final String loginPluginId;
  final String pluginId;
  final PluginHomeBundle? bundle;
  final List<String> candidates;
  final int reloadSignal;

  PluginHomeState copyWith({
    bool? loading,
    String? error,
    String? loginPluginId,
    String? pluginId,
    PluginHomeBundle? Function()? bundle,
    List<String>? candidates,
    int? reloadSignal,
  }) {
    return PluginHomeState(
      loading: loading ?? this.loading,
      error: error ?? this.error,
      loginPluginId: loginPluginId ?? this.loginPluginId,
      pluginId: pluginId ?? this.pluginId,
      bundle: bundle == null ? this.bundle : bundle(),
      candidates: candidates ?? this.candidates,
      reloadSignal: reloadSignal ?? this.reloadSignal,
    );
  }
}

class PluginHomeCubit extends Cubit<PluginHomeState> {
  PluginHomeCubit({
    required this.bundleFnPath,
    required this.capabilityFlag,
    required this.readMemory,
    required this.writeMemory,
    required PluginRegistryCubit registry,
    PluginRegistryService? service,
  }) : _registry = registry,
       _service = service ?? PluginRegistryService.I,
       super(
         PluginHomeState(
           candidates: registry.state.capablePlugins(capabilityFlag),
         ),
       ) {
    _registrySubscription = registry.stream.listen((_) => onRegistryChanged());
  }

  final String bundleFnPath;
  final String capabilityFlag;
  final Future<String?> Function() readMemory;
  final Future<void> Function(String pluginId) writeMemory;

  final PluginRegistryCubit _registry;
  final PluginRegistryService _service;
  late final StreamSubscription<PluginRegistryState> _registrySubscription;

  @override
  Future<void> close() async {
    await _registrySubscription.cancel();
    return super.close();
  }

  /// init 后直接调用，无延迟 hack。
  /// infos 没就绪就在 load 里阻塞等（轮询 registry 快照，最多 10 秒），
  /// 等到再读记忆匹配，不靠广播重入。
  bool _loading = false;

  Future<void> load() async {
    if (isClosed || _loading) {
      return;
    }
    _loading = true;
    try {
      emit(
        state.copyWith(
          loading: true,
          error: '',
          loginPluginId: '',
          bundle: () => null,
          reloadSignal: state.reloadSignal + 1,
        ),
      );
      String pluginId = '';
      try {
        var candidates = _resolveCandidates();
        if (candidates.isEmpty) {
          candidates = await _waitForCandidates();
        }
        emit(state.copyWith(candidates: candidates));
        if (candidates.isEmpty) {
          // 等了 10 秒还是空：真没插件，定死空态。
          if (!isClosed) {
            emit(state.copyWith(loading: false, pluginId: ''));
          }
          return;
        }
        final remembered = (await readMemory())?.trim() ?? '';
        pluginId = candidates.contains(remembered)
            ? remembered
            : candidates.first;
        // 选中后写回固化：记忆为空或失效时选了 candidates.first，
        // 不写下次还是空。写失败不阻断加载。
        try {
          await writeMemory(pluginId);
        } catch (_) {}
        // 未就绪（init 登录还没跑完）就一直 loading 等，不超时。
        await _waitForInitOk(pluginId);
        final bundle = await _loadBundle(pluginId);
        if (isClosed) {
          return;
        }
        emit(
          state.copyWith(
            loading: false,
            error: '',
            loginPluginId: '',
            pluginId: pluginId,
            bundle: () => bundle,
            candidates: _resolveCandidates(),
          ),
        );
      } catch (e) {
        logger.e(e);
        if (isClosed) {
          return;
        }
        _emitFailure(e, fallbackPluginId: pluginId);
      }
    } finally {
      _loading = false;
    }
  }

  /// 阻塞等 infos 就绪：每 200ms 看一次 registry 快照，最多 10 秒。
  /// 中途关了抛错，外层走 error 态。
  Future<List<String>> _waitForCandidates() async {
    for (var i = 0; i < 50; i++) {
      if (isClosed) {
        throw StateError('已关闭');
      }
      final candidates = _resolveCandidates();
      if (candidates.isNotEmpty) {
        return candidates;
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    return _resolveCandidates();
  }

  /// 失败分流：登录错误记 loginPluginId（错误页出登录/刷新按钮），
  /// 其他错误 loginPluginId 置空走普通错误态。错误文案直接透传。
  ///
  /// 只认 [PluginUnauthorizedException]（callUnifiedComicPlugin 已识别好），
  /// 不做二次文本解析。
  void _emitFailure(Object e, {required String fallbackPluginId}) {
    var loginPluginId = '';
    if (e is PluginUnauthorizedException) {
      final id = e.pluginId.trim();
      loginPluginId = id.isNotEmpty ? id : fallbackPluginId;
    }
    emit(
      state.copyWith(
        loading: false,
        error: normalizeSearchErrorMessage(e),
        loginPluginId: loginPluginId,
        bundle: () => null,
      ),
    );
  }

  Future<void> switchPlugin(String pluginId) async {
    final id = pluginId.trim();
    if (id.isEmpty || id == state.pluginId) {
      return;
    }
    await writeMemory(id);
    if (isClosed) {
      return;
    }
    emit(
      state.copyWith(
        loading: true,
        error: '',
        loginPluginId: '',
        pluginId: id,
        bundle: () => null,
        reloadSignal: state.reloadSignal + 1,
      ),
    );
    try {
      // 未就绪就一直 loading 等，不超时。
      await _waitForInitOk(id);
      final bundle = await _loadBundle(id);
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          loading: false,
          error: '',
          loginPluginId: '',
          bundle: () => bundle,
          candidates: _resolveCandidates(),
        ),
      );
    } catch (e) {
      logger.e(e);
      if (isClosed) {
        return;
      }
      _emitFailure(e, fallbackPluginId: id);
    }
  }

  Future<void> retry() => load();

  /// 插件被删/禁用时静默选第一项：当前选中不在候选中则视为不存在。
  /// 只管删/禁用切换，不管加载（加载由 load 内阻塞等）。
  /// 更新时 info 短暂清空但插件本身还在：不切，等 info 回来（广播会再触发）。
  void onRegistryChanged() {
    if (isClosed || state.loading || state.bundle == null) {
      return;
    }
    final candidates = _resolveCandidates();
    if (candidates.isEmpty) {
      if (state.pluginId.isNotEmpty || state.bundle != null) {
        emit(
          state.copyWith(
            pluginId: '',
            bundle: () => null,
            candidates: candidates,
          ),
        );
      }
      return;
    }
    if (candidates.contains(state.pluginId)) {
      if (!_sameList(candidates, state.candidates)) {
        emit(state.copyWith(candidates: candidates));
      }
      return;
    }
    // 当前选中不在候选中：插件本身还在（更新中 info 短暂清空）就不切，
    // 等下一次广播；真被删/禁用了才切 first。
    final current = _service.snapshot[state.pluginId];
    if (current != null && current.isActive) {
      if (!_sameList(candidates, state.candidates)) {
        emit(state.copyWith(candidates: candidates));
      }
      return;
    }
    unawaitedSwitch(candidates.first);
  }

  void unawaitedSwitch(String pluginId) {
    // ignore: discarded_futures
    switchPlugin(pluginId);
  }

  List<String> _resolveCandidates() {
    return _registry.state.capablePlugins(capabilityFlag);
  }

  /// 等该插件 init 成功（登录走完），最多等 30 秒。
  /// 超时后不再等，直接调 bundle：失败走正常登录错误页（带登录/刷新按钮），
  /// 而不是无限转圈。已就绪直接返回；cubit 关了抛错让外层走 error 态。
  Future<void> _waitForInitOk(String pluginId) async {
    if (_service.isPluginInitOk(pluginId)) {
      return;
    }
    try {
      await _service.initOkStream
          .firstWhere((ok) => ok.contains(pluginId))
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      // 超时：init 还没跑完（选线慢/登录卡），不等了，直接调 bundle。
      return;
    }
    if (isClosed) {
      throw StateError('已关闭');
    }
  }

  Future<PluginHomeBundle> _loadBundle(String pluginId) async {
    final response = await callUnifiedComicPlugin(
      pluginId: pluginId,
      fnPath: bundleFnPath,
      core: const <String, dynamic>{},
      extern: <String, dynamic>{'source': pluginId},
      // 登录错误由本页错误态出登录/刷新按钮，不走全局跳转。
      suppressNeedLoginEvent: true,
    );
    final envelope = UnifiedPluginEnvelope.fromMap(response);
    final data = asJsonMap(envelope.data);
    if (data.isEmpty && envelope.scheme.isEmpty) {
      throw StateError('插件返回格式错误');
    }
    return PluginHomeBundle.fromResponse({
      'data': envelope.data,
      'scheme': envelope.scheme,
    }, pluginId);
  }

  bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
