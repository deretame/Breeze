import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/search_result/bloc/search_bloc.dart';
import 'package:zephyr/page/search_result/method/get_plugin_result.dart';
import 'package:zephyr/page/search_result/models/bloc_state.dart';
import 'package:zephyr/util/download/qjs_download_runtime.dart';

enum AggregateSearchStatus { initial, loading, success, failure }

class AggregateSearchState {
  const AggregateSearchState({
    this.status = AggregateSearchStatus.initial,
    this.results = const <String, List<dynamic>>{},
    this.errors = const <String, String>{},
    this.selectedSources = const <String, bool>{},
    this.refreshingSources = const <String>{},
    this.showHasResults = true,
    this.showErrors = true,
  });

  final AggregateSearchStatus status;
  final Map<String, List<dynamic>> results;
  final Map<String, String> errors;
  final Map<String, bool> selectedSources;
  final Set<String> refreshingSources;
  final bool showHasResults;
  final bool showErrors;

  AggregateSearchState copyWith({
    AggregateSearchStatus? status,
    Map<String, List<dynamic>>? results,
    Map<String, String>? errors,
    Map<String, bool>? selectedSources,
    Set<String>? refreshingSources,
    bool? showHasResults,
    bool? showErrors,
  }) {
    return AggregateSearchState(
      status: status ?? this.status,
      results: results ?? this.results,
      errors: errors ?? this.errors,
      selectedSources: selectedSources ?? this.selectedSources,
      refreshingSources: refreshingSources ?? this.refreshingSources,
      showHasResults: showHasResults ?? this.showHasResults,
      showErrors: showErrors ?? this.showErrors,
    );
  }
}

class AggregateSearchCubit extends Cubit<AggregateSearchState> {
  AggregateSearchCubit(
    this.baseEvent, {
    Map<String, bool> initialSelectedSources = const <String, bool>{},
  }) : super(AggregateSearchState(selectedSources: initialSelectedSources));

  final SearchEvent baseEvent;

  Future<void> search() async {
    final selected = state.selectedSources.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    emit(
      state.copyWith(
        status: AggregateSearchStatus.loading,
        results: const <String, List<dynamic>>{},
        errors: const <String, String>{},
        refreshingSources: const <String>{},
      ),
    );

    if (selected.isEmpty) {
      emit(
        state.copyWith(
          status: AggregateSearchStatus.success,
          results: const <String, List<dynamic>>{},
          errors: const <String, String>{},
        ),
      );
      return;
    }

    final nextResults = <String, List<dynamic>>{};
    final nextErrors = <String, String>{};

    await Future.wait(
      selected.map((pluginId) async {
        final resolvedPluginId = normalizePluginId(pluginId);
        try {
          nextResults[resolvedPluginId] = await _searchSingleSource(
            resolvedPluginId,
          );
        } catch (error) {
          nextErrors[resolvedPluginId] = error.toString();
          nextResults[resolvedPluginId] = const <dynamic>[];
        }
      }),
    );

    emit(
      state.copyWith(
        status: nextResults.isEmpty && nextErrors.isNotEmpty
            ? AggregateSearchStatus.failure
            : AggregateSearchStatus.success,
        results: nextResults,
        errors: nextErrors,
      ),
    );
  }

  Future<void> toggleSource(String pluginId, bool enabled) async {
    final next = Map<String, bool>.from(state.selectedSources);
    next[pluginId] = enabled;
    emit(state.copyWith(selectedSources: next));
    await search();
  }

  Future<void> refreshSource(String pluginId) async {
    final resolvedPluginId = normalizePluginId(pluginId);
    if (resolvedPluginId.isEmpty ||
        !(state.selectedSources[resolvedPluginId] ?? false)) {
      return;
    }

    final refreshing = Set<String>.from(state.refreshingSources)
      ..add(resolvedPluginId);
    emit(state.copyWith(refreshingSources: refreshing));

    final nextResults = Map<String, List<dynamic>>.from(state.results);
    final nextErrors = Map<String, String>.from(state.errors);
    try {
      nextResults[resolvedPluginId] = await _searchSingleSource(
        resolvedPluginId,
      );
      nextErrors.remove(resolvedPluginId);
    } catch (error) {
      nextResults[resolvedPluginId] = const <dynamic>[];
      nextErrors[resolvedPluginId] = error.toString();
    } finally {
      refreshing.remove(resolvedPluginId);
    }

    emit(
      state.copyWith(
        status: AggregateSearchStatus.success,
        results: nextResults,
        errors: nextErrors,
        refreshingSources: refreshing,
      ),
    );
  }

  Future<List<dynamic>> _searchSingleSource(String pluginId) async {
    final event = baseEvent.copyWith(
      page: 1,
      searchStates: baseEvent.searchStates.copyWith(
        from: pluginId,
        pluginExtern: {
          ...baseEvent.searchStates.pluginExtern,
          '_pluginId': pluginId,
        },
      ),
    );
    final result = await getPluginSearchResult(event, BlocState());
    return result.comics.map((e) => e.comic).toList();
  }

  Future<void> applySelectedSources(Map<String, bool> selectedSources) async {
    emit(
      state.copyWith(selectedSources: Map<String, bool>.from(selectedSources)),
    );
    await search();
  }

  void toggleHasResults(bool value) {
    emit(state.copyWith(showHasResults: value));
  }

  void toggleShowErrors(bool value) {
    emit(state.copyWith(showErrors: value));
  }
}
