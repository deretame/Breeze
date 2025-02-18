import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart';

import '../../../../main.dart';
import '../../../../mobx/int_select.dart';
import '../../../../mobx/string_select.dart';
import '../../../../widgets/comic_entry/comic_entry.dart';

class DownloadPage extends StatelessWidget {
  final SearchStatusStore searchStatusStore;
  final StringSelectStore stringSelectStore;
  final IntSelectStore indexStore;

  const DownloadPage({
    super.key,
    required this.searchStatusStore,
    required this.stringSelectStore,
    required this.indexStore,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) => UserDownloadBloc()..add(UserDownloadEvent(SearchEnterConst())),
      child: _DownloadPage(
        searchStatusStore: searchStatusStore,
        stringSelectStore: stringSelectStore,
        indexStore: indexStore,
      ),
    );
  }
}

class _DownloadPage extends StatefulWidget {
  final SearchStatusStore searchStatusStore;
  final StringSelectStore stringSelectStore;
  final IntSelectStore indexStore;

  const _DownloadPage({
    required this.searchStatusStore,
    required this.stringSelectStore,
    required this.indexStore,
  });

  @override
  State<_DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<_DownloadPage>
    with AutomaticKeepAliveClientMixin {
  SearchStatusStore get searchStatusStore => widget.searchStatusStore;

  StringSelectStore get stringSelectStore => widget.stringSelectStore;

  IntSelectStore get indexStore => widget.indexStore;

  int totalComicCount = 0;
  bool notice = false;

  @override
  void initState() {
    super.initState();
    eventBus.on<DownloadEvent>().listen((event) {
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
    return BlocBuilder<UserDownloadBloc, UserDownloadState>(
      builder: (context, state) {
        return RefreshIndicator(
          displacement: 60.0,
          onRefresh: () async {
            if (widget.indexStore.date == 2) {
              _refresh(searchStatusStore);
            }
          },
          child: _buildContent(state),
        );
      },
    );
  }

  Widget _buildContent(UserDownloadState state) {
    switch (state.status) {
      case UserDownloadStatus.initial:
        // stringSelectStore.setDate("");
        return const Center(child: CircularProgressIndicator());
      case UserDownloadStatus.failure:
        return _buildError(state);
      case UserDownloadStatus.success:
        return _buildList(state);
    }
  }

  Widget _buildError(UserDownloadState state) {
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

  Widget _buildList(UserDownloadState state) {
    totalComicCount = state.comics.length;

    if (notice == false) {
      if (widget.indexStore.date == 2) {
        eventBus.fire(DownloadEvent(EventType.showInfo));
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
          if (widget.indexStore.date == 2) {
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
            delegate: SliverChildBuilderDelegate((
              BuildContext context,
              int index,
            ) {
              // 如果索引等于状态的 comics.length，并且已经达到最大值
              if (index == state.comics.length) {
                return deletingDialog(
                  context,
                  () => _refresh(searchStatusStore),
                  DeleteType.download,
                );
              } else {
                return ComicEntryWidget(
                  comicEntryInfo: downloadConvertToComicEntryInfo(
                    state.comics[index],
                  ),
                  type: ComicEntryType.download,
                  refresh: () => _refresh(searchStatusStore),
                );
              }
            }, childCount: itemCount),
          ),
        ],
      ),
    );
  }

  void _refresh(SearchStatusStore searchStatusStore) {
    notice = false;
    // 使用原本输入参数进行重新搜索
    context.read<UserDownloadBloc>().add(
      UserDownloadEvent(
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
