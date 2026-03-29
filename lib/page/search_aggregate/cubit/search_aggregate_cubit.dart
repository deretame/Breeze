import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/search_result/bloc/search_bloc.dart';
import 'package:zephyr/page/search_result/method/get_plugin_result.dart';
import 'package:zephyr/page/search_result/models/bloc_state.dart';
import 'package:zephyr/type/enum.dart';

enum AggregateSearchStatus { initial, loading, success, failure }

class AggregateSearchState {
  const AggregateSearchState({
    this.status = AggregateSearchStatus.initial,
    this.results = const <From, List<dynamic>>{},
    this.errors = const <From, String>{},
    this.selectedSources = const <From, bool>{From.jm: true, From.bika: true},
    this.showHasResults = true,
    this.showErrors = true,
  });

  final AggregateSearchStatus status;
  final Map<From, List<dynamic>> results;
  final Map<From, String> errors;
  final Map<From, bool> selectedSources;
  final bool showHasResults;
  final bool showErrors;

  AggregateSearchState copyWith({
    AggregateSearchStatus? status,
    Map<From, List<dynamic>>? results,
    Map<From, String>? errors,
    Map<From, bool>? selectedSources,
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
    Map<String, bool> initialSelectedSources = const <String, bool>{
      'jm': true,
      'bika': true,
    },
  }) : super(
         AggregateSearchState(
           selectedSources: {
             From.jm: initialSelectedSources['jm'] ?? true,
             From.bika: initialSelectedSources['bika'] ?? true,
           },
         ),
       );

  final SearchEvent baseEvent;

  Future<void> search() async {
    final selected = state.selectedSources.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    emit(
      state.copyWith(
        status: AggregateSearchStatus.loading,
        results: const <From, List<dynamic>>{},
        errors: const <From, String>{},
      ),
    );

    if (selected.isEmpty) {
      emit(
        state.copyWith(
          status: AggregateSearchStatus.success,
          results: const <From, List<dynamic>>{},
          errors: const <From, String>{},
        ),
      );
      return;
    }

    final nextResults = <From, List<dynamic>>{};
    final nextErrors = <From, String>{};

    await Future.wait(
      selected.map((source) async {
        try {
          final event = baseEvent.copyWith(
            page: 1,
            searchStates: baseEvent.searchStates.copyWith(from: source),
          );
          final result = await getPluginSearchResult(event, BlocState());
          nextResults[source] = result.comics.map((e) => e.comic).toList();
        } catch (error) {
          nextErrors[source] = error.toString();
          nextResults[source] = const <dynamic>[];
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

  Future<void> toggleSource(From from, bool enabled) async {
    final next = Map<From, bool>.from(state.selectedSources);
    next[from] = enabled;
    emit(state.copyWith(selectedSources: next));
    await search();
  }

  Future<void> applySelectedSources(Map<From, bool> selectedSources) async {
    emit(
      state.copyWith(selectedSources: Map<From, bool>.from(selectedSources)),
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
