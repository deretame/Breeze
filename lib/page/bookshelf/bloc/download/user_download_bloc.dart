import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart';
import 'package:zephyr/util/settings_hive_utils.dart';

import '../../../../main.dart';
import '../../../../object_box/model.dart';

part 'user_download_event.dart';
part 'user_download_state.dart';

const _throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> _throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class UserDownloadBloc extends Bloc<UserDownloadEvent, UserDownloadState> {
  UserDownloadBloc() : super(UserDownloadState()) {
    on<UserDownloadEvent>(
      _fetchComicList,
      transformer: _throttleDroppable(_throttleDuration),
    );
  }

  bool initial = true;

  Future<void> _fetchComicList(
    UserDownloadEvent event,
    Emitter<UserDownloadState> emit,
  ) async {
    if (state.searchEnterConst == event.searchEnterConst && initial == false) {
      return; // 如果状态相同，直接返回，避免再次请求
    }

    if (initial) {
      emit(
        state.copyWith(
          status: UserDownloadStatus.initial,
          comics: [],
          searchEnterConst: event.searchEnterConst,
        ),
      );
    }
    try {
      final comicList = _getComicList(event);

      // emit 状态更新
      emit(
        state.copyWith(
          status: UserDownloadStatus.success,
          comics: comicList,
          searchEnterConst: event.searchEnterConst,
        ),
      );
      initial = false;
    } catch (e) {
      emit(
        state.copyWith(
          status: UserDownloadStatus.failure,
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

  List<JmDownload> _fetchOfSortJm(List<JmDownload> comicList, String sort) {
    if (sort == "dd") {
      comicList.sort((a, b) => b.downloadTime.compareTo(a.downloadTime));
    }
    if (sort == "da") {
      comicList.sort((a, b) => a.downloadTime.compareTo(b.downloadTime));
    }
    if (sort == "ld") {
      comicList.sort((a, b) => b.likes.compareTo(a.likes));
    }
    if (sort == "vd") {
      comicList.sort((a, b) => b.totalViews.compareTo(a.totalViews));
    }
    return comicList;
  }

  List<BikaComicDownload> _filterShieldedComics(
    List<BikaComicDownload> comics,
  ) {
    // 获取所有被屏蔽的分类
    List<String> shieldedCategoriesList = SettingsHiveUtils
        .bikaShieldCategoryMap
        .entries
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

  List<dynamic> _getComicList(UserDownloadEvent event) {
    List<dynamic> comics = [];
    if (SettingsHiveUtils.comicChoice == 1) {
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

      comics = comicList;
    } else if (SettingsHiveUtils.comicChoice == 2) {
      late var comicList = objectbox.jmDownloadBox.getAll();

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

      comics = comicList;
    }
    return comics;
  }
}
