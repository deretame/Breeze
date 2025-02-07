import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/network/http/http_request.dart';
import 'package:zephyr/page/user_favourite/user_favourite.dart';

import '../../../main.dart';

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

  Future<void> _fetchComicList(
    UserFavouriteEvent event,
    Emitter<UserFavouriteState> emit,
  ) async {
    // 一样的话就直接返回，啥都不做
    if (event.refresh == state.refresh &&
        event.pageCount >= pageCont &&
        initial == false &&
        hasReachedMax) {
      return;
    }

    // 如果强制刷新状态不变那么就是加载更多漫画的意思
    if ((event.refresh == state.refresh || event.refresh == "addMore") &&
        initial == false) {
      emit(
        state.copyWith(
          status: UserFavouriteStatus.loadingMore,
          comics: comics,
          refresh: event.refresh,
        ),
      );
    } else {
      // 如果刷新状态改变，那么就重新加载漫画列表（因为首次的时候状态的refresh为空，所以首次传来一个不为空的值就行了，所以不额外做一次首次加载判断
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

      // 获取所有被屏蔽的分类
      List<String> shieldedCategoriesList =
          bikaSetting.shieldCategoryMap.entries
              .where((entry) => entry.value) // 只选择值为 true 的条目
              .map((entry) => entry.key) // 提取键（分类名）
              .toList();

      comics = comics.where((comic) {
        // 检查该漫画的分类是否与屏蔽分类列表中的任何分类匹配
        return !comic.doc.categories
            .any((category) => shieldedCategoriesList.contains(category));
      }).toList();

      emit(
        state.copyWith(
          status: UserFavouriteStatus.success,
          comics: comics,
          hasReachedMax: hasReachedMax,
          refresh: event.refresh,
          pageCount: event.pageCount,
          pagesCount: result.data.comics.pages,
        ),
      );
      initial = false;
    } catch (e) {
      if (comics.isNotEmpty) {
        emit(
          state.copyWith(
            status: UserFavouriteStatus.getMoreFailure,
            comics: comics,
            refresh: event.refresh,
            pageCount: event.pageCount,
            result: e.toString(),
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
}
