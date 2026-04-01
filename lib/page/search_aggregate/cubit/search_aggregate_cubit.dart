import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/plugin/plugin_constants.dart';
import 'package:zephyr/page/search_result/bloc/search_bloc.dart';
import 'package:zephyr/page/search_result/method/get_plugin_result.dart';
import 'package:zephyr/page/search_result/models/bloc_state.dart';

enum AggregateSearchStatus { initial, loading, success, failure }

class AggregateSearchState {
  const AggregateSearchState({
    this.status = AggregateSearchStatus.initial,
    this.results = const <String, List<dynamic>>{},
    this.errors = const <String, String>{},
    this.selectedSources = const <String, bool>{
      kJmPluginUuid: true,
      kBikaPluginUuid: true,
    },
    this.showHasResults = true,
    this.showErrors = true,
  });

  final AggregateSearchStatus status;
  final Map<String, List<dynamic>> results;
  final Map<String, String> errors;
  final Map<String, bool> selectedSources;
  final bool showHasResults;
  final bool showErrors;

  AggregateSearchState copyWith({
    AggregateSearchStatus? status,
    Map<String, List<dynamic>>? results,
    Map<String, String>? errors,
    Map<String, bool>? selectedSources,
    bool? showHasResults,
    bool? showErrors,
  }) {
    return AggregateSearchState(
      status: status ?? this.status,
      results: results ?? this.results,
      errors: errors ?? this.errors,
      selectedSources: selectedSources ?? this.selectedSources,
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
        try {
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
          nextResults[pluginId] = result.comics.map((e) => e.comic).toList();
        } catch (error) {
          nextErrors[pluginId] = error.toString();
          nextResults[pluginId] = const <dynamic>[];
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
