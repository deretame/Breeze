import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/jm_search_result/jm_search_result.dart';

import '../../search_result/widgets/bottom_loader.dart';

@RoutePage()
class JmSearchResultPage extends StatelessWidget {
  final JmSearchResultEvent event;

  const JmSearchResultPage({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => JmSearchResultBloc()..add(event),
      child: _JmSearchResultPage(event: event),
    );
  }
}

class _JmSearchResultPage extends StatefulWidget {
  final JmSearchResultEvent event;

  const _JmSearchResultPage({required this.event});

  @override
  State<StatefulWidget> createState() => _JmSearchResultPageState();
}

class _JmSearchResultPageState extends State<_JmSearchResultPage> {
  late JmSearchResultEvent event;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    event = widget.event;
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Search Result')),
      body: BlocBuilder<JmSearchResultBloc, JmSearchResultState>(
        builder: (context, state) {
          switch (state.status) {
            case JmSearchResultStatus.initial:
              return const Center(child: CircularProgressIndicator());
            case JmSearchResultStatus.failure:
              return _failureWidget(state);
            case JmSearchResultStatus.success:
            case JmSearchResultStatus.loadingMoreFailure:
            case JmSearchResultStatus.loadingMore:
              return _buildList(state);
          }
        },
      ),
    );
  }

  Widget _buildList(JmSearchResultState state) {
    logger.d(state.status);
    int length =
        state.jmSearchResults!.length +
        (state.hasReachedMax ? 1 : 0) +
        (state.status == JmSearchResultStatus.loadingMore ? 1 : 0) +
        (state.status == JmSearchResultStatus.loadingMoreFailure ? 1 : 0);

    return ListView.builder(
      itemCount: length,
      itemBuilder: (context, index) {
        switch (index) {
          case _ when (index != length - 1):
            return _buildItem(state.jmSearchResults![index]);
          case _ when (state.hasReachedMax):
            return _maxReachedWidget();
          case _ when (state.status == JmSearchResultStatus.loadingMore):
            return Center(child: BottomLoader());
          case _ when (state.status == JmSearchResultStatus.loadingMoreFailure):
            return _loadingMoreFailureWidget();
          default:
            return SizedBox.shrink();
        }
      },
      controller: _scrollController,
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
          onPressed: _fetchSearchResult,
          child: const Text('点击重试'),
        ),
      ],
    ),
  );

  Widget _buildItem(Content item) => ListTile(title: Text(item.name));

  Widget _failureWidget(JmSearchResultState state) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${state.result.toString()}\n加载失败',
          style: TextStyle(fontSize: 20),
        ),
        SizedBox(height: 10), // 添加间距
        ElevatedButton(
          onPressed: () => context.read<JmSearchResultBloc>().add(event),
          child: Text('点击重试'),
        ),
      ],
    ),
  );

  void _fetchSearchResult() => context.read<JmSearchResultBloc>().add(
    event.copyWith(status: JmSearchResultStatus.loadingMore),
  );

  void _onScroll() {
    if (_isBottom) {
      _fetchSearchResult();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}
