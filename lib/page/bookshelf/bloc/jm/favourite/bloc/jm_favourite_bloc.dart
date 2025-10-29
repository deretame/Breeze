import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/bookshelf/models/search_enter.dart';

part 'jm_favourite_event.dart';
part 'jm_favourite_state.dart';
part 'jm_favourite_bloc.freezed.dart';

const _throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> _throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class JmFavouriteBloc extends Bloc<JmFavouriteEvent, JmFavouriteState> {
  JmFavouriteBloc() : super(JmFavouriteState()) {
    on<JmFavouriteEvent>(
      _fetchComicList,
      transformer: _throttleDroppable(_throttleDuration),
    );
  }

  bool initial = true;
  int totalComicCount = 0;

  Future<void> _fetchComicList(
    JmFavouriteEvent event,
    Emitter<JmFavouriteState> emit,
  ) async {
    if (state.searchEnterConst == event.searchEnterConst && initial == false) {
      return; // 如果状态相同，直接返回，避免再次请求
    }

    if (initial) {
      emit(
        state.copyWith(
          status: JmFavouriteStatus.initial,
          comics: [],
          searchEnterConst: event.searchEnterConst,
        ),
      );
    }

    try {
      emit(
        state.copyWith(
          status: JmFavouriteStatus.success,
          comics: _getComicList(event),
          searchEnterConst: event.searchEnterConst,
          result: totalComicCount.toString(),
        ),
      );
      initial = false;
    } catch (e) {
      emit(
        state.copyWith(
          status: JmFavouriteStatus.failure,
          result: e.toString(),
          searchEnterConst: event.searchEnterConst,
        ),
      );
    }
  }

  List<JmFavorite> _fetchOfSort(List<JmFavorite> comicList, String sort) {
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
    comicList.removeWhere((comic) => comic.deleted == true);

    return comicList;
  }

  List<JmFavorite> _getComicList(JmFavouriteEvent event) {
    List<JmFavorite> comicsList = [];
    var temp = objectbox.jmFavoriteBox.getAll();

    totalComicCount = temp.length;

    if (event.searchEnterConst.keyword.isNotEmpty) {
      final keyword = event.searchEnterConst.keyword.toLowerCase();

      temp = temp.where((comic) {
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

    comicsList = _fetchOfSort(temp, event.searchEnterConst.sort);
    return comicsList;
  }
}
