import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/page/comic_list/models/comic_list_scene.dart';
import 'package:zephyr/page/comic_list/models/list_filter_bundle.dart';
import 'package:zephyr/page/comic_list/scene_filter/plugin_list_filter_schema.dart';
import 'package:zephyr/util/error_filter.dart';
import 'package:zephyr/util/json/json_value.dart';

class ComicListState {
  const ComicListState({
    this.currentFrom = '',
    this.scene,
    this.sceneLoading = false,
    this.sceneError,
    this.filterLoading = false,
    this.filterError,
    this.filterBundle,
    this.filterSelections = const {},
    this.resolvedUiParams = const {},
    this.resolvedFilterCore = const {},
    this.resolvedFilterExtern = const {},
  });

  final String currentFrom;
  final ComicListScene? scene;
  final bool sceneLoading;
  final String? sceneError;
  final bool filterLoading;
  final String? filterError;
  final ListFilterBundle? filterBundle;
  final Map<String, String> filterSelections;
  final Map<String, dynamic> resolvedUiParams;
  final Map<String, dynamic> resolvedFilterCore;
  final Map<String, dynamic> resolvedFilterExtern;

  bool get requiresFilter => scene?.filter != null;
  bool get hasResolvedFilter => filterBundle != null;

  ComicListState copyWith({
    String? currentFrom,
    ComicListScene? scene,
    bool? sceneLoading,
    String? sceneError,
    bool? filterLoading,
    String? filterError,
    ListFilterBundle? filterBundle,
    Map<String, String>? filterSelections,
    Map<String, dynamic>? resolvedUiParams,
    Map<String, dynamic>? resolvedFilterCore,
    Map<String, dynamic>? resolvedFilterExtern,
  }) {
    return ComicListState(
      currentFrom: currentFrom ?? this.currentFrom,
      scene: scene ?? this.scene,
      sceneLoading: sceneLoading ?? this.sceneLoading,
      sceneError: sceneError,
      filterLoading: filterLoading ?? this.filterLoading,
      filterError: filterError,
      filterBundle: filterBundle ?? this.filterBundle,
      filterSelections: filterSelections ?? this.filterSelections,
      resolvedUiParams: resolvedUiParams ?? this.resolvedUiParams,
      resolvedFilterCore: resolvedFilterCore ?? this.resolvedFilterCore,
      resolvedFilterExtern: resolvedFilterExtern ?? this.resolvedFilterExtern,
    );
  }
}

class ComicListCubit extends Cubit<ComicListState> {
  ComicListCubit({
    this.initialScene,
    this.sceneSource,
    this.sceneBundleFnPath,
    this.sceneBundleFnPathFallback,
  }) : super(const ComicListState()) {
    _init();
  }

  final ComicListScene? initialScene;
  final String? sceneSource;
  final String? sceneBundleFnPath;
  final String? sceneBundleFnPathFallback;

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

    emit(state.copyWith(sceneLoading: true, sceneError: null));

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
          extern: const <String, dynamic>{},
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

      emit(state.copyWith(scene: loadedScene, sceneLoading: false));
      _onSceneAvailable(from);
    } catch (e) {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          sceneError: normalizeSearchErrorMessage(e),
          sceneLoading: false,
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

    emit(state.copyWith(filterLoading: true, filterError: null));

    try {
      final response = await callUnifiedComicPlugin(
        from: from,
        fnPath: filterRequest.fnPath,
        core: filterRequest.core,
        extern: filterRequest.extern,
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
      ),
    );
  }

  ListFilterBundle _parseFilterBundle(UnifiedPluginEnvelope envelope) {
    final values = asMap(envelope.data['values']);
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
