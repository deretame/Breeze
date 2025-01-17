import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:zephyr/page/comments/comments.dart';

import '../../../main.dart';
import '../../../network/http/http_request.dart';
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
          case CommentsStatus.success:
          case CommentsStatus.getMoreFailure:
          case CommentsStatus.loadingMore:
          case CommentsStatus.comment:
            return _CommentWidget(
              state: state,
            );
        }
      }),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.comment),
        onPressed: () async {
          var text = await _showInputDialog(context, '发表评论', '输入评论内容');
          if (text.isEmpty) {
            return;
          }
          _writeComment(comicId, text);
        },
      ),
    );
  }

  Future<void> _writeComment(String comicId, String text) async {
    try {
      await writeComment(comicId, text);

      // 检查 State 是否仍然挂载
      if (!mounted) return;

      context
          .read<CommentsBloc>()
          .add(CommentsEvent(comicId, CommentsStatus.comment, 1));
    } catch (e) {
      debugPrint(e.toString());
      EasyLoading.showError('评论失败，请稍后再试。\n${e.toString()}');
    }
  }

  // 弹出输入框对话框
  Future<String> _showInputDialog(
    BuildContext context,
    String title,
    String defaultText,
  ) async {
    final TextEditingController controller = TextEditingController();

    String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return Observer(builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0), // 圆角
            ),
            child: Container(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min, // 使对话框根据内容调整大小
                children: [
                  Text(title),
                  SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      // color: Colors.grey[200], // 背景色
                      border: Border.all(
                        color: globalSetting.themeType
                            ? materialColorScheme.secondaryFixedDim
                            : materialColorScheme.secondaryFixedDim,
                      ), // 边框
                      borderRadius: BorderRadius.circular(8.0), // 圆角
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextField(
                      controller: controller,
                      maxLines: null, // 设置多行输入
                      decoration: InputDecoration(
                        border: InputBorder.none, // 去掉默认的输入框边框
                        hintText: defaultText,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // 关闭对话框
                        },
                        child: Text('取消'),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(controller.text); // 返回输入内容
                        },
                        child: Text('确认'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
      },
    );

    return result ?? "";
  }
}

class _CommentWidget extends StatefulWidget {
  final CommentsState state;

  const _CommentWidget({
    required this.state,
  });

  @override
  State<_CommentWidget> createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<_CommentWidget> {
  CommentsState get state => widget.state;

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
    if (state.status != CommentsStatus.comment) {
      commentIndex = state.count;
    }

    comments = state.commentsJson!;
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
    return ListView.builder(
      itemCount: topComments.length +
          commentsDoc.length +
          (state.status == CommentsStatus.loadingMore ? 1 : 0) +
          (state.status == CommentsStatus.getMoreFailure ? 1 : 0) +
          1,
      itemBuilder: (context, index) {
        // 处理 topComments
        if (index < topComments.length) {
          var topComment = topComments[index];
          return CommentsWidget(
            doc: topCommentToDoc(topComment),
            index: index,
          );
        }

        // 处理 commentsDoc
        if (index < topComments.length + commentsDoc.length) {
          int commentIndex = index - topComments.length;
          var comment = commentsDoc[commentIndex];
          int displayIndex = comments[0].data.comments.total - commentIndex;
          return CommentsWidget(
            doc: comment,
            index: displayIndex,
          );
        }

        // 处理加载更多指示器
        if (state.status == CommentsStatus.loadingMore &&
            index == topComments.length + commentsDoc.length) {
          return Center(child: CircularProgressIndicator());
        }

        // 处理加载失败的错误视图
        if (state.status == CommentsStatus.getMoreFailure &&
            index == topComments.length + commentsDoc.length) {
          return Center(
            child: ElevatedButton(
              onPressed: () {
                context.read<CommentsBloc>().add(
                      CommentsEvent(
                        comments[0].data.comments.docs[0].comic,
                        CommentsStatus.loadingMore,
                        commentIndex,
                      ),
                    );
              },
              child: const Text('重新加载'),
            ),
          );
        }

        // 默认返回空容器
        return const SizedBox(height: 120);
      },
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
    List<Doc> uniqueDocs = commentsDoc.toSet().toList();

    // 按照 _id 排序
    uniqueDocs.sort((a, b) => b.id.compareTo(a.id));

    return uniqueDocs;
  }
}
