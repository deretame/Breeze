import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../../main.dart';
import '../../../object_box/model.dart';
import '../models/search_enter.dart';

part 'download_list_event.dart';
part 'download_list_state.dart';

const throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class DownloadListBloc extends Bloc<DownloadListEvent, DownloadListState> {
  DownloadListBloc() : super(DownloadListState()) {
    on<DownloadListEvent>(
      _fetchComicList,
      transformer: throttleDroppable(throttleDuration),
    );
  }

  bool initial = true;

  Future<void> _fetchComicList(
    DownloadListEvent event,
    Emitter<DownloadListState> emit,
  ) async {
    if (state.searchEnterConst == event.searchEnterConst && initial == false) {
      return; // 如果状态相同，直接返回，避免再次请求
    }

    if (initial) {
      emit(
        state.copyWith(
          status: DownloadListStatus.initial,
          comics: [],
          searchEnterConst: event.searchEnterConst,
        ),
      );
    }
    try {
      late var comicList = objectbox.bikaDownloadBox.getAll();

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

        comicList = comicList
            .where((comic) =>
                comic.title.toLowerCase().contains(keyword) ||
                comic.categoriesString.toLowerCase().contains(keyword) ||
                comic.description.toLowerCase().contains(keyword) ||
                comic.tagsString.toLowerCase().contains(keyword))
            .toList();
      }

      // emit 状态更新
      emit(
        state.copyWith(
          status: DownloadListStatus.success,
          comics: comicList,
          searchEnterConst: event.searchEnterConst,
        ),
      );
      initial = false;
    } catch (e) {
      emit(
        state.copyWith(
          status: DownloadListStatus.failure,
          result: e.toString(),
          searchEnterConst: event.searchEnterConst,
        ),
      );
    }
  }

  List<BikaComicDownload> _fetchOfSort(
    List<BikaComicDownload> comicList,
    String sort,
  ) {
    if (sort == "dd") {
      comicList.sort((a, b) => b.downloadTime.compareTo(a.downloadTime));
    }
    if (sort == "da") {
      comicList.sort((a, b) => a.downloadTime.compareTo(b.downloadTime));
    }
    if (sort == "ld") {
      comicList.sort((a, b) => b.likesCount.compareTo(a.likesCount));
    }
    if (sort == "vd") {
      comicList.sort((a, b) => b.viewsCount.compareTo(a.viewsCount));
    }
    return comicList;
  }

  List<BikaComicDownload> _filterShieldedComics(
      List<BikaComicDownload> comics) {
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
