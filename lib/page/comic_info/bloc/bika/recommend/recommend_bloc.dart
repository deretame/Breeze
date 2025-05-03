import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/network/http/bika/http_request.dart';

import '../../../json/bika/recommend/recommend_json.dart';

part 'recommend_event.dart';

part 'recommend_state.dart';

const _throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> _throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class RecommendBloc extends Bloc<RecommendEvent, RecommendState> {
  RecommendBloc() : super(RecommendState()) {
    on<RecommendEvent>(
      _fetchComicList,
      transformer: _throttleDroppable(_throttleDuration),
    );
  }

  Future<void> _fetchComicList(
    RecommendEvent event,
    Emitter<RecommendState> emit,
  ) async {
    if (event.status == RecommendStatus.initial) {
      emit(state.copyWith(status: RecommendStatus.initial));
    }

    try {
      final result = await getRecommend(event.comicId);

      final comics = result['data']['comics'] as List;

      if (comics.isEmpty) {
        emit(state.copyWith(status: RecommendStatus.success, comicList: null));
      } else {
        List<Comic> comicList = [];
        for (var comic in comics) {
          comic['author'] ??= '';
          if (comic['likesCount'] is String) {
            comic['likesCount'] = int.parse(comic['likesCount']);
          }
          comic['thumb'] ??= {"fileServer": "", "path": "", "originalName": ""};
          comic['thumb']['fileServer'] ??= '';
          comic['thumb']['path'] ??= '';
          comic['thumb']['originalName'] ??= '';
        }
        final temp = RecommendJson.fromJson(result);
        for (var comic in temp.data.comics) {
          comicList.add(comic);
        }
        emit(
          state.copyWith(status: RecommendStatus.success, comicList: comicList),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(status: RecommendStatus.failure, result: e.toString()),
      );
    }
  }
}
