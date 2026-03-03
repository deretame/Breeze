import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/jm/jm_week_ranking/bloc/week_ranking_bloc.dart';
import 'package:zephyr/page/search_result/widgets/bottom_loader.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_grid.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_mapper.dart';
import 'package:zephyr/widgets/error_view.dart';

class RankingWidget extends StatelessWidget {
  final int week;
  final String tag;

  const RankingWidget({super.key, required this.week, required this.tag});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          WeekRankingBloc()..add(WeekRankingEvent(date: week, type: tag)),
      child: _RankingWidget(tag: tag, week: week),
    );
  }
}

class _RankingWidget extends StatefulWidget {
  final String tag;
  final int week;

  const _RankingWidget({required this.tag, required this.week});

  @override
  State<_RankingWidget> createState() => _RankingWidgetState();
}

class _RankingWidgetState extends State<_RankingWidget>
    with AutomaticKeepAliveClientMixin {
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
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<WeekRankingBloc, WeekRankingState>(
      builder: (context, state) {
        switch (state.status) {
          case JmRankingStatus.initial:
            return const Center(child: CircularProgressIndicator());
          case JmRankingStatus.failure:
            return ErrorView(
              errorMessage: '${state.result.toString()}\n加载失败，请重试。',
              onRetry: () {
                context.read<WeekRankingBloc>().add(
                  WeekRankingEvent(date: widget.week, type: widget.tag),
                );
              },
            );
          case JmRankingStatus.loadingMore:
          case JmRankingStatus.loadingMoreFailure:
          case JmRankingStatus.success:
            if (state.status == JmRankingStatus.success) {
              page = state.result.let(toInt);
            }
            return _commentItem(state);
        }
      },
    );
  }

  Widget _commentItem(WeekRankingState state) {
    if (state.list.isEmpty && state.status == JmRankingStatus.success) {
      return const Center(
        child: Text('啥都没有', style: TextStyle(fontSize: 20.0)),
      );
    }

    final list = mapToJmComicSimplifyEntryInfoList(
      state.list,
      title: (item) => item.name,
      id: (item) => item.id,
    );

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        ComicSimplifyEntrySliverGrid(
          entries: list,
          type: ComicEntryType.normal,
        ),
        if (state.hasReachedMax)
          const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(30.0),
                child: Text('没有更多了', style: TextStyle(fontSize: 20.0)),
              ),
            ),
          ),
        if (state.status == JmRankingStatus.loadingMore)
          const SliverToBoxAdapter(child: Center(child: BottomLoader())),
        if (state.status == JmRankingStatus.loadingMoreFailure)
          SliverToBoxAdapter(
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => context.read<WeekRankingBloc>().add(
                      WeekRankingEvent(
                        date: widget.week,
                        page: page + 1,
                        type: widget.tag,
                        status: JmRankingStatus.loadingMore,
                      ),
                    ),
                    child: const Text('点击重试'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<WeekRankingBloc>().add(
        WeekRankingEvent(
          date: widget.week,
          page: page + 1,
          type: widget.tag,
          status: JmRankingStatus.loadingMore,
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
