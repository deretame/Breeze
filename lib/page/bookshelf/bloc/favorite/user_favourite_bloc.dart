import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/network/http/bika/http_request.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart';
import 'package:zephyr/page/bookshelf/json/favorite/favourite_json.dart';

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
      var temp = await getFavorites(event.pageCount);
      var result = FavouriteJson.fromJson(temp);

      pageCont = result.data.comics.total ~/ 20 + 1;

      if (result.data.comics.page >= pageCont) {
        hasReachedMax = true;
      }

      for (var comic in result.data.comics.docs) {
        comics.add(
          ComicNumber(buildNumber: result.data.comics.page, doc: comic),
        );
      }

      emit(
        state.copyWith(
          status: UserFavouriteStatus.success,
          comics: _filterShieldedComics(comics),
          hasReachedMax: hasReachedMax,
          refresh: event.refresh,
          pageCount: event.pageCount,
          pagesCount: result.data.comics.pages,
        ),
      );
      initial = false;
      totalPages = result.data.comics.pages;
    } catch (e) {
      logger.d(e);
      if (comics.isNotEmpty) {
        emit(
          state.copyWith(
            status: UserFavouriteStatus.getMoreFailure,
            comics: _filterShieldedComics(comics),
            hasReachedMax: hasReachedMax,
            refresh: event.refresh,
            pageCount: event.pageCount,
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
      if (!seenIds.contains(comic.doc.id)) {
        uniqueComics.add(comic);
        seenIds.add(comic.doc.id);
      }
    }

    return uniqueComics;
  }

  List<ComicNumber> _filterShieldedComics(List<ComicNumber> comics) {
    // 获取所有被屏蔽的分类
    List<String> shieldedCategoriesList =
        bikaSetting.shieldCategoryMap.entries
            .where((entry) => entry.value) // 只选择值为 true 的条目
            .map((entry) => entry.key) // 提取键（分类名）
            .toList();

    // 过滤掉包含屏蔽分类的漫画
    return comics.where((comic) {
      // 检查该漫画的分类是否与屏蔽分类列表中的任何分类匹配
      return !comic.doc.categories.any(
        (category) => shieldedCategoriesList.contains(category),
      );
    }).toList();
  }
}
