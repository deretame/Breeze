import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/page/search_result/method/get_bika_result.dart';
import 'package:zephyr/page/search_result/method/get_jm_result.dart';
import 'package:zephyr/page/search_result/models/bloc_state.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/settings_hive_utils.dart';
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
          comics: _filterShieldedComics(blocState.comics),
          hasReachedMax: blocState.hasReachedMax,
          searchEvent: event,
        ),
      );
    }

    try {
      if (event.searchStates.from == From.bika) {
        blocState = await getBikaResult(event, blocState);
      } else {
        blocState = await getJMResult(event, blocState);
      }

      logger.d(blocState.pagesCount);

      emit(
        state.copyWith(
          status: SearchStatus.success,
          comics: _filterShieldedComics(blocState.comics),
          hasReachedMax: blocState.hasReachedMax,
          searchEvent: event.copyWith(page: blocState.pagesCount),
        ),
      );
    } catch (e, s) {
      logger.e(e, stackTrace: s);
      if (blocState.comics.isNotEmpty) {
        emit(
          state.copyWith(
            status: SearchStatus.getMoreFailure,
            comics: _filterShieldedComics(blocState.comics),
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

  List<ComicNumber> _filterShieldedComics(List<ComicNumber> comics) {
    final maskedKeywords = SettingsHiveUtils.maskedKeywords
        .where((keyword) => keyword.trim().isNotEmpty)
        .toList();

    final shieldedCategories = SettingsHiveUtils.bikaShieldCategoryMap.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    return comics.where((comic) {
      return comic.comicInfo.when(
        bika: (bikaComic) {
          final hasShieldedCategory = bikaComic.categories.any(
            (category) => shieldedCategories.contains(category),
          );
          if (hasShieldedCategory) return false;

          final allText = [
            bikaComic.title,
            bikaComic.author,
            bikaComic.chineseTeam,
            bikaComic.categories.join(),
            bikaComic.tags.join(),
            bikaComic.description,
          ].join().toLowerCase().let(t2s);

          final containsKeyword = maskedKeywords.any(
            (keyword) => allText.contains(keyword.toLowerCase().let(t2s)),
          );

          return !containsKeyword;
        },
        jm: (jmComic) {
          final allText = [
            jmComic.name,
            jmComic.author,
            jmComic.category.title,
            jmComic.categorySub.title,
          ].join().toLowerCase().let(t2s);

          final containsKeyword = maskedKeywords.any(
            (keyword) => allText.contains(keyword.toLowerCase().let(t2s)),
          );

          return !containsKeyword;
        },
      );
    }).toList();
  }
}
