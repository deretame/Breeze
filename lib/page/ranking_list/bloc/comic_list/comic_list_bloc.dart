import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/network/http/http_request.dart';

import '../../json/leaderboard.dart';
import '../../models/models.dart';

part 'comic_list_event.dart';
part 'comic_list_state.dart';

const throttleDurationComic = Duration(milliseconds: 100);

EventTransformer<E> throttleDroppableComic<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class ComicListBloc extends Bloc<FetchComicList, ComicListState> {
  ComicListBloc() : super(ComicListState()) {
    on<FetchComicList>(
      _fetchComicList,
      transformer: throttleDroppableComic(throttleDurationComic),
    );
  }

  Future<void> _fetchComicList(
    FetchComicList event,
    Emitter<ComicListState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ComicListStatus.initial,
      ),
    );

    try {
      var temp = await getRankingList(
        days: event.getInfo.days,
        type: event.getInfo.type,
      );

      var result = Leaderboard.fromJson(temp);

      emit(
        state.copyWith(
          status: ComicListStatus.success,
          comicList: result.data.comics,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ComicListStatus.failure,
          result: e.toString(),
        ),
      );
    }
  }
}
