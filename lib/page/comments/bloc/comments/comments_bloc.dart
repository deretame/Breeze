import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
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
    if (hasReachedMax && event.status != CommentsStatus.comment) {
      return;
    }

    if (event.status == CommentsStatus.initial) {
      comments = [];
      emit(
        state.copyWith(
          status: CommentsStatus.initial,
        ),
      );
    }

    if (event.status == CommentsStatus.loadingMore) {
      emit(
        state.copyWith(
          status: CommentsStatus.loadingMore,
          commentsJson: comments,
        ),
      );
    }

    try {
      var commentsJson = await _getComments(event.commentsId, event.count);
      debugPrint(limitString(commentsJson.toString(), 150));
      if (event.status == CommentsStatus.comment) {
        comments = [commentsJson, ...comments];
      } else {
        comments = [...comments, commentsJson];

        if (int.parse(commentsJson.data.comments.page) >=
            commentsJson.data.comments.pages) {
          hasReachedMax = true;
        }
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
      debugPrint(e.toString());
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
          count: event.count - 1,
          result: e.toString(),
        ),
      );
    }
  }

  Future<CommentsJson> _getComments(String commentsId, int count) async {
    var temp = await getComments(commentsId, count);
    return handleComment(temp);
  }

  CommentsJson handleComment(Map<String, dynamic> temp) {
    for (var comment in temp['data']['comments']['docs']) {
      comment['_id'] ??= '';
      comment['content'] ??= '';
      comment['_user'] ??= {
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

var tempJson = {
  "code": 200,
  "message": "success",
  "data": {
    "comments": {
      "docs": [
        {
          "_id": "6781f7d279fe26e9eaf67569",
          "content": "3",
          "_user": {
            "_id": "598fcb7f6438d97844947571",
            "gender": "m",
            "name": "微笑(=^▽^=)",
            "title": "萌新",
            "verified": false,
            "exp": 1310,
            "level": 4,
            "characters": [],
            "role": "member",
            "avatar": {
              "originalName": "avatar.jpg",
              "path": "tobs/a359c0ba-bda7-4b04-b10a-7521792046b0.jpg",
              "fileServer": "https://storage-b.picacomic.com"
            },
            "slogan": "1",
            "character": "https://pica-web.wakamoment.tk/images/halloween_m.png"
          },
          "_comic": "66d5cc3f7c4e9a3882743c18",
          "totalComments": 0,
          "isTop": false,
          "hide": false,
          "created_at": "2025-01-11T04:47:14.524Z",
          "id": "6781f7d279fe26e9eaf67569",
          "likesCount": 0,
          "commentsCount": 0,
          "isLiked": false
        },
        {
          "_id": "6781f794f10e90f2440eb552",
          "content": "2",
          "_user": {
            "_id": "598fcb7f6438d97844947571",
            "gender": "m",
            "name": "微笑(=^▽^=)",
            "title": "萌新",
            "verified": false,
            "exp": 1310,
            "level": 4,
            "characters": [],
            "role": "member",
            "avatar": {
              "originalName": "avatar.jpg",
              "path": "tobs/a359c0ba-bda7-4b04-b10a-7521792046b0.jpg",
              "fileServer": "https://storage-b.picacomic.com"
            },
            "slogan": "1",
            "character": "https://pica-web.wakamoment.tk/images/halloween_m.png"
          },
          "_comic": "66d5cc3f7c4e9a3882743c18",
          "totalComments": 0,
          "isTop": false,
          "hide": false,
          "created_at": "2025-01-11T04:46:12.870Z",
          "id": "6781f794f10e90f2440eb552",
          "likesCount": 0,
          "commentsCount": 0,
          "isLiked": false
        },
        {
          "_id": "6781f78ba599b4f258c69ba6",
          "content": "1",
          "_user": {
            "_id": "598fcb7f6438d97844947571",
            "gender": "m",
            "name": "微笑(=^▽^=)",
            "title": "萌新",
            "verified": false,
            "exp": 1310,
            "level": 4,
            "characters": [],
            "role": "member",
            "avatar": {
              "originalName": "avatar.jpg",
              "path": "tobs/a359c0ba-bda7-4b04-b10a-7521792046b0.jpg",
              "fileServer": "https://storage-b.picacomic.com"
            },
            "slogan": "1",
            "character": "https://pica-web.wakamoment.tk/images/halloween_m.png"
          },
          "_comic": "66d5cc3f7c4e9a3882743c18",
          "totalComments": 0,
          "isTop": false,
          "hide": false,
          "created_at": "2025-01-11T04:46:03.240Z",
          "id": "6781f78ba599b4f258c69ba6",
          "likesCount": 0,
          "commentsCount": 0,
          "isLiked": false
        },
        {
          "_id": "6781f6126885b3fd2fc204a6",
          "content": "💕",
          "_user": {
            "_id": "598fcb7f6438d97844947571",
            "gender": "m",
            "name": "微笑(=^▽^=)",
            "title": "萌新",
            "verified": false,
            "exp": 1310,
            "level": 4,
            "characters": [],
            "role": "member",
            "avatar": {
              "originalName": "avatar.jpg",
              "path": "tobs/a359c0ba-bda7-4b04-b10a-7521792046b0.jpg",
              "fileServer": "https://storage-b.picacomic.com"
            },
            "slogan": "1",
            "character": "https://pica-web.wakamoment.tk/images/halloween_m.png"
          },
          "_comic": "66d5cc3f7c4e9a3882743c18",
          "totalComments": 0,
          "isTop": false,
          "hide": false,
          "created_at": "2025-01-11T04:39:46.314Z",
          "id": "6781f6126885b3fd2fc204a6",
          "likesCount": 0,
          "commentsCount": 0,
          "isLiked": false
        },
        {
          "_id": "6781f5e46194494648dfa0e5",
          "content": "💕",
          "_user": {
            "_id": "598fcb7f6438d97844947571",
            "gender": "m",
            "name": "微笑(=^▽^=)",
            "title": "萌新",
            "verified": false,
            "exp": 1310,
            "level": 4,
            "characters": [],
            "role": "member",
            "avatar": {
              "originalName": "avatar.jpg",
              "path": "tobs/a359c0ba-bda7-4b04-b10a-7521792046b0.jpg",
              "fileServer": "https://storage-b.picacomic.com"
            },
            "slogan": "1",
            "character": "https://pica-web.wakamoment.tk/images/halloween_m.png"
          },
          "_comic": "66d5cc3f7c4e9a3882743c18",
          "totalComments": 0,
          "isTop": false,
          "hide": false,
          "created_at": "2025-01-11T04:39:00.849Z",
          "id": "6781f5e46194494648dfa0e5",
          "likesCount": 0,
          "commentsCount": 0,
          "isLiked": false
        },
        {
          "_id": "6781f5b6680944399fa6adb9",
          "content": "💕",
          "_user": {
            "_id": "598fcb7f6438d97844947571",
            "gender": "m",
            "name": "微笑(=^▽^=)",
            "title": "萌新",
            "verified": false,
            "exp": 1310,
            "level": 4,
            "characters": [],
            "role": "member",
            "avatar": {
              "originalName": "avatar.jpg",
              "path": "tobs/a359c0ba-bda7-4b04-b10a-7521792046b0.jpg",
              "fileServer": "https://storage-b.picacomic.com"
            },
            "slogan": "1",
            "character": "https://pica-web.wakamoment.tk/images/halloween_m.png"
          },
          "_comic": "66d5cc3f7c4e9a3882743c18",
          "totalComments": 0,
          "isTop": false,
          "hide": false,
          "created_at": "2025-01-11T04:38:14.271Z",
          "id": "6781f5b6680944399fa6adb9",
          "likesCount": 0,
          "commentsCount": 0,
          "isLiked": false
        },
        {
          "_id": "6781f3f1895935f6205729bb",
          "content": "💕",
          "_user": {
            "_id": "598fcb7f6438d97844947571",
            "gender": "m",
            "name": "微笑(=^▽^=)",
            "title": "萌新",
            "verified": false,
            "exp": 1310,
            "level": 4,
            "characters": [],
            "role": "member",
            "avatar": {
              "originalName": "avatar.jpg",
              "path": "tobs/a359c0ba-bda7-4b04-b10a-7521792046b0.jpg",
              "fileServer": "https://storage-b.picacomic.com"
            },
            "slogan": "1",
            "character": "https://pica-web.wakamoment.tk/images/halloween_m.png"
          },
          "_comic": "66d5cc3f7c4e9a3882743c18",
          "totalComments": 0,
          "isTop": false,
          "hide": false,
          "created_at": "2025-01-11T04:30:41.214Z",
          "id": "6781f3f1895935f6205729bb",
          "likesCount": 0,
          "commentsCount": 0,
          "isLiked": false
        },
        {
          "_id": "6755d7a605dece67f9bf3194",
          "content": "偶像，不是杀就是被杀",
          "_user": {
            "_id": "5c4ebd7c48fbd4356bce5dce",
            "gender": "m",
            "name": "正经绅士罢",
            "title": "萌新",
            "verified": false,
            "exp": 3140,
            "level": 6,
            "characters": [],
            "role": "member",
            "avatar": {
              "originalName": "avatar.jpg",
              "path": "adf11d7d-460d-466a-82e2-cbdd64878531.jpg",
              "fileServer": "https://storage1.picacomic.com"
            },
            "slogan": "nullllllllllllllll",
            "character": "https://pica-web.wakamoment.tk/images/halloween_m.png"
          },
          "_comic": "66d5cc3f7c4e9a3882743c18",
          "totalComments": 0,
          "isTop": false,
          "hide": false,
          "created_at": "2024-12-08T17:30:14.683Z",
          "id": "6755d7a605dece67f9bf3194",
          "likesCount": 0,
          "commentsCount": 0,
          "isLiked": false
        }
      ],
      "total": 8,
      "limit": 20,
      "page": "1",
      "pages": 1
    },
    "topComments": []
  }
};
