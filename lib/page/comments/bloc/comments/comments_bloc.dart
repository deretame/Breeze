import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../../../network/http/http_request.dart';
import '../../json/comments_json/comments_json.dart';

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

  List<CommentsJson> comments = [];
  bool hasReachedMax = false;

  Future<void> _fetchComments(
    CommentsEvent event,
    Emitter<CommentsState> emit,
  ) async {
    if (hasReachedMax) {
      return;
    }

    if (event.status == CommentsStatus.initial) {
      comments = [];
      emit(
        state.copyWith(
          status: CommentsStatus.initial,
        ),
      );
    } else if (event.status == CommentsStatus.loadingMore) {
      emit(
        state.copyWith(
          status: CommentsStatus.loadingMore,
          commentsJson: comments,
        ),
      );
    }

    try {
      var commentsJson = await _getComments(event.commentsId, event.count);

      comments = [...comments, commentsJson];
      if (int.parse(commentsJson.data.comments.page) >=
          commentsJson.data.comments.pages) {
        hasReachedMax = true;
      }

      emit(
        state.copyWith(
          status: CommentsStatus.success,
          commentsJson: comments,
          count: event.count,
          hasReachedMax: hasReachedMax,
        ),
      );
      return;
    } catch (e) {
      if (comments.isEmpty) {
        emit(
          state.copyWith(
            status: CommentsStatus.failure,
            result: e.toString(),
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: CommentsStatus.getMoreFailure,
          commentsJson: comments,
          count: event.count,
          result: e.toString(),
        ),
      );
    }
  }

  Future<CommentsJson> _getComments(String commentsId, int count) async {
    var temp = await getComments(commentsId, count);

    for (var comment in temp['data']['comments']['docs']) {
      comment['_id'] ??= '';
      comment['content'] ??= '';
      comment['_user']['_id'] ??= '';
      comment['_user']['gender'] ??= '';
      comment['_user']['name'] ??= '';
      comment['_user']['verified'] ??= false;
      comment['_user']['exp'] ??= 0;
      comment['_user']['level'] ??= 0;
      comment['_user']['characters'] ??= [];
      comment['_user']['role'] ??= '';
      comment['_user']
          ['avatar'] ??= {"fileServer": "", "path": "", "originalName": ""};
      comment['_user']['avatar']['originalName'] ??= '';
      comment['_user']['avatar']['path'] ??= '';
      comment['_user']['avatar']['fileServer'] ??= '';
      comment['_user']['title'] ??= '';
      comment['_user']['slogan'] ??= '';
      comment['_user']['character'] ??= '';
      comment['_comic'] ??= '';
      comment['totalComments'] ??= 0;
      comment['isTop'] ??= false;
      comment['hide'] ??= false;
      comment['created_at'] ??= DateTime(1970, 1, 1).toIso8601String();
      comment['id'] ??= '';
      comment['likesCount'] ??= 0;
      comment['commentsCount'] ??= 0;
      comment['isLiked'] ??= false;
    }

    for (var topComment in temp['data']['topComments']) {
      topComment['_id'] ??= '';
      topComment['content'] ??= '';
      topComment['_user']['_id'] ??= '';
      topComment['_user']['gender'] ??= '';
      topComment['_user']['name'] ??= '';
      topComment['_user']['verified'] ??= false;
      topComment['_user']['exp'] ??= 0;
      topComment['_user']['level'] ??= 0;
      topComment['_user']['characters'] ??= [];
      topComment['_user']['role'] ??= '';
      topComment['_user']
          ['avatar'] ??= {"fileServer": "", "path": "", "originalName": ""};
      topComment['_user']['avatar']['originalName'] ??= '';
      topComment['_user']['avatar']['path'] ??= '';
      topComment['_user']['avatar']['fileServer'] ??= '';
      topComment['_user']['title'] ??= '';
      topComment['_user']['slogan'] ??= '';
      topComment['_user']['character'] ??= '';
      topComment['_comic'] ??= '';
      topComment['isTop'] ??= false;
      topComment['hide'] ??= false;
      topComment['created_at'] ??= DateTime(1970, 1, 1).toIso8601String();
      topComment['totalComments'] ??= 0;
      topComment['likesCount'] ??= 0;
      topComment['commentsCount'] ??= 0;
      topComment['isLiked'] ??= false;
    }

    temp['data']['topComments'] =
        List<dynamic>.from(temp['data']['topComments']).reversed.toList();

    var commentsJson = CommentsJson.fromJson(temp);
    return commentsJson;
  }
}
