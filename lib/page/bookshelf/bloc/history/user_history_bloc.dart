import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart';

import '../../../../main.dart';
import '../../../../object_box/model.dart';

part 'user_history_event.dart';
part 'user_history_state.dart';

const _throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> _throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class UserHistoryBloc extends Bloc<UserHistoryEvent, UserHistoryState> {
  UserHistoryBloc() : super(UserHistoryState()) {
    on<UserHistoryEvent>(
      _fetchComicList,
      transformer: _throttleDroppable(_throttleDuration),
    );
  }

  bool initial = true;
  int totalComicCount = 0;

  Future<void> _fetchComicList(
    UserHistoryEvent event,
    Emitter<UserHistoryState> emit,
  ) async {
    if (state.searchEnterConst == event.searchEnterConst && initial == false) {
      return; // 如果状态相同，直接返回，避免再次请求
    }

    if (initial) {
      emit(
        state.copyWith(
          status: UserHistoryStatus.initial,
          comics: [],
          searchEnterConst: event.searchEnterConst,
        ),
      );
    }

    try {
      emit(
        state.copyWith(
          status: UserHistoryStatus.success,
          comics: _getComicList(event),
          searchEnterConst: event.searchEnterConst,
          result: totalComicCount.toString(),
        ),
      );
      initial = false;
    } catch (e) {
      emit(
        state.copyWith(
          status: UserHistoryStatus.failure,
          result: e.toString(),
          searchEnterConst: event.searchEnterConst,
        ),
      );
    }
  }

  List<BikaComicHistory> _fetchOfSort(
    List<BikaComicHistory> comicList,
    String sort,
  ) {
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

  List<JmHistory> _fetchOfSortJm(List<JmHistory> comicList, String sort) {
    if (sort == "dd") {
      comicList.sort((a, b) => b.history.compareTo(a.history));
    }
    if (sort == "da") {
      comicList.sort((a, b) => a.history.compareTo(b.history));
    }
    if (sort == "ld") {
      comicList.sort((a, b) => b.likes.compareTo(a.likes));
    }
    if (sort == "vd") {
      comicList.sort((a, b) => b.totalViews.compareTo(a.totalViews));
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
      return !comic.categories.any(
        (category) => shieldedCategoriesList.contains(category),
      );
    }).toList();
  }

  List<dynamic> _getComicList(UserHistoryEvent event) {
    List<dynamic> comics = [];
    if (bookshelfStore.topBarStore.date == 1) {
      late var comicList = objectbox.bikaHistoryBox.getAll();

      totalComicCount = comicList.length;

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
        final keyword = event.searchEnterConst.keyword.toLowerCase();

        comicList = comicList.where((comic) {
          var allString =
              comic.title +
              comic.author +
              comic.chineseTeam +
              comic.categoriesString +
              comic.tagsString +
              comic.description +
              comic.creatorName;
          return allString.toLowerCase().contains(keyword);
        }).toList();
      }

      comicList.removeWhere((comic) => comic.deleted == true);

      comics = comicList;
    } else if (bookshelfStore.topBarStore.date == 2) {
      late var comicList = objectbox.jmHistoryBox.getAll();

      totalComicCount = comicList.length;

      comicList = _fetchOfSortJm(comicList, event.searchEnterConst.sort);

      if (event.searchEnterConst.keyword.isNotEmpty) {
        final keyword = event.searchEnterConst.keyword.toLowerCase();

        comicList = comicList.where((comic) {
          var allString =
              comic.comicId.toString() +
              comic.name +
              comic.description +
              comic.author.toString() +
              comic.tags.toString() +
              comic.works.toString() +
              comic.actors.toString();
          return allString.toLowerCase().contains(keyword);
        }).toList();
      }

      comicList.removeWhere((comic) => comic.deleted == true);

      comics = comicList;
    }
    return comics;
  }
}
