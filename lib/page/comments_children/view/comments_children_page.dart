import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:zephyr/config/global.dart';
import 'package:zephyr/page/comments_children/comments_children.dart';

import '../../../main.dart';
import '../../../network/http/http_request.dart';
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
          case CommentsChildrenStatus.comment:
            return _CommentWidget(
              fatherDoc: fatherDoc,
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
            _writeCommentChildren(fatherDoc.id, text);
          }),
    );
  }

  Future<void> _writeCommentChildren(String comicId, String text) async {
    try {
      await writeCommentChildren(comicId, text);

      // 检查 State 是否仍然挂载
      if (!mounted) return;

      context.read<CommentsChildrenBloc>().add(
          CommentsChildrenEvent(comicId, CommentsChildrenStatus.comment, 1));
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
  final comments_json.Doc fatherDoc;
  final CommentsChildrenState state;

  const _CommentWidget({
    required this.fatherDoc,
    required this.state,
  });

  @override
  State<_CommentWidget> createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<_CommentWidget> {
  comments_json.Doc get fatherDoc => widget.fatherDoc;

  CommentsChildrenState get state => widget.state;

  List<CommentsChildrenJson> comments = [];

  List<Doc> commentsDoc = [];

  int commentIndex = 1;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
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
        }

        if (index == commentsDoc.length + 1 &&
            state.status == CommentsChildrenStatus.loadingMore) {
          return Padding(
            padding: const EdgeInsets.all(10),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (index == commentsDoc.length + 1 &&
            state.status == CommentsChildrenStatus.getMoreFailure) {
          return Center(
              child: ElevatedButton(
            onPressed: () {
              context.read<CommentsChildrenBloc>().add(CommentsChildrenEvent(
                    fatherDoc.id,
                    CommentsChildrenStatus.loadingMore,
                    commentIndex,
                  ));
            },
            child: const Text('重新加载'),
          ));
        }
        // 计算当前评论的索引
        int currentIndex = index - 1;
        return CommentsChildrenWidget(
          doc: commentsDoc[currentIndex],
          index: comments[0].data.comments.total - index + 1,
        );
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
    List<Doc> uniqueDocs = commentsDoc.toSet().toList();

    // 按照 _id 排序
    uniqueDocs.sort((a, b) => b.id.compareTo(a.id));

    return uniqueDocs;
  }

  Widget _divider() {
    return Container(
      width: screenHeight,
      height: 5,
      color: materialColorScheme.onInverseSurface,
    );
  }
}
