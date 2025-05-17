import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/jm/jm_comments/jm_comments.dart';
import 'package:zephyr/page/jm/jm_comments/json/comments_json.dart';
import 'package:zephyr/widgets/error_view.dart';

@RoutePage()
class JmCommentsPage extends StatelessWidget {
  final String comicId;
  final String comicTitle;

  const JmCommentsPage({
    super.key,
    required this.comicId,
    required this.comicTitle,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CommentsBloc()..add(CommentsEvent(comicId: comicId)),
      child: _JmCommentsPage(comicId: comicId, comicTitle: comicTitle),
    );
  }
}

class _JmCommentsPage extends StatefulWidget {
  final String comicId;
  final String comicTitle;

  const _JmCommentsPage({required this.comicId, required this.comicTitle});

  @override
  _JmCommentsPageState createState() => _JmCommentsPageState();
}

class _JmCommentsPageState extends State<_JmCommentsPage> {
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.comicTitle)),
      body: BlocBuilder<CommentsBloc, CommentsState>(
        builder: (context, state) {
          switch (state.status) {
            case CommentsStatus.initial:
              return const Center(child: CircularProgressIndicator());
            case CommentsStatus.failure:
              return _failureWidget(state);
            case CommentsStatus.success:
            case CommentsStatus.loadingMore:
            case CommentsStatus.loadingMoreFailure:
              return _successWidget(state);
          }
        },
      ),
    );
  }

  Widget _failureWidget(CommentsState state) {
    return ErrorView(
      errorMessage: '${state.result.toString()}\n加载失败，请重试。',
      onRetry: () {
        context.read<CommentsBloc>().add(
          CommentsEvent(comicId: widget.comicId),
        );
      },
    );
  }

  Widget _successWidget(CommentsState state) {
    var length =
        state.comments.length +
        (state.status == CommentsStatus.loadingMore ? 1 : 0) +
        (state.status == CommentsStatus.loadingMoreFailure ? 1 : 0);

    return ListView.builder(
      itemCount: length,
      itemBuilder: (context, index) {
        if (index == length - 1) {
          if (state.status == CommentsStatus.loadingMore) {
            return Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (state.status == CommentsStatus.loadingMoreFailure) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextButton(
                child: Text('加载失败，点击重试'),
                onPressed: () {
                  context.read<CommentsBloc>().add(
                    CommentsEvent(
                      comicId: widget.comicId,
                      status: CommentsStatus.loadingMore,
                    ),
                  );
                },
              ),
            );
          }

          if (state.hasReachedMax) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('没有更多评论了')),
            );
          }
        }

        return _commentItem(state.comments[index], index);
      },
      controller: scrollController,
    );
  }

  Widget _commentItem(ListElement element, int index) {
    return CommentsWidget(element: element);
  }

  void _fetchSearchResult(CommentsEvent event) =>
      context.read<CommentsBloc>().add(event);

  void _onScroll() {
    if (_isBottom) {
      logger.d('load more comments');
      _fetchSearchResult(
        CommentsEvent(
          comicId: widget.comicId,
          status: CommentsStatus.loadingMore,
        ),
      );
    }
  }

  bool get _isBottom {
    if (!scrollController.hasClients) return false;
    final maxScroll = scrollController.position.maxScrollExtent;
    final currentScroll = scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}
