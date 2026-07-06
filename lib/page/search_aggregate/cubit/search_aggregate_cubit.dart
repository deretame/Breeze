import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:worker_manager/worker_manager.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/widgets/comic_entry/models/models.dart';
import 'package:zephyr/page/search_result/bloc/search_bloc.dart';
import 'package:zephyr/page/search_result/method/get_plugin_result.dart';
import 'package:zephyr/page/search_result/models/bloc_state.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/error_filter.dart';
import 'package:zephyr/util/rust_loader.dart';
import 'package:zephyr/util/sundry.dart';

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
  int _searchVersion = 0;

  Future<void> search() async {
    final int searchVersion = ++_searchVersion;
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
    var completed = 0;

    await Future.wait(
      selected.map((pluginId) async {
        try {
          final result = await _searchSingleSource(pluginId);
          if (!_isSearchActive(searchVersion)) {
            return;
          }
          nextResults[pluginId] = result;
          nextErrors.remove(pluginId);
        } catch (error) {
          if (!_isSearchActive(searchVersion)) {
            return;
          }
          nextErrors[pluginId] = normalizeSearchErrorMessage(error);
          nextResults[pluginId] = const <dynamic>[];
        } finally {
          if (_isSearchActive(searchVersion)) {
            completed++;
            final allDone = completed >= selected.length;
            emit(
              state.copyWith(
                status: allDone
                    ? AggregateSearchStatus.success
                    : AggregateSearchStatus.loading,
                results: Map<String, List<dynamic>>.from(nextResults),
                errors: Map<String, String>.from(nextErrors),
              ),
            );
          }
        }
      }),
    );
  }

  bool _isSearchActive(int searchVersion) {
    return !isClosed && searchVersion == _searchVersion;
  }

  Future<void> toggleSource(String pluginId, bool enabled) async {
    final next = Map<String, bool>.from(state.selectedSources);
    next[pluginId] = enabled;
    emit(state.copyWith(selectedSources: next));
    await search();
  }

  Future<void> refreshSource(String pluginId) async {
    if (pluginId.isEmpty || !(state.selectedSources[pluginId] ?? false)) {
      return;
    }

    final refreshing = Set<String>.from(state.refreshingSources)..add(pluginId);
    emit(state.copyWith(refreshingSources: refreshing));

    final nextResults = Map<String, List<dynamic>>.from(state.results);
    final nextErrors = Map<String, String>.from(state.errors);
    try {
      nextResults[pluginId] = await _searchSingleSource(pluginId);
      nextErrors.remove(pluginId);
    } catch (error) {
      nextResults[pluginId] = const <dynamic>[];
      nextErrors[pluginId] = normalizeSearchErrorMessage(error);
    } finally {
      refreshing.remove(pluginId);
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
      searchStates: baseEvent.searchStates.copyWith(from: pluginId),
    );
    final result = await getPluginSearchResult(event, BlocState());
    final comics = result.comics.map((e) => e.comic).toList();
    final maskedKeywords = objectbox.userSettingBox
        .get(1)!
        .globalSetting
        .maskedKeywords
        .where((keyword) => keyword.trim().isNotEmpty)
        .map((keyword) => keyword.trim().toLowerCase().let(t2s))
        .where((keyword) => keyword.isNotEmpty)
        .toList();

    if (maskedKeywords.isEmpty) {
      return comics;
    }

    final payload = <String, dynamic>{
      'comics': comics.map((c) => c.toJson()).toList(),
      'maskedKeywords': maskedKeywords,
    };

    try {
      final filtered = await workerManager.execute<List<Map<String, dynamic>>>(
        () => _filterAggregateComics(payload),
      );
      return filtered
          .map((json) => UnifiedComicListItem.fromJson(json))
          .toList();
    } catch (_) {
      return comics.where((comic) {
        final allText = [
          comic.title,
          comic.subtitle,
          comic.metadata.expand((item) => item.value).join(),
        ].join().toLowerCase().let(t2s);
        return !maskedKeywords.any(allText.contains);
      }).toList();
    }
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

Future<List<Map<String, dynamic>>> _filterAggregateComics(
  Map<String, dynamic> payload,
) async {
  await initRustLib(silent: true);
  final comics = ((payload['comics'] as List?) ?? const <dynamic>[])
      .whereType<Map>()
      .map((entry) => _asWorkerMapF(entry))
      .toList();
  final maskedKeywords =
      ((payload['maskedKeywords'] as List?) ?? const <dynamic>[])
          .map((entry) => entry.toString().trim())
          .where((entry) => entry.isNotEmpty)
          .toList();

  if (comics.isEmpty || maskedKeywords.isEmpty) {
    return comics;
  }

  final visible = <Map<String, dynamic>>[];
  for (final comic in comics) {
    final metadata = ((comic['metadata'] as List?) ?? const <dynamic>[])
        .whereType<Map>()
        .map((item) => _asWorkerMapF(item))
        .toList();

    final valueNames = <String>[];
    for (final meta in metadata) {
      final values = (meta['value'] as List?) ?? const <dynamic>[];
      for (final val in values) {
        if (val is Map) {
          final name = val['name']?.toString() ?? '';
          if (name.isNotEmpty) {
            valueNames.add(name);
          }
        } else {
          final name = val.toString().trim();
          if (name.isNotEmpty) {
            valueNames.add(name);
          }
        }
      }
    }

    final allText = _normalizeMaskedTextF(
      [
        comic['title']?.toString() ?? '',
        comic['subtitle']?.toString() ?? '',
        valueNames.join(),
      ].join(),
    );

    final blocked = maskedKeywords.any(allText.contains);
    if (!blocked) {
      visible.add(comic);
    }
  }
  return visible;
}

Map<String, dynamic> _asWorkerMapF(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const <String, dynamic>{};
}

String _normalizeMaskedTextF(String text) {
  final lower = text.toLowerCase();
  try {
    return t2s(lower);
  } catch (_) {
    return lower;
  }
}
