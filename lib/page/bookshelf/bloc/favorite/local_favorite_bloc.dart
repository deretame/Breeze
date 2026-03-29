import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/bookshelf/models/search_enter.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/sundry.dart';

part 'local_favorite_bloc.freezed.dart';
part 'local_favorite_event.dart';
part 'local_favorite_state.dart';

const _throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> _throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class LocalFavoriteBloc extends Bloc<LocalFavoriteEvent, LocalFavoriteState> {
  LocalFavoriteBloc() : super(LocalFavoriteState()) {
    on<LocalFavoriteEvent>(
      _fetchComicList,
      transformer: _throttleDroppable(_throttleDuration),
    );
  }

  bool initial = true;
  int totalComicCount = 0;

  Future<void> _fetchComicList(
    LocalFavoriteEvent event,
    Emitter<LocalFavoriteState> emit,
  ) async {
    if (state.searchEnterConst == event.searchEnterConst && initial == false) {
      return; // 如果状态相同，直接返回，避免再次请求
    }

    if (initial) {
      emit(
        state.copyWith(
          status: LocalFavoriteStatus.initial,
          comics: [],
          searchEnterConst: event.searchEnterConst,
        ),
      );
    }

    try {
      emit(
        state.copyWith(
          status: LocalFavoriteStatus.success,
          comics: _getComicList(event),
          searchEnterConst: event.searchEnterConst,
          result: totalComicCount.toString(),
        ),
      );
      initial = false;
    } catch (e) {
      emit(
        state.copyWith(
          status: LocalFavoriteStatus.failure,
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

  List<UnifiedComicFavorite> _getComicList(LocalFavoriteEvent event) {
    List<UnifiedComicFavorite> comicsList = [];
    final sourceFilter = event.searchEnterConst.sources;
    var temp = objectbox.unifiedFavoriteBox
        .getAll()
        .where((comic) => sourceFilter.contains(comic.source))
        .toList();

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
