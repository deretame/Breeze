import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/page/search_result/method/get_bika_result.dart';
import 'package:zephyr/page/search_result/method/get_jm_result.dart';
import 'package:zephyr/page/search_result/models/bloc_state.dart';
import 'package:zephyr/type/enum.dart';

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

      emit(
        state.copyWith(
          status: SearchStatus.success,
          comics: _filterShieldedComics(blocState.comics),
          hasReachedMax: blocState.hasReachedMax,
          searchEvent: event,
        ),
      );
    } catch (e) {
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
    // // 获取有效屏蔽关键词（非空）
    // final maskedKeywords = SettingsHiveUtils.maskedKeywords
    //     .where((keyword) => keyword.trim().isNotEmpty)
    //     .toList();

    // // 获取屏蔽分类
    // final shieldedCategories = SettingsHiveUtils.bikaShieldCategoryMap.entries
    //     .where((entry) => entry.value)
    //     .map((entry) => entry.key)
    //     .toList();

    // return comics.where((comic) {
    //   // 1. 检查屏蔽分类
    //   final hasShieldedCategory = comic.doc.categories.any(
    //     (category) => shieldedCategories.contains(category),
    //   );
    //   if (hasShieldedCategory) return false;

    //   // 2. 检查屏蔽关键词
    //   final allText = [
    //     comic.doc.title,
    //     comic.doc.author,
    //     comic.doc.chineseTeam,
    //     comic.doc.categories.join(),
    //     comic.doc.tags.join(),
    //     comic.doc.description,
    //   ].join().toLowerCase().let(t2s);

    //   final containsKeyword = maskedKeywords.any(
    //     (keyword) => allText.contains(keyword.toLowerCase().let(t2s)),
    //   );

    //   return !containsKeyword;
    // }).toList();
    return comics;
  }
}
