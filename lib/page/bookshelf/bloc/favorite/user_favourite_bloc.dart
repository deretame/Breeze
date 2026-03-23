import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/model/unified_comic_list_item.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart';
import 'package:zephyr/type/enum.dart';

import '../../../../main.dart';

part 'user_favourite_event.dart';
part 'user_favourite_state.dart';

const _throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> _throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class UserFavouriteBloc extends Bloc<UserFavouriteEvent, UserFavouriteState> {
  UserFavouriteBloc() : super(UserFavouriteState()) {
    on<UserFavouriteEvent>(
      _fetchComicList,
      transformer: _throttleDroppable(_throttleDuration),
    );
  }

  bool initial = true;
  bool hasReachedMax = false;
  List<ComicNumber> comics = [];

  // 这个的作用是用来记录收藏页面实际上有几页
  int pageCont = 0;
  int totalPages = 0;

  Future<void> _fetchComicList(
    UserFavouriteEvent event,
    Emitter<UserFavouriteState> emit,
  ) async {
    if (event.refresh == "updateShield") {
      emit(
        state.copyWith(
          status: UserFavouriteStatus.success,
          comics: _filterShieldedComics(comics),
          hasReachedMax: hasReachedMax,
          refresh: "",
          pageCount: event.pageCount,
          pagesCount: totalPages,
        ),
      );
    }

    if (event.status == UserFavouriteStatus.initial) {
      comics = [];
      emit(
        state.copyWith(
          status: UserFavouriteStatus.initial,
          refresh: event.refresh,
        ),
      );

      hasReachedMax = false;
    }

    if (hasReachedMax == true) {
      return;
    }

    if (event.status == UserFavouriteStatus.loadingMore) {
      emit(
        state.copyWith(
          status: UserFavouriteStatus.loadingMore,
          comics: _filterShieldedComics(comics),
          refresh: event.refresh,
          hasReachedMax: hasReachedMax,
          pageCount: event.pageCount,
          pagesCount: totalPages,
        ),
      );
    }

    try {
      final response = await callUnifiedComicPlugin(
        from: From.bika,
        fnPath: 'getFavoriteData',
        core: {'page': event.pageCount},
        extern: const {'source': 'favorite'},
      );
      final envelope = UnifiedPluginEnvelope.fromMap(response);
      final data = asMap(envelope.data);
      final paging = asMap(data['paging']);
      final items = asList(data['items'])
          .map((item) => UnifiedComicListItem.fromJson(asMap(item)))
          .toList();

      pageCont = (paging['pages'] as num?)?.toInt() ?? 1;
      hasReachedMax = paging['hasReachedMax'] == true;

      for (var comic in items) {
        comics.add(
          ComicNumber(
            buildNumber: (paging['page'] as num?)?.toInt() ?? event.pageCount,
            doc: comic,
          ),
        );
      }

      emit(
        state.copyWith(
          status: UserFavouriteStatus.success,
          comics: _filterShieldedComics(comics),
          hasReachedMax: hasReachedMax,
          refresh: event.refresh,
          pageCount: event.pageCount,
          pagesCount: pageCont,
        ),
      );
      initial = false;
      totalPages = pageCont;
    } catch (e, s) {
      logger.e(e, stackTrace: s);
      if (comics.isNotEmpty) {
        emit(
          state.copyWith(
            status: UserFavouriteStatus.getMoreFailure,
            comics: _filterShieldedComics(comics),
            hasReachedMax: hasReachedMax,
            refresh: event.refresh,
            result: e.toString(),
            pagesCount: totalPages,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: UserFavouriteStatus.failure,
          refresh: event.refresh,
          result: e.toString(),
        ),
      );
    }
  }

  List<ComicNumber> deduplicateComics(List<ComicNumber> comics) {
    Set<String> seenIds = {};
    List<ComicNumber> uniqueComics = [];

    for (var comic in comics) {
      final id = comic.doc.id;
      if (!seenIds.contains(id)) {
        uniqueComics.add(comic);
        seenIds.add(id);
      }
    }

    return uniqueComics;
  }

  List<ComicNumber> _filterShieldedComics(List<ComicNumber> comics) {
    final settings = objectbox.userSettingBox.get(1)!.bikaSetting;
    // 获取所有被屏蔽的分类
    List<String> shieldedCategoriesList = settings.shieldCategoryMap.entries
        .where((entry) => entry.value) // 只选择值为 true 的条目
        .map((entry) => entry.key) // 提取键（分类名）
        .toList();

    // 过滤掉包含屏蔽分类的漫画
    return comics.where((comic) {
      // 检查该漫画的分类是否与屏蔽分类列表中的任何分类匹配
      final categories = comic.doc.metadataValues('categories');
      return !categories.any(
        (category) => shieldedCategoriesList.contains(category),
      );
    }).toList();
  }
}
