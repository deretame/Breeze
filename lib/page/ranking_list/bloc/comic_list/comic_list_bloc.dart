import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/network/http/bika/http_request.dart';

import '../../../../main.dart';
import '../../json/leaderboard.dart';
import '../../models/models.dart';

part 'comic_list_event.dart';

part 'comic_list_state.dart';

const throttleDurationComic = Duration(milliseconds: 100);

EventTransformer<E> throttleDroppableComic<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class ComicListBloc extends Bloc<FetchComicList, ComicListState> {
  ComicListBloc() : super(ComicListState()) {
    on<FetchComicList>(
      _fetchComicList,
      transformer: throttleDroppableComic(throttleDurationComic),
    );
  }

  Future<void> _fetchComicList(
    FetchComicList event,
    Emitter<ComicListState> emit,
  ) async {
    emit(state.copyWith(status: ComicListStatus.initial));

    try {
      var temp = await getRankingList(
        days: event.getInfo.days,
        type: event.getInfo.type,
      );

      // 获取有效屏蔽关键词（非空）
      final maskedKeywords =
          globalSetting.maskedKeywords
              .where((keyword) => keyword.trim().isNotEmpty)
              .toList();

      // 获取屏蔽分类
      final shieldedCategories =
          bikaSetting.shieldCategoryMap.entries
              .where((entry) => entry.value)
              .map((entry) => entry.key)
              .toList();

      List<Comic> result =
          Leaderboard.fromJson(temp).data.comics.where((comic) {
            // 1. 检查屏蔽分类
            final hasShieldedCategory = comic.categories.any(
              (category) => shieldedCategories.contains(category),
            );
            if (hasShieldedCategory) return false;

            // 2. 检查屏蔽关键词
            final allText =
                [
                  comic.title,
                  comic.author,
                  comic.categories.join(),
                ].join().toLowerCase();

            final containsKeyword = maskedKeywords.any(
              (keyword) => allText.contains(keyword.toLowerCase()),
            );

            return !containsKeyword;
          }).toList();

      emit(state.copyWith(status: ComicListStatus.success, comicList: result));
    } catch (e) {
      emit(
        state.copyWith(status: ComicListStatus.failure, result: e.toString()),
      );
    }
  }
}
