import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/jm/http_request.dart';
import 'package:zephyr/page/jm/jm_comments/json/comments_json.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/json/json_dispose.dart';

part 'comments_bloc.freezed.dart';
part 'comments_event.dart';
part 'comments_state.dart';

const _throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> _throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class CommentsBloc extends Bloc<CommentsEvent, CommentsState> {
  CommentsBloc() : super(CommentsState()) {
    on<CommentsEvent>(
      _fetchComments,
      transformer: _throttleDroppable(_throttleDuration),
    );
  }

  int page = 1;
  List<ListElement> comments = [];
  bool hasReachedMax = false;

  Future<void> _fetchComments(
    CommentsEvent event,
    Emitter<CommentsState> emit,
  ) async {
    if (hasReachedMax) return;

    if (event.status == CommentsStatus.initial) {
      emit(state.copyWith(status: CommentsStatus.initial));
      page = 1;
      comments = [];
      hasReachedMax = false;
    } else if (event.status == CommentsStatus.loadingMore) {
      emit(
        state.copyWith(status: CommentsStatus.loadingMore, comments: comments),
      );
    }

    try {
      final response = await getComments(page, event.comicId)
          .let(replaceNestedNull)
          .let((it) {
            it["total"] = (it["total"] as int).toString();
            return it;
          })
          .let(CommentsJson.fromJson);

      comments = [...comments, ...response.list];

      final totalPage = (response.total.let(toInt) / 10).ceil();
      hasReachedMax = page == totalPage;

      emit(
        state.copyWith(
          status: CommentsStatus.success,
          comments: comments,
          hasReachedMax: hasReachedMax,
        ),
      );
      page++;
    } catch (e) {
      logger.e(e);

      if (comments.isNotEmpty) {
        emit(
          state.copyWith(
            status: CommentsStatus.failure,
            comments: comments,
            result: e.toString(),
          ),
        );
        return;
      }

      emit(
        state.copyWith(status: CommentsStatus.failure, result: e.toString()),
      );
    }
  }
}
