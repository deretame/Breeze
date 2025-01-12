import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/user_comments/user_comments.dart';

import '../../../widgets/error_view.dart';
import '../json/user_comments_json.dart';

@RoutePage()
class UserCommentsPage extends StatelessWidget {
  const UserCommentsPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UserCommentsBloc()
        ..add(UserCommentsEvent(status: UserCommentsStatus.initial, count: 1)),
      child: _UserCommentsPage(),
    );
  }
}

class _UserCommentsPage extends StatefulWidget {
  @override
  State<_UserCommentsPage> createState() => _UserCommentsPageState();
}

class _UserCommentsPageState extends State<_UserCommentsPage> {
  int _count = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        context.read<UserCommentsBloc>().add(UserCommentsEvent(
            status: UserCommentsStatus.loadingMore, count: _count));
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('评论'),
      ),
      body: BlocBuilder<UserCommentsBloc, UserCommentsState>(
          builder: (context, state) {
        switch (state.status) {
          case UserCommentsStatus.initial:
            return Center(
              child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: CircularProgressIndicator()),
            );
          case UserCommentsStatus.failure:
            return ErrorView(
              errorMessage: '${state.result.toString()}\n加载失败，请重试。',
              onRetry: () {
                context.read<UserCommentsBloc>().add(UserCommentsEvent(
                    status: UserCommentsStatus.initial, count: 1));
              },
            );
          case UserCommentsStatus.success:
          case UserCommentsStatus.loadingMore:
          case UserCommentsStatus.getMoreFailure:
            return _buildCommentList(state);
        }
      }),
    );
  }

  Widget _buildCommentList(UserCommentsState state) {
    _count = state.count;
    if (state.userCommentsJson!.isEmpty) {
      return Center(
        child: Text('啥都没有', style: TextStyle(fontSize: 20)),
      );
    }

    List<Doc> userComments = [];
    List<UserCommentsJson> userCommentsJson = state.userCommentsJson!;

    for (var userCommentJson in userCommentsJson) {
      for (var doc in userCommentJson.data.comments.docs) {
        userComments.add(doc);
      }
    }
    userComments.toSet().toList();

    return ListView.builder(
      itemCount: userComments.length +
          (state.status == UserCommentsStatus.loadingMore ? 1 : 0) +
          (state.status == UserCommentsStatus.getMoreFailure ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == userComments.length) {
          if (state.status == UserCommentsStatus.loadingMore) {
            return Center(
                child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: CircularProgressIndicator(),
            ));
          }

          if (state.status == UserCommentsStatus.getMoreFailure) {
            return Center(
                child: ElevatedButton(
              onPressed: () {
                context.read<UserCommentsBloc>().add(UserCommentsEvent(
                      status: UserCommentsStatus.loadingMore,
                      count: _count,
                    ));
              },
              child: const Text('重新加载'),
            ));
          }
        }

        return CommentsWidget(
          doc: userComments[index],
          index: userComments.length - index,
        );
      },
      controller: _scrollController,
    );
  }
}
