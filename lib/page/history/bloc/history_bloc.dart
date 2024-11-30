import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/page/history/models/search_enter.dart';

import '../../../main.dart';
import '../../../object_box/model.dart';

part 'history_event.dart';
part 'history_state.dart';

const throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  HistoryBloc() : super(HistoryState()) {
    on<HistoryEvent>(
      _fetchComicList,
      transformer: throttleDroppable(throttleDuration),
    );
  }

  bool initial = true;

  Future<void> _fetchComicList(
    HistoryEvent event,
    Emitter<HistoryState> emit,
  ) async {
    if (state.searchEnterConst == event.searchEnterConst && initial == false) {
      return; // 如果状态相同，直接返回，避免再次请求
    }

    emit(
      state.copyWith(
        status: HistoryStatus.initial,
        comics: [],
        searchEnterConst: event.searchEnterConst,
      ),
    );

    try {
      // 记录开始时间
      final startTime = DateTime.now();

      late var comicList = objectbox.bikaBox.getAll();

      comicList = _filterShieldedComics(comicList);

      comicList = _fetchOfSort(comicList, event.searchEnterConst.sort);

      if (event.searchEnterConst.categories.isNotEmpty) {
        for (var category in event.searchEnterConst.categories) {
          comicList = comicList
              .where((comic) => comic.categories.contains(category))
              .toList();
        }
      }

      if (event.searchEnterConst.keyword.isNotEmpty) {
        comicList = comicList
            .where((comic) =>
                comic.title.contains(event.searchEnterConst.keyword) ||
                comic.categoriesString
                    .contains(event.searchEnterConst.keyword) ||
                comic.description.contains(event.searchEnterConst.keyword) ||
                comic.tagsString.contains(event.searchEnterConst.keyword))
            .toList();
      }

      // 计算耗时
      final elapsedTime = DateTime.now().difference(startTime).inMilliseconds;

      // 计算需要额外延迟的时间
      final remainingDelay = 500 - elapsedTime;

      if (remainingDelay > 0) {
        await Future.delayed(Duration(milliseconds: remainingDelay));
      }

      // emit 状态更新
      emit(
        state.copyWith(
          status: HistoryStatus.success,
          comics: comicList,
          searchEnterConst: event.searchEnterConst,
        ),
      );
      initial = false;
    } catch (e) {
      emit(
        state.copyWith(
          status: HistoryStatus.failure,
          result: e.toString(),
          searchEnterConst: event.searchEnterConst,
        ),
      );
    }
  }

  List<BikaComicHistory> _fetchOfSort(
      List<BikaComicHistory> comicList, String sort) {
    if (sort == "dd") {
      comicList.sort((a, b) => b.history.compareTo(a.history));
    }
    if (sort == "da") {
      comicList.sort((a, b) => a.history.compareTo(b.history));
    }
    if (sort == "ld") {
      comicList.sort((a, b) => b.likesCount.compareTo(a.likesCount));
    }
    if (sort == "vd") {
      comicList.sort((a, b) => b.viewsCount.compareTo(a.viewsCount));
    }
    return comicList;
  }

  List<BikaComicHistory> _filterShieldedComics(List<BikaComicHistory> comics) {
    // 获取所有被屏蔽的分类
    List<String> shieldedCategoriesList = bikaSetting.shieldCategoryMap.entries
        .where((entry) => entry.value) // 只选择值为 true 的条目
        .map((entry) => entry.key) // 提取键（分类名）
        .toList();

    // 过滤掉包含屏蔽分类的漫画
    return comics.where((comic) {
      // 检查该漫画的分类是否与屏蔽分类列表中的任何分类匹配
      return !comic.categories
          .any((category) => shieldedCategoriesList.contains(category));
    }).toList();
  }
}
