import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/jm/jm_search_result/jm_search_result.dart';
import 'package:zephyr/type/pipe.dart';

import '../../../../network/http/picture/picture.dart';
import '../../../../type/enum.dart';
import '../../../../util/router/router.gr.dart';
import '../../../../widgets/comic_simplify_entry/comic_simplify_entry.dart';
import '../../../../widgets/comic_simplify_entry/comic_simplify_entry_info.dart';
import '../../../search_result/widgets/bottom_loader.dart';

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
  String totalCount = '0';

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
      appBar: BikaSearchBar(event: event, searchCallback: _searchCallback),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Column(
              children: <Widget>[
                SizedBox(height: 35), // 为顶部阴影容器预留空间
                Expanded(child: _bloc()),
              ],
            ),
          ),
          // 这里是操作栏
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 35,
              decoration: BoxDecoration(
                color: globalSetting.backgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: materialColorScheme.secondaryFixedDim,
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  SizedBox(width: 5),
                  SortWidget(
                    event: event,
                    sortCallback: (value) {
                      if (event != event.copyWith(sort: value)) {
                        setState(() => event = event.copyWith(sort: value));
                        _fetchSearchResult(
                          event.copyWith(status: JmSearchResultStatus.initial),
                        );
                      }
                    },
                  ),
                  SizedBox(width: 5),
                  InkWell(
                    onTap: () => showSearchHelp(context),
                    splashColor: Colors.transparent, // 可选：禁用涟漪效果
                    child: Padding(
                      padding: EdgeInsets.all(4), // 仅保留必要的小内边距
                      child: Icon(Icons.help_outline, size: 20),
                    ),
                  ),
                  Expanded(child: Container()),
                  Text(
                    totalCount != '0' ? '共 $totalCount 个结果' : '',
                    style: TextStyle(
                      color: globalSetting.textColor,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(width: 5),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bloc() => BlocBuilder<JmSearchResultBloc, JmSearchResultState>(
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
  );

  Widget _buildList(JmSearchResultState state) {
    if (totalCount != state.result && event.keyword.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          int.parse(state.result);
          setState(() => totalCount = state.result);
        } catch (_) {}
      });
    }

    if (event.keyword.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(state.result, style: TextStyle(fontSize: 20.0)),
        ),
      );
    }

    if (state.jmSearchResults!.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('啥都没有', style: TextStyle(fontSize: 20.0)),
        ),
      );
    }

    // logger.d(state.status);

    var list = state.jmSearchResults!
        .map((item) {
          return ComicSimplifyEntryInfo(
            title: item.name,
            id: item.id,
            fileServer: getJmCoverUrl(item.id),
            path: ".jpg",
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
          case _ when (index != length - 1):
            var key = list[index].map((item) => item.id).toList().toString();
            return ComicSimplifyEntryRow(
              key: ValueKey(key),
              entries: list[index],
              type: ComicEntryType.normal,
            );
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
          onPressed:
              () => _fetchSearchResult(
                event.copyWith(status: JmSearchResultStatus.loadingMore),
              ),
          child: const Text('点击重试'),
        ),
      ],
    ),
  );

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

  void _searchCallback(value) {
    try {
      // 因为jm有搜id直接跳转到漫画详情的功能，从100开始的id会直接跳转到漫画详情
      final keyword = value as String;

      if (int.parse(keyword) >= 100) {
        // 说明应该搜的是漫画id，直接跳转到详情页
        context.pushRoute(
          JmComicInfoRoute(comicId: keyword, type: ComicEntryType.normal),
        );
        return;
      }
    } catch (_) {}
    if (event != event.copyWith(keyword: value)) {
      setState(() => event = event.copyWith(keyword: value));
      _fetchSearchResult(event.copyWith(status: JmSearchResultStatus.initial));
    }
  }

  void _fetchSearchResult(JmSearchResultEvent event) =>
      context.read<JmSearchResultBloc>().add(event);

  void _onScroll() {
    if (_isBottom) {
      _fetchSearchResult(
        event.copyWith(status: JmSearchResultStatus.loadingMore),
      );
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  int _calculateItemCount(JmSearchResultState state, int dataLength) {
    var count = dataLength + 1;
    if (!state.hasReachedMax) count--;
    if (state.status == JmSearchResultStatus.loadingMore ||
        state.status == JmSearchResultStatus.loadingMoreFailure) {
      count++;
    }
    return count;
  }
}
