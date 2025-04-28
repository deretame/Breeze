import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/network/http/bika/http_request.dart';

import '../json/comments_children_json.dart';

part 'comments_children_event.dart';

part 'comments_children_state.dart';

const _throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> _throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class CommentsChildrenBloc
    extends Bloc<CommentsChildrenEvent, CommentsChildrenState> {
  CommentsChildrenBloc() : super(CommentsChildrenState()) {
    on<CommentsChildrenEvent>(
      _fetchCommentsChildren,
      transformer: _throttleDroppable(_throttleDuration),
    );
  }

  List<CommentsChildrenJson> comments = [];
  bool hasReachedMax = false;

  Future<void> _fetchCommentsChildren(
    CommentsChildrenEvent event,
    Emitter<CommentsChildrenState> emit,
  ) async {
    if (hasReachedMax && event.status != CommentsChildrenStatus.comment) {
      return;
    }

    if (event.status == CommentsChildrenStatus.initial) {
      comments = [];
      emit(state.copyWith(status: CommentsChildrenStatus.initial));
    } else if (event.status == CommentsChildrenStatus.loadingMore) {
      emit(
        state.copyWith(
          status: CommentsChildrenStatus.loadingMore,
          commentsChildrenJson: comments,
        ),
      );
    }

    try {
      var commentsJson = await _getCommentsChildren(
        event.commentChildrenId,
        event.count,
      );
      if (event.status == CommentsChildrenStatus.comment) {
        comments = [commentsJson, ...comments];
      } else {
        comments = [...comments, commentsJson];
      }
      if (int.parse(commentsJson.data.comments.page) >=
          commentsJson.data.comments.pages) {
        hasReachedMax = true;
      }

      emit(
        state.copyWith(
          status: CommentsChildrenStatus.success,
          commentsChildrenJson: comments,
          count: event.count,
          hasReachedMax: hasReachedMax,
        ),
      );
      return;
    } catch (e) {
      if (comments.isEmpty) {
        emit(
          state.copyWith(
            status: CommentsChildrenStatus.failure,
            result: e.toString(),
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: CommentsChildrenStatus.getMoreFailure,
          commentsChildrenJson: comments,
          count: event.count - 1,
          result: e.toString(),
        ),
      );
    }
  }

  Future<CommentsChildrenJson> _getCommentsChildren(
    String commentsId,
    int count,
  ) async {
    var temp = await getCommentsChildren(commentsId, count);
    // 空安全检查和提供默认值
    temp['code'] ??= 0;
    temp['message'] ??= '';
    temp['data'] ??= {};

    var data = temp['data'];
    data['comments'] ??= {};

    var comments = data['comments'];
    comments['docs'] ??= [];
    comments['total'] ??= 0;
    comments['limit'] ??= 0;
    comments['page'] ??= '';
    comments['pages'] ??= 0;

    for (var doc in comments['docs']) {
      doc['_id'] ??= '';
      doc['content'] ??= '';
      doc['_user'] ??= {};
      doc['_parent'] ??= '';
      doc['_comic'] ??= '';
      doc['totalComments'] ??= 0;
      doc['isTop'] ??= false;
      doc['hide'] ??= false;
      doc['created_at'] ??= DateTime(1970, 1, 1).toIso8601String();
      doc['id'] ??= '';
      doc['likesCount'] ??= 0;
      doc['isLiked'] ??= false;

      doc['_user'] ??= {
        "_id": "",
        "gender": "",
        "name": "用户已注销",
        "verified": false,
        "exp": 0,
        "level": 0,
        "characters": [],
        "role": "",
        "avatar": {"fileServer": "", "path": "", "originalName": ""},
        "title": "",
        "slogan": "",
        "character": "",
      };
      var user = doc['_user'];
      user['_id'] ??= '';
      user['gender'] ??= 'bot';
      user['name'] ??= '';
      user['title'] ??= '';
      user['verified'] ??= false;
      user['exp'] ??= 0;
      user['level'] ??= 0;
      user['characters'] ??= [];
      user['role'] ??= 'member';
      user['avatar'] ??= {};
      user['slogan'] ??= '';
      user['character'] ??= '';
      user['avatar'] ??= {"fileServer": "", "path": "", "originalName": ""};
      user['avatar'] = Map<String, dynamic>.from(user['avatar']);

      var avatar = user['avatar'];
      avatar['originalName'] ??= '';
      avatar['path'] ??= '';
      avatar['fileServer'] ??= '';
    }

    var commentsJson = CommentsChildrenJson.fromJson(temp);
    return commentsJson;
  }
}
