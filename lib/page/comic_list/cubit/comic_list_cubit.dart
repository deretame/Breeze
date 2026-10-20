import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/network/http/plugin/unauthorized_payload.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/network/http/plugin/unified_plugin_envelope.dart';
import 'package:zephyr/page/comic_list/cubit/comic_list_state.dart';
import 'package:zephyr/page/comic_list/models/comic_list_scene.dart';
import 'package:zephyr/page/comic_list/models/list_filter_bundle.dart';
import 'package:zephyr/page/comic_list/scene_filter/plugin_list_filter_schema.dart';
import 'package:zephyr/util/error_filter.dart';
import 'package:zephyr/util/json/json_value.dart';

export 'package:zephyr/page/comic_list/cubit/comic_list_state.dart';

class ComicListCubit extends Cubit<ComicListState> {
  ComicListCubit({
    this.initialScene,
    this.sceneSource,
    this.sceneBundleFnPath,
    this.sceneBundleFnPathFallback,
    // 新两页（插件首页/云收藏）内的 scene 传 true：登录错误不出全局弹窗，
    // 由外层错误页出登录/刷新按钮。其他调用方保持默认行为。
    this.suppressNeedLoginEvent = false,
  }) : super(const ComicListState()) {
    _init();
  }

  final ComicListScene? initialScene;
  final String? sceneSource;
  final String? sceneBundleFnPath;
  final String? sceneBundleFnPathFallback;
  final bool suppressNeedLoginEvent;

  void _init() {
    final currentFrom = initialScene?.from ?? (sceneSource ?? '').trim();
    emit(state.copyWith(currentFrom: currentFrom));

    if (currentFrom.isEmpty) {
      return;
    }

    if (initialScene != null) {
      emit(state.copyWith(scene: initialScene));
      _onSceneAvailable(currentFrom);
      return;
    }

    _loadScene(currentFrom);
  }

  Future<void> reload() async {
    final from = state.currentFrom;
    emit(ComicListState(currentFrom: from));

    if (from.isEmpty) {
      return;
    }

    if (initialScene != null) {
      emit(state.copyWith(scene: initialScene));
      _onSceneAvailable(from);
      return;
    }

    await _loadScene(from);
  }

  Future<void> _loadScene(String from) async {
    if (state.sceneLoading) {
      return;
    }

    emit(
      state.copyWith(
        sceneLoading: true,
        sceneError: null,
        sceneLoginPluginId: '',
      ),
    );

    try {
      final sceneFnPath = sceneBundleFnPath?.trim().isNotEmpty == true
          ? sceneBundleFnPath!.trim()
          : 'getComicListSceneBundle';

      Map<String, dynamic> response;
      try {
        response = await callUnifiedComicPlugin(
          from: from,
          fnPath: sceneFnPath,
          core: const <String, dynamic>{},
          extern: const <String, dynamic>{},
          suppressNeedLoginEvent: suppressNeedLoginEvent,
        );
      } catch (_) {
        final fallback = sceneBundleFnPathFallback?.trim() ?? '';
        if (fallback.isEmpty || fallback == sceneFnPath) {
          rethrow;
        }
        response = await callUnifiedComicPlugin(
          from: from,
          fnPath: fallback,
          core: const <String, dynamic>{},
          suppressNeedLoginEvent: suppressNeedLoginEvent,
        );
      }

      final envelope = UnifiedPluginEnvelope.fromMap(response);
      final sceneMap = asJsonMap(envelope.data['scene']);
      final loadedScene = ComicListScene.fromMap(
        sceneMap.isNotEmpty ? sceneMap : envelope.data,
      );

      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          scene: loadedScene,
          sceneLoading: false,
          sceneError: null,
          sceneLoginPluginId: '',
        ),
      );
    } catch (e) {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          sceneError: normalizeSearchErrorMessage(e),
          sceneLoading: false,
          sceneLoginPluginId: _loginPluginId(e, from),
        ),
      );
    }
  }

  void _onSceneAvailable(String from) {
    final validationError = _validateScene(state.scene);
    if (validationError != null) {
      emit(state.copyWith(sceneError: validationError));
      return;
    }

    if (state.requiresFilter &&
        !state.hasResolvedFilter &&
        !state.filterLoading) {
      _loadFilter(from);
    }
  }

  String? _validateScene(ComicListScene? scene) {
    final request = scene?.body.request;
    if (request == null) {
      return t.comicList.missingListConfig;
    }
    if (request.fnPath.trim().isEmpty) {
      return t.comicList.missingFnPath;
    }
    return null;
  }

  Future<void> loadFilter() async {
    if (state.currentFrom.isEmpty) {
      return;
    }
    await _loadFilter(state.currentFrom);
  }

  Future<void> _loadFilter(String from) async {
    final filterRequest = state.scene?.filter;
    if (filterRequest == null || state.filterLoading) {
      return;
    }

    emit(
      state.copyWith(
        filterLoading: true,
        filterError: null,
        filterLoginPluginId: '',
      ),
    );

    try {
      final response = await callUnifiedComicPlugin(
        from: from,
        fnPath: filterRequest.fnPath,
        core: filterRequest.core,
        extern: filterRequest.extern,
        suppressNeedLoginEvent: suppressNeedLoginEvent,
      );
      final envelope = UnifiedPluginEnvelope.fromMap(response);
      final bundle = _parseFilterBundle(envelope);

      if (isClosed) {
        return;
      }

      _applyFilterBundle(bundle, state.filterSelections);
    } catch (e) {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          filterError: normalizeSearchErrorMessage(e),
          filterLoading: false,
          filterLoginPluginId: _loginPluginId(e, from),
        ),
      );
    }
  }

  void applyFilterSelections(Map<String, String> selections) {
    final bundle = state.filterBundle;
    if (bundle == null) {
      return;
    }
    _applyFilterBundle(bundle, selections);
  }

  void _applyFilterBundle(
    ListFilterBundle bundle,
    Map<String, String> selections,
  ) {
    final resolved = bundle.scheme.resolve(
      requestedSelections: selections,
      defaultSelections: bundle.defaultSelections,
    );

    emit(
      state.copyWith(
        filterBundle: bundle,
        filterSelections: resolved.selections,
        resolvedUiParams: resolved.params,
        resolvedFilterCore: resolved.core,
        resolvedFilterExtern: resolved.extern,
        filterLoading: false,
        filterError: null,
        filterLoginPluginId: '',
      ),
    );
  }

  /// 登录错误取插件身份（只认 callUnifiedComicPlugin 抛的类型化错误，
  /// 不做二次文本解析），非登录错误返回空。错误文案由调用方透传。
  String _loginPluginId(Object e, String from) {
    if (e is PluginUnauthorizedException) {
      final id = e.pluginId.trim();
      return id.isNotEmpty ? id : from;
    }
    return '';
  }

  ListFilterBundle _parseFilterBundle(UnifiedPluginEnvelope envelope) {
    final values = asJsonMap(envelope.data['values']);
    final defaults = <String, String>{};
    values.forEach((key, value) {
      defaults[key] = value?.toString() ?? '';
    });

    return ListFilterBundle(
      scheme: PluginListFilterSchema.fromMap(envelope.scheme),
      defaultSelections: defaults,
    );
  }
}
