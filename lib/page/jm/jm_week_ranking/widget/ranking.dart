import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/page/jm/jm_week_ranking/bloc/week_ranking_bloc.dart';
import 'package:zephyr/page/search_result/widgets/bottom_loader.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_info.dart';
import 'package:zephyr/widgets/error_view.dart';

class RankingWidget extends StatelessWidget {
  final int week;
  final String tag;

  const RankingWidget({super.key, required this.week, required this.tag});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) =>
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

    var list = state.list
        .map((item) {
          return ComicSimplifyEntryInfo(
            title: item.name,
            id: item.id,
            fileServer: getJmCoverUrl(item.id),
            path: "${item.id}.jpg",
            pictureType: 'cover',
            from: 'jm',
          );
        })
        .toList()
        .let(generateElements);

    var length = _calculateItemCount(state, list.length);

    return ListView.builder(
      itemCount: length,
      itemBuilder: (context, index) {
        switch (index) {
          case _ when (index < list.length):
            var key = list[index].map((item) => item.id).toList().toString();
            return ComicSimplifyEntryRow(
              key: ValueKey(key),
              entries: list[index],
              type: ComicEntryType.normal,
            );
          case _ when (state.hasReachedMax):
            return _maxReachedWidget();
          case _ when (state.status == JmRankingStatus.loadingMore):
            return Center(child: BottomLoader());
          case _ when (state.status == JmRankingStatus.loadingMoreFailure):
            return _loadingMoreFailureWidget();
          default:
            return SizedBox.shrink();
        }
      },
      controller: scrollController,
    );
  }

  Widget _maxReachedWidget() => const Center(
    child: Padding(
      padding: EdgeInsets.all(30.0),
      child: Text('没有更多了', style: TextStyle(fontSize: 20.0)),
    ),
  );

  Widget _loadingMoreFailureWidget() => Center(
    child: Column(
      children: [
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed:
              () => context.read<WeekRankingBloc>().add(
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
  );

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

  int _calculateItemCount(WeekRankingState state, int dataLength) {
    var count = dataLength + 1;
    if (!state.hasReachedMax) count--;
    if (state.status == JmRankingStatus.loadingMore ||
        state.status == JmRankingStatus.loadingMoreFailure) {
      count++;
    }
    return count;
  }
}
