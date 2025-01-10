import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global.dart';
import 'package:zephyr/page/comments_children/comments_children.dart';

import '../../../main.dart';
import '../../../widgets/error_view.dart';
import '../../comments/json/comments_json/comments_json.dart' as comments_json;
import '../json/comments_children_json.dart';

@RoutePage()
class CommentsChildrenPage extends StatelessWidget {
  final comments_json.Doc fatherDoc;

  const CommentsChildrenPage({
    super.key,
    required this.fatherDoc,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CommentsChildrenBloc()
        ..add(CommentsChildrenEvent(
          fatherDoc.id,
          CommentsChildrenStatus.initial,
          1,
        )),
      child: _CommentsChildrenPage(
        fatherDoc: fatherDoc,
      ),
    );
  }
}

class _CommentsChildrenPage extends StatefulWidget {
  final comments_json.Doc fatherDoc;

  const _CommentsChildrenPage({required this.fatherDoc});

  @override
  _CommentsChildrenPageState createState() => _CommentsChildrenPageState();
}

class _CommentsChildrenPageState extends State<_CommentsChildrenPage> {
  comments_json.Doc get fatherDoc => widget.fatherDoc;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('评论详情'),
      ),
      body: BlocBuilder<CommentsChildrenBloc, CommentsChildrenState>(
        builder: (context, state) {
          switch (state.status) {
            case CommentsChildrenStatus.initial:
            case CommentsChildrenStatus.failure:
            case CommentsChildrenStatus.success:
            case CommentsChildrenStatus.getMoreFailure:
            case CommentsChildrenStatus.loadingMore:
              return _CommentWidget(
                fatherDoc: fatherDoc,
                state: state,
                fatherCommentIndex: 1,
              );
          }
        },
      ),
    );
  }
}

class _CommentWidget extends StatefulWidget {
  final comments_json.Doc fatherDoc;
  final CommentsChildrenState state;
  final int fatherCommentIndex;

  const _CommentWidget({
    required this.fatherDoc,
    required this.state,
    required this.fatherCommentIndex,
  });

  @override
  State<_CommentWidget> createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<_CommentWidget> {
  comments_json.Doc get fatherDoc => widget.fatherDoc;

  int get fatherCommentIndex => widget.fatherCommentIndex;

  CommentsChildrenState get state => widget.state;

  List<CommentsChildrenJson> comments = [];

  List<Doc> commentsDoc = [];

  int commentIndex = 1;

  final ScrollController _scrollController = ScrollController();

  // int _lastExecutedTime = 0;

  @override
  void initState() {
    super.initState();

    debugPrint("comments count: ${commentsDoc.length}");
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (state.status == CommentsChildrenStatus.initial) {
      return Column(
        children: [
          FatherCommentsWidget(doc: fatherDoc),
          _divider(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (state.status == CommentsChildrenStatus.failure) {
      return Column(
        children: [
          FatherCommentsWidget(doc: fatherDoc),
          _divider(),
          ErrorView(
            errorMessage: '${state.result.toString()}\n加载失败，请重试。',
            onRetry: () {
              context.read<CommentsChildrenBloc>().add(CommentsChildrenEvent(
                    fatherDoc.id,
                    CommentsChildrenStatus.initial,
                    1,
                  ));
            },
          )
        ],
      );
    }

    commentIndex = fatherCommentIndex;
    comments = state.commentsChildrenJson!;

    for (var comment in comments) {
      if (comment.data.comments.docs.isNotEmpty) {
        for (var doc in comment.data.comments.docs) {
          commentsDoc.add(doc);
        }
      }
    }
    commentsDoc = removeDuplicatesDoc(commentsDoc);

    commentIndex = state.count;

    if (commentIndex <= 2 && state.hasReachedMax == false) {
      _fetchMoreData();
    }

    return ListView.builder(
      itemCount: commentsDoc.length +
          1 +
          (state.status == CommentsChildrenStatus.loadingMore ? 1 : 0) +
          (state.status == CommentsChildrenStatus.getMoreFailure ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            children: [
              FatherCommentsWidget(doc: fatherDoc),
              _divider(),
              SizedBox(height: 5),
            ],
          );
        } else if (index == commentsDoc.length + 1 &&
            state.status == CommentsChildrenStatus.loadingMore) {
          return Padding(
            padding: const EdgeInsets.all(10),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (index == commentsDoc.length + 1 &&
            state.status == CommentsChildrenStatus.getMoreFailure) {
          return ErrorView(
            errorMessage: '点击重试',
            onRetry: () {
              context.read<CommentsChildrenBloc>().add(
                    CommentsChildrenEvent(
                      fatherDoc.id,
                      CommentsChildrenStatus.initial,
                      commentIndex,
                    ),
                  );
            },
          );
        } else {
          // 计算当前评论的索引
          int currentIndex = index - 1; // 因为 index == 0 已经被占用
          return CommentsChildrenWidget(
            doc: commentsDoc[currentIndex],
            index: currentIndex + 1,
          );
        }
      },
      controller: _scrollController,
    );
  }

  void _onScroll() {
    // debugPrint('滚动到了底部');
    if (_isBottom) {
      // 当滚动到达底部时执行相关操作
      _fetchMoreData();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9); // 调整触发的底部距离
  }

  void _fetchMoreData() {
    context.read<CommentsChildrenBloc>().add(
          CommentsChildrenEvent(
            fatherDoc.id,
            CommentsChildrenStatus.loadingMore,
            commentIndex + 1,
          ),
        );
    debugPrint('已经滚动到达底部，加载更多数据!');
  }

  List<Doc> removeDuplicatesDoc(List<Doc> commentsDoc) {
    // 用于存储已见过的 id
    Set<String> seenIds = {};

    // 使用 .where() 方法进行过滤
    return commentsDoc.where((comment) {
      // 检查当前 comment 的 id 是否已经在 seenIds 中
      if (seenIds.contains(comment.id)) {
        return false; // 已存在，过滤掉
      } else {
        seenIds.add(comment.id); // 记录新的 id
        return true; // 保留这个 comment
      }
    }).toList(); // 转换为 List<Doc>
  }

  Widget _divider() {
    return Container(
      width: screenHeight,
      height: 5,
      color: primaryColor,
    );
  }
}
