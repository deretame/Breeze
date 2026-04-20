import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:worker_manager/worker_manager.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/page/search_result/method/get_plugin_result.dart';
import 'package:zephyr/page/search_result/models/bloc_state.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/sundry.dart';

import '../models/models.dart';

part 'search_bloc.freezed.dart';
part 'search_bloc.g.dart';
part 'search_event.dart';
part 'search_state.dart';

const throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

Map<String, dynamic> _asWorkerMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const <String, dynamic>{};
}

String _normalizeMaskedText(String text) {
  final lower = text.toLowerCase();
  try {
    return t2s(lower);
  } catch (_) {
    return lower;
  }
}

Future<List<Map<String, dynamic>>> _filterShieldedComicJsonList(
  Map<String, dynamic> payload,
) async {
  final comics = ((payload['comics'] as List?) ?? const <dynamic>[])
      .whereType<Map>()
      .map((entry) => _asWorkerMap(entry))
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
  for (final entry in comics) {
    final comic = _asWorkerMap(entry['comic']);
    final metadata = ((comic['metadata'] as List?) ?? const <dynamic>[])
        .whereType<Map>()
        .map((item) => _asWorkerMap(item))
        .toList();

    final metadataNames = StringBuffer();
    final metadataValues = StringBuffer();
    final categories = <String>[];
    final tags = <String>[];

    for (final meta in metadata) {
      metadataNames.write(meta['name']?.toString() ?? '');
      final type = meta['type']?.toString() ?? '';
      final values = ((meta['value'] as List?) ?? const <dynamic>[])
          .map((item) {
            if (item is Map) {
              return item['name']?.toString() ?? '';
            }
            return item.toString();
          })
          .where((item) => item.isNotEmpty)
          .toList();
      metadataValues.write(values.join());
      if (type == 'categories') {
        categories.addAll(values);
      } else if (type == 'tags') {
        tags.addAll(values);
      }
    }

    final allText = _normalizeMaskedText(
      [
        comic['title']?.toString() ?? '',
        comic['subtitle']?.toString() ?? '',
        metadataNames.toString(),
        metadataValues.toString(),
        categories.join(),
        tags.join(),
      ].join(),
    );

    final blocked = maskedKeywords.any(allText.contains);
    if (!blocked) {
      visible.add(entry);
    }
  }
  return visible;
}

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc() : super(SearchState()) {
    on<SearchEvent>(
      _fetchComicList,
      transformer: throttleDroppable(throttleDuration),
    );
  }

  var blocState = BlocState();

  Future<void> _fetchComicList(
    SearchEvent event,
    Emitter<SearchState> emit,
  ) async {
    if (event.status == SearchStatus.initial) {
      blocState = BlocState();
      emit(state.copyWith(status: SearchStatus.initial));
    }

    if (blocState.hasReachedMax) return;

    if (event.status == SearchStatus.loadingMore) {
      emit(
        state.copyWith(
          status: SearchStatus.loadingMore,
          comics: blocState.visibleComics,
          hasReachedMax: blocState.hasReachedMax,
          searchEvent: event,
        ),
      );
    }

    try {
      final previousRawCount = blocState.comics.length;
      blocState = await getPluginSearchResult(event, blocState);
      final (maskedKeywords, fingerprint) = _loadMaskedKeywords();

      if (fingerprint != blocState.maskedKeywordsFingerprint) {
        blocState.visibleComics = await _filterShieldedComicsByWorker(
          blocState.comics,
          maskedKeywords,
        );
        blocState.maskedKeywordsFingerprint = fingerprint;
      } else {
        final appended = blocState.comics.skip(previousRawCount).toList();
        final filteredAppended = await _filterShieldedComicsByWorker(
          appended,
          maskedKeywords,
        );
        if (filteredAppended.isNotEmpty) {
          blocState.visibleComics = [
            ...blocState.visibleComics,
            ...filteredAppended,
          ];
        }
      }

      emit(
        state.copyWith(
          status: SearchStatus.success,
          comics: blocState.visibleComics,
          hasReachedMax: blocState.hasReachedMax,
          searchEvent: event.copyWith(
            page: blocState.pagesCount,
            searchStates: event.searchStates.copyWith(
              pluginExtern: blocState.pluginExtern,
            ),
          ),
        ),
      );
    } catch (e, s) {
      logger.e(e, stackTrace: s);
      if (blocState.comics.isNotEmpty) {
        emit(
          state.copyWith(
            status: SearchStatus.getMoreFailure,
            comics: blocState.visibleComics,
            searchEvent: event,
            result: e.toString(),
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: SearchStatus.failure,
          searchEvent: event,
          result: e.toString(),
        ),
      );
    }
  }

  (List<String>, String) _loadMaskedKeywords() {
    final settings = objectbox.userSettingBox.get(1)!.globalSetting;
    final maskedKeywords = settings.maskedKeywords
        .where((keyword) => keyword.trim().isNotEmpty)
        .map((keyword) => _normalizeMaskedText(keyword.trim()))
        .where((keyword) => keyword.isNotEmpty)
        .toSet()
        .toList();
    maskedKeywords.sort();
    return (maskedKeywords, maskedKeywords.join('\u0001'));
  }

  List<ComicNumber> _filterShieldedComicsFallback(
    List<ComicNumber> comics,
    List<String> maskedKeywords,
  ) {
    if (comics.isEmpty || maskedKeywords.isEmpty) {
      return comics;
    }
    return comics.where((comic) {
      final data = comic.comic;
      final categories = data.metadataValues('categories');
      final tags = data.metadataValues('tags');

      final allText = [
        data.title,
        data.subtitle,
        data.metadata.map((item) => item.name).join(),
        data.metadata.expand((item) => item.value).join(),
        categories.join(),
        tags.join(),
      ].join().toLowerCase().let(t2s);

      final containsKeyword = maskedKeywords.any(allText.contains);

      return !containsKeyword;
    }).toList();
  }

  Future<List<ComicNumber>> _filterShieldedComicsByWorker(
    List<ComicNumber> comics,
    List<String> maskedKeywords,
  ) async {
    if (comics.isEmpty || maskedKeywords.isEmpty) {
      return comics;
    }

    final payload = <String, dynamic>{
      'comics': comics.map((item) => item.toJson()).toList(),
      'maskedKeywords': maskedKeywords,
    };

    try {
      final filtered = await workerManager.execute<List<Map<String, dynamic>>>(
        () => _filterShieldedComicJsonList(payload),
      );
      return filtered.map(ComicNumber.fromJson).toList();
    } catch (e, s) {
      logger.w('search shield filter fallback to main isolate', error: e);
      logger.d(s);
      return _filterShieldedComicsFallback(comics, maskedKeywords);
    }
  }
}
