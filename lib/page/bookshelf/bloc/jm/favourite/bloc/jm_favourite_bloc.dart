import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/bookshelf/models/search_enter.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/sundry.dart';

part 'jm_favourite_bloc.freezed.dart';
part 'jm_favourite_event.dart';
part 'jm_favourite_state.dart';

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

  List<UnifiedComicFavorite> _fetchOfSort(
    List<UnifiedComicFavorite> comicList,
    String sort,
  ) {
    if (sort == "dd") {
      comicList.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    if (sort == "da") {
      comicList.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    }
    if (sort == "ld") {
      comicList.sort((a, b) => b.title.compareTo(a.title));
    }
    if (sort == "vd") {
      comicList.sort((a, b) => b.title.compareTo(a.title));
    }
    comicList.removeWhere((comic) => comic.deleted == true);

    return comicList;
  }

  List<UnifiedComicFavorite> _getComicList(JmFavouriteEvent event) {
    List<UnifiedComicFavorite> comicsList = [];
    var temp = objectbox.unifiedFavoriteBox
        .query(UnifiedComicFavorite_.source.equals('jm'))
        .build()
        .find();

    totalComicCount = temp.length;

    if (event.searchEnterConst.keyword.isNotEmpty) {
      final keyword = event.searchEnterConst.keyword.toLowerCase();

      temp = temp.where((comic) {
        var allString =
            comic.comicId +
            comic.title +
            comic.description +
            comic.metadata.toString();
        return allString.toLowerCase().let(t2s).contains(keyword.let(t2s));
      }).toList();
    }

    comicsList = _fetchOfSort(temp, event.searchEnterConst.sort);
    return comicsList;
  }
}
