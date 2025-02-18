import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../../network/http/http_request.dart';
import '../json/user_comments_json.dart';

part 'user_comments_event.dart';
part 'user_comments_state.dart';

const _throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> _throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class UserCommentsBloc extends Bloc<UserCommentsEvent, UserCommentsState> {
  UserCommentsBloc() : super(UserCommentsState()) {
    on<UserCommentsEvent>(
      _fetchComments,
      transformer: _throttleDroppable(_throttleDuration),
    );
  }

  bool hasReachedMax = false;
  List<UserCommentsJson> userComments = [];

  Future<void> _fetchComments(
    UserCommentsEvent event,
    Emitter<UserCommentsState> emit,
  ) async {
    if (hasReachedMax) {
      return;
    }

    if (event.status == UserCommentsStatus.initial) {
      userComments = [];
      emit(state.copyWith(status: UserCommentsStatus.initial));
    }

    if (event.status == UserCommentsStatus.loadingMore) {
      emit(
        state.copyWith(
          status: UserCommentsStatus.loadingMore,
          userCommentsJson: userComments,
        ),
      );
    }

    try {
      var commentsJson = await _getComments(event.count);
      debugPrint(limitString(commentsJson.toString(), 150));

      userComments = [...userComments, commentsJson];

      if (int.parse(commentsJson.data.comments.page) >=
          commentsJson.data.comments.pages) {
        hasReachedMax = true;
      }

      emit(
        state.copyWith(
          status: UserCommentsStatus.success,
          userCommentsJson: userComments,
          count: event.count,
          hasReachedMax: hasReachedMax,
        ),
      );
      return;
    } catch (e) {
      debugPrint(e.toString());
      if (userComments.isEmpty) {
        emit(
          state.copyWith(
            status: UserCommentsStatus.failure,
            result: e.toString(),
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: UserCommentsStatus.getMoreFailure,
          userCommentsJson: userComments,
          count: event.count - 1,
          result: e.toString(),
        ),
      );
    }
  }

  Future<UserCommentsJson> _getComments(int count) async {
    var temp = await getUserComments(count);
    return UserCommentsJson.fromJson(temp);
  }
}
