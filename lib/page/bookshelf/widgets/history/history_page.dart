import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart';

import '../../../../main.dart';
import '../../../../mobx/int_select.dart';
import '../../../../mobx/string_select.dart';
import '../../../../widgets/comic_entry/comic_entry.dart';

class HistoryPage extends StatelessWidget {
  final SearchStatusStore searchStatusStore;
  final StringSelectStore stringSelectStore;
  final IntSelectStore indexStore;

  const HistoryPage({
    super.key,
    required this.searchStatusStore,
    required this.stringSelectStore,
    required this.indexStore,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          UserHistoryBloc()..add(UserHistoryEvent(SearchEnterConst())),
      child: _HistoryPage(
        searchStatusStore: searchStatusStore,
        stringSelectStore: stringSelectStore,
        indexStore: indexStore,
      ),
    );
  }
}

class _HistoryPage extends StatefulWidget {
  final SearchStatusStore searchStatusStore;
  final StringSelectStore stringSelectStore;
  final IntSelectStore indexStore;

  const _HistoryPage({
    required this.searchStatusStore,
    required this.stringSelectStore,
    required this.indexStore,
  });

  @override
  State<_HistoryPage> createState() => __HistoryPageState();
}

class __HistoryPageState extends State<_HistoryPage>
    with AutomaticKeepAliveClientMixin {
  SearchStatusStore get searchStatusStore => widget.searchStatusStore;

  StringSelectStore get stringSelectStore => widget.stringSelectStore;

  IntSelectStore get indexStore => widget.indexStore;

  int totalComicCount = 0;
  bool notice = false;

  @override
  void initState() {
    super.initState();
    eventBus.on<HistoryEvent>().listen((event) {
      if (event.type == EventType.showInfo) {
        stringSelectStore.setDate(totalComicCount.toString());
      } else if (event.type == EventType.refresh) {
        _refresh(searchStatusStore);
      }
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<UserHistoryBloc, UserHistoryState>(
      builder: (context, state) {
        return RefreshIndicator(
          displacement: 60.0,
          onRefresh: () async {
            if (widget.indexStore.date == 1) {
              _refresh(searchStatusStore);
            }
          },
          child: _buildContent(state),
        );
      },
    );
  }

  Widget _buildContent(UserHistoryState state) {
    switch (state.status) {
      case UserHistoryStatus.initial:
        // stringSelectStore.setDate("");
        return const Center(child: CircularProgressIndicator());
      case UserHistoryStatus.failure:
        return _buildError(state);
      case UserHistoryStatus.success:
        return _buildList(state);
    }
  }

  Widget _buildError(UserHistoryState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${state.result.toString()}\n加载失败',
            style: TextStyle(fontSize: 20),
          ),
          SizedBox(height: 10), // 添加间距
          ElevatedButton(
            onPressed: () => _refresh(searchStatusStore),
            child: Text('点击重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildList(UserHistoryState state) {
    totalComicCount = state.comics.length;

    if (notice == false) {
      if (widget.indexStore.date == 1) {
        eventBus.fire(HistoryEvent(EventType.showInfo));
        notice = true;
      }
    }

    if (state.comics.isEmpty) {
      return Center(
        child: Column(
          children: [
            Spacer(),
            const Text('啥都没有', style: TextStyle(fontSize: 20.0)),
            SizedBox(height: 10), // 添加间距
            ElevatedButton(
              onPressed: () => _refresh(searchStatusStore),
              child: const Text('刷新'),
            ),
            Spacer(),
          ],
        ),
      );
    }

    int itemCount = state.comics.length + 1;

    debugPrint(itemCount.toString());

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          if (widget.indexStore.date == 1) {
            stringSelectStore.setDate(state.comics.length.toString());
          }
        }
        return false;
      },
      child: CustomScrollView(
        slivers: [
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                // 如果索引等于状态的 comics.length，并且已经达到最大值
                if (index == state.comics.length) {
                  return deletingDialog(
                    context,
                    () => _refresh(searchStatusStore),
                    DeleteType.history,
                  );
                } else {
                  return ComicEntryWidget(
                    comicEntryInfo: convertToComicEntryInfo(
                      state.comics[index],
                    ),
                    type: ComicEntryType.history,
                    refresh: () => _refresh(searchStatusStore),
                  );
                }
              },
              childCount: itemCount,
            ),
          ),
        ],
      ),
    );
  }

  void _refresh(SearchStatusStore searchStatusStore) {
    notice = false;
    // 使用原本输入参数进行重新搜索
    context.read<UserHistoryBloc>().add(
          UserHistoryEvent(
            SearchEnterConst(
              keyword: searchStatusStore.keyword,
              sort: searchStatusStore.sort,
              categories: searchStatusStore.categories,
              refresh: Uuid().v4(), //传入一个不一样的值，来强行刷新
            ),
          ),
        );
  }
}
