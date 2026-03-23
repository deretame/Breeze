import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/json/json_value.dart';
import 'package:zephyr/util/sundry.dart';

import '../../../../main.dart';
import '../../../../object_box/model.dart';
import '../../../../object_box/objectbox.g.dart';

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

  List<UnifiedComicDownload> _fetchOfSort(
    List<UnifiedComicDownload> comicList,
    String sort,
  ) {
    if (sort == "dd") {
      comicList.sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));
    }
    if (sort == "da") {
      comicList.sort((a, b) => a.downloadedAt.compareTo(b.downloadedAt));
    }
    if (sort == "ld") {
      comicList.sort((a, b) => b.totalLikes.compareTo(a.totalLikes));
    }
    if (sort == "vd") {
      comicList.sort((a, b) => b.totalViews.compareTo(a.totalViews));
    }
    return comicList;
  }

  List<UnifiedComicDownload> _filterShieldedComics(
    List<UnifiedComicDownload> comics,
  ) {
    final settings = objectbox.userSettingBox.get(1)!.bikaSetting;
    // 获取所有被屏蔽的分类
    List<String> shieldedCategoriesList = settings.shieldCategoryMap.entries
        .where((entry) => entry.value) // 只选择值为 true 的条目
        .map((entry) => entry.key) // 提取键（分类名）
        .toList();

    // 过滤掉包含屏蔽分类的漫画
    return comics.where((comic) {
      // 检查该漫画的分类是否与屏蔽分类列表中的任何分类匹配
      return !(comic.metadata ?? const <Map<String, dynamic>>[]).any((entry) {
        if (entry['type']?.toString() != 'categories') return false;
        final values = asJsonList(entry['value'])
            .map((e) => asJsonMap(e)['name']?.toString() ?? '')
            .toList();
        return values.any(shieldedCategoriesList.contains);
      });
    }).toList();
  }

  List<dynamic> _getComicList(UserDownloadEvent event) {
    List<dynamic> comics = [];
    if (event.comicChoice == 1) {
      late var comicList = objectbox.unifiedDownloadBox
          .query(UnifiedComicDownload_.source.equals('bika'))
          .build()
          .find();

      comicList = _filterShieldedComics(comicList);

      comicList = _fetchOfSort(comicList, event.searchEnterConst.sort);

      if (event.searchEnterConst.categories.isNotEmpty) {
        for (var category in event.searchEnterConst.categories) {
          comicList = comicList
              .where((comic) {
                final metadata = comic.metadata ?? const <Map<String, dynamic>>[];
                return metadata.any((entry) {
                  if (entry['type']?.toString() != 'categories') return false;
                  final values = asJsonList(entry['value'])
                      .map((e) => asJsonMap(e)['name']?.toString() ?? '')
                      .toList();
                  return values.contains(category);
                });
              })
              .toList();
        }
      }

      if (event.searchEnterConst.keyword.isNotEmpty) {
        final keyword = event.searchEnterConst.keyword.toLowerCase().let(t2s);

        comicList = comicList.where((comic) {
          var allString =
              comic.title +
              comic.description +
              ((comic.creator ?? const <String, dynamic>{})['name']?.toString() ?? '') +
              comic.metadata.toString();
          return allString.toLowerCase().let(t2s).contains(keyword);
        }).toList();
      }

      comics = comicList;
    } else if (event.comicChoice == 2) {
      late var comicList = objectbox.unifiedDownloadBox
          .query(UnifiedComicDownload_.source.equals('jm'))
          .build()
          .find();

      comicList = _fetchOfSort(comicList, event.searchEnterConst.sort);

      if (event.searchEnterConst.keyword.isNotEmpty) {
        final keyword = event.searchEnterConst.keyword.toLowerCase().let(t2s);

        comicList = comicList.where((comic) {
          var allString =
              comic.comicId +
              comic.title +
              comic.description +
              comic.metadata.toString();
          return allString.toLowerCase().let(t2s).contains(keyword);
        }).toList();
      }

      comics = comicList;
    }
    return comics;
  }
}
