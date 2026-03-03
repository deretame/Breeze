import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/jm/jm_promote_list/jm_promote_list.dart';
import 'package:zephyr/page/jm/jm_promote_list/json/jm_promote_list_json.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_grid.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_info.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_mapper.dart';
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
  final ScrollController scrollController = ScrollController();
  int page = 0;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    super.dispose();
  }

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
                  context.read<JmPromoteListBloc>().add(
                    JmPromoteListEvent(id: widget.id),
                  );
                },
              );
            case JmPromoteListStatus.loadingMore:
            case JmPromoteListStatus.loadingMoreFailure:
            case JmPromoteListStatus.success:
              if (state.status == JmPromoteListStatus.success) {
                page = state.result.let(toInt);
              }
              return _commentItem(state);
          }
        },
      ),
    );
  }

  Widget _commentItem(JmPromoteListState state) {
    final list = _toSimplifyEntries(state.list);

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        ComicSimplifyEntrySliverGrid(
          entries: list,
          type: ComicEntryType.normal,
          refresh: () {},
        ),
        if (state.hasReachedMax)
          const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('没有更多了'),
              ),
            ),
          ),
        if (state.status == JmPromoteListStatus.loadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        if (state.status == JmPromoteListStatus.loadingMoreFailure)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  context.read<JmPromoteListBloc>().add(JmPromoteListEvent());
                },
              ),
            ),
          ),
      ],
    );
  }

  List<ComicSimplifyEntryInfo> _toSimplifyEntries(List<ListElement> comics) {
    return mapToJmComicSimplifyEntryInfoList(
      comics,
      title: (element) => element.name,
      id: (element) => element.id.toString(),
    );
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<JmPromoteListBloc>().add(
        JmPromoteListEvent(
          status: JmPromoteListStatus.loadingMore,
          id: widget.id,
          page: page + 1,
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
