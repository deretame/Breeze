import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/comments/comments.dart';

import '../../../widgets/error_view.dart';
import '../json/comments_json/comments_json.dart';

@RoutePage()
class CommentsPage extends StatelessWidget {
  final String comicId;
  final String comicTitle;

  const CommentsPage({
    super.key,
    required this.comicId,
    required this.comicTitle,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CommentsBloc()
        ..add(CommentsEvent(comicId, CommentsStatus.initial, 1)),
      child: _ComicReadPage(
        comicId: comicId,
        comicTitle: comicTitle,
      ),
    );
  }
}

class _ComicReadPage extends StatefulWidget {
  final String comicId;
  final String comicTitle;

  const _ComicReadPage({
    required this.comicId,
    required this.comicTitle,
  });

  @override
  State<_ComicReadPage> createState() => _ComicReadPageState();
}

class _ComicReadPageState extends State<_ComicReadPage> {
  get comicTitle => widget.comicTitle;

  get comicId => widget.comicId;

  int commentIndex = 1;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ScrollableTitle(
          text: comicTitle,
        ),
      ),
      body: BlocBuilder<CommentsBloc, CommentsState>(builder: (context, state) {
        switch (state.status) {
          case CommentsStatus.initial:
            return Center(child: CircularProgressIndicator());
          case CommentsStatus.success:
            commentIndex = state.count;
            return _CommentWidget(
              comments: state.commentsJson!,
              fatherCommentIndex: commentIndex,
              status: state.status,
            );
          case CommentsStatus.failure:
            return ErrorView(
              errorMessage: '${state.result.toString()}\n加载失败，请重试。',
              onRetry: () {
                context.read<CommentsBloc>().add(
                      CommentsEvent(
                        comicId,
                        CommentsStatus.initial,
                        commentIndex,
                      ),
                    );
              },
            );
          case CommentsStatus.getMoreFailure:
            commentIndex = state.count;
            return _CommentWidget(
              comments: state.commentsJson!,
              fatherCommentIndex: commentIndex,
              status: state.status,
            );
          case CommentsStatus.loadingMore:
            commentIndex = state.count;
            return _CommentWidget(
              comments: state.commentsJson!,
              fatherCommentIndex: commentIndex,
              status: state.status,
            );
        }
      }),
    );
  }
}

class _CommentWidget extends StatefulWidget {
  final List<CommentsJson> comments;
  final int fatherCommentIndex;
  final CommentsStatus status;

  const _CommentWidget({
    required this.comments,
    required this.fatherCommentIndex,
    required this.status,
  });

  @override
  State<_CommentWidget> createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<_CommentWidget> {
  int get fatherCommentIndex => widget.fatherCommentIndex;

  List<CommentsJson> comments = [];

  List<TopComment> topComments = [];
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
    commentIndex = fatherCommentIndex;
    comments = widget.comments;
    for (var comment in comments) {
      if (comment.data.topComments.isNotEmpty) {
        for (var topComment in comment.data.topComments) {
          topComments.add(topComment);
        }
      }
    }
    topComments = removeDuplicates(topComments);

    for (var comment in comments) {
      if (comment.data.comments.docs.isNotEmpty) {
        for (var doc in comment.data.comments.docs) {
          commentsDoc.add(doc);
        }
      }
    }
    commentsDoc = removeDuplicatesDoc(commentsDoc);
    return CustomScrollView(
      slivers: [
        if (topComments.isNotEmpty) ...[
          ...topComments.asMap().entries.map(
            (entry) {
              int index = entry.key; // 获取当前索引
              var topComment = entry.value; // 获取当前的 topComment

              return SliverToBoxAdapter(
                child: CommentsWidget(
                  doc: topCommentToDoc(topComment),
                  index: index, // 将索引传递给 CommentsWidget
                ),
              );
            },
          )
        ],
        if (commentsDoc.isNotEmpty) ...[
          ...commentsDoc.asMap().entries.map(
            (entry) {
              int index = comments[0].data.comments.total - entry.key; // 获取当前索引
              var comment = entry.value; // 获取当前的 topComment

              return SliverToBoxAdapter(
                child: CommentsWidget(
                  doc: comment,
                  index: index, // 将索引传递给 CommentsWidget
                ),
              );
            },
          )
        ],
        if (widget.status == CommentsStatus.loadingMore) ...[
          SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
        if (widget.status == CommentsStatus.getMoreFailure) ...[
          SliverToBoxAdapter(
            child: ErrorView(
              errorMessage: '点击重试',
              onRetry: () {
                context.read<CommentsBloc>().add(
                      CommentsEvent(
                        comments[0].data.comments.docs[0].comic,
                        CommentsStatus.initial,
                        commentIndex,
                      ),
                    );
              },
            ),
          ),
        ]
      ],
      controller: _scrollController, // 设置控制器
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
    context.read<CommentsBloc>().add(
          CommentsEvent(
            comments[0].data.comments.docs[0].comic,
            CommentsStatus.loadingMore,
            commentIndex + 1,
          ),
        );
    debugPrint('已经滚动到达底部，加载更多数据!');
  }

  List<TopComment> removeDuplicates(List<TopComment> topComments) {
    // 用于存储已见过的 id
    Set<String> seenIds = {};

    // 使用 .where() 方法进行过滤
    return topComments.where((comment) {
      // 检查当前 comment 的 id 是否已经在 seenIds 中
      if (seenIds.contains(comment.id)) {
        return false; // 已存在，过滤掉
      } else {
        seenIds.add(comment.id); // 记录新的 id
        return true; // 保留这个 comment
      }
    }).toList(); // 转换为 List<TopComment>
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
}
