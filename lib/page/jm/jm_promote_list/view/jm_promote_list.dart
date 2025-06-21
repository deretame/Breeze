import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/jm/jm_promote_list/jm_promote_list.dart';
import 'package:zephyr/page/jm/jm_promote_list/json/jm_promote_list_json.dart';
import 'package:zephyr/widgets/error_view.dart';

@RoutePage()
class JmPromoteListPage extends StatelessWidget {
  final int id;
  final String name;

  const JmPromoteListPage({super.key, required this.id, required this.name});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => JmPromoteListBloc()..add(JmPromoteListEvent(id: id)),
      child: _JmPromoteListPage(id: id, name: name),
    );
  }
}

class _JmPromoteListPage extends StatefulWidget {
  final int id;
  final String name;

  const _JmPromoteListPage({required this.id, required this.name});

  @override
  State<_JmPromoteListPage> createState() => _JmPromoteListPageState();
}

class _JmPromoteListPageState extends State<_JmPromoteListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: BlocBuilder<JmPromoteListBloc, JmPromoteListState>(
        builder: (context, state) {
          switch (state.status) {
            case JmPromoteListStatus.initial:
              return const Center(child: CircularProgressIndicator());
            case JmPromoteListStatus.failure:
              return ErrorView(
                errorMessage: '${state.result.toString()}\n加载失败，请重试。',
                onRetry: () {
                  context.read<JmPromoteListBloc>().add(JmPromoteListEvent());
                },
              );
            case JmPromoteListStatus.loadingMore:
            case JmPromoteListStatus.loadingMoreFailure:
            case JmPromoteListStatus.success:
              return ListView.builder(
                itemCount: state.list.length,
                itemBuilder: (context, index) {
                  return _commentItem(state.list[index]);
                },
              );
          }
        },
      ),
    );
  }

  Widget _commentItem(ListElement element) {
    return ListTile(title: Text(element.toString()));
  }
}
