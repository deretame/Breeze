import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/network/http/http_request.dart';

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
    emit(
      state.copyWith(
        status: ComicListStatus.initial,
      ),
    );

    try {
      var temp = await getRankingList(
        days: event.getInfo.days,
        type: event.getInfo.type,
      );

      var result = Leaderboard.fromJson(temp);

      // 获取所有被屏蔽的分类
      List<String> shieldedCategoriesList =
          bikaSetting.shieldCategoryMap.entries
              .where((entry) => entry.value) // 只选择值为 true 的条目
              .map((entry) => entry.key) // 提取键（分类名）
              .toList();

      // 过滤掉包含屏蔽分类的漫画
      var temp1 = result.data.comics.where((comic) {
        // 检查该漫画的分类是否与屏蔽分类列表中的任何分类匹配
        return !comic.categories
            .any((category) => shieldedCategoriesList.contains(category));
      }).toList();

      emit(
        state.copyWith(
          status: ComicListStatus.success,
          comicList: temp1,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ComicListStatus.failure,
          result: e.toString(),
        ),
      );
    }
  }
}
