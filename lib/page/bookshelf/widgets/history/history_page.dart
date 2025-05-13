import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/config/global/global.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart';

import '../../../../main.dart';
import '../../../../mobx/int_select.dart';
import '../../../../mobx/string_select.dart';
import '../../../../object_box/model.dart';
import '../../../../type/enum.dart';
import '../../../../widgets/comic_entry/comic_entry.dart';
import '../../../../widgets/comic_simplify_entry/comic_simplify_entry.dart';
import '../../../../widgets/comic_simplify_entry/comic_simplify_entry_info.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) => UserHistoryBloc()..add(UserHistoryEvent(SearchEnterConst())),
      child: _HistoryPage(),
    );
  }
}

class _HistoryPage extends StatefulWidget {
  const _HistoryPage();

  @override
  State<_HistoryPage> createState() => __HistoryPageState();
}

class __HistoryPageState extends State<_HistoryPage>
    with AutomaticKeepAliveClientMixin {
  SearchStatusStore get searchStatusStore => bookshelfStore.historyStore;

  StringSelectStore get stringSelectStore => bookshelfStore.stringSelectStore;

  IntSelectStore get indexStore => bookshelfStore.indexStore;

  int totalComicCount = 0;
  bool notice = false;

  ScrollController get _scrollController => scrollControllers['history']!;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    eventBus.on<HistoryEvent>().listen((event) {
      if (event.type == EventType.showInfo) {
        stringSelectStore.setDate(totalComicCount.toString());
      } else if (event.type == EventType.refresh) {
        _refresh(searchStatusStore);
      }
    });
  }

  // 滚动监听方法
  void _scrollListener() {
    if (bookshelfStore.indexStore.date == 1) {
      stringSelectStore.setDate(totalComicCount.toString());
    }
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
            if (bookshelfStore.indexStore.date == 1) {
              _refresh(bookshelfStore.historyStore);
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
          SizedBox(height: 10),
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

    _showNoticeIfNeeded();

    if (state.comics.isEmpty) {
      return _buildEmptyState();
    }

    return bikaSetting.brevity
        ? _buildBrevityList(state)
        : _buildDetailedList(state);
  }

  // 显示通知（如果条件满足）
  void _showNoticeIfNeeded() {
    if (!notice && bookshelfStore.indexStore.date == 1) {
      eventBus.fire(HistoryEvent(EventType.showInfo));
      notice = true;
    }
  }

  // 构建空状态UI
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const Spacer(),
          const Text('啥都没有', style: TextStyle(fontSize: 20.0)),
          const SizedBox(height: 10),
          IconButton(
            onPressed: () => _refresh(bookshelfStore.historyStore),
            icon: const Icon(Icons.refresh),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // 构建简洁模式列表
  Widget _buildBrevityList(UserHistoryState state) {
    final elementsRows = generateElements(
      _convertToEntryInfoList(state.comics),
    );

    return _buildCommonListView(
      itemCount: elementsRows.length + 1,
      itemBuilder:
          (context, index) => _buildListItem(
            context,
            index,
            elementsRows.length,
            () => _refresh(searchStatusStore),
            isBrevity: true,
            elementsRows: elementsRows,
          ),
    );
  }

  // 构建详细模式列表
  Widget _buildDetailedList(UserHistoryState state) {
    return _buildCommonListView(
      itemCount: state.comics.length + 1,
      itemBuilder:
          (context, index) => _buildListItem(
            context,
            index,
            state.comics.length,
            () => _refresh(searchStatusStore),
            isBrevity: false,
            comics: state.comics,
          ),
    );
  }

  // 公共列表构建方法
  ListView _buildCommonListView({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
  }) {
    return ListView.builder(
      itemExtent:
          bikaSetting.brevity
              ? screenWidth * 0.425
              : 180.0 + (screenHeight / 10) * 0.1,
      physics: const AlwaysScrollableScrollPhysics(),
      controller: _scrollController,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }

  // 构建单个列表项
  Widget _buildListItem(
    BuildContext context,
    int index,
    int dataLength,
    VoidCallback refreshCallback, {
    required bool isBrevity,
    List<List<ComicSimplifyEntryInfo>>? elementsRows,
    List<dynamic>? comics,
  }) {
    final temp = comics!.map((e) => e as BikaComicHistory).toList();

    if (index == dataLength) {
      return Column(
        children: [
          SizedBox(height: 10),
          IconButton(
            onPressed: refreshCallback,
            icon: const Icon(Icons.refresh),
          ),
          deletingDialog(context, refreshCallback, DeleteType.history),
        ],
      );
    }

    return isBrevity
        ? ComicSimplifyEntryRow(
          key: ValueKey(elementsRows![index].map((e) => e.id).join(',')),
          entries: elementsRows[index],
          type: ComicEntryType.history,
          refresh: refreshCallback,
        )
        : ComicEntryWidget(
          comicEntryInfo: convertToComicEntryInfo(temp[index]),
          type: ComicEntryType.history,
          refresh: refreshCallback,
        );
  }

  // 转换数据格式
  List<ComicSimplifyEntryInfo> _convertToEntryInfoList(List<dynamic> comics) {
    final temp = comics.map((e) => e as BikaComicHistory).toList();

    return temp
        .map(
          (element) => ComicSimplifyEntryInfo(
            title: element.title,
            id: element.comicId,
            fileServer: element.thumbFileServer,
            path: element.thumbPath,
            pictureType: "cover",
            from: "bika",
          ),
        )
        .toList();
  }

  void _refresh(SearchStatusStore searchStatusStore) {
    _scrollController.animateTo(
      0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    notice = false;
    eventBus.fire(HistoryEvent(EventType.showInfo));
    context.read<UserHistoryBloc>().add(
      UserHistoryEvent(
        SearchEnterConst(
          keyword: searchStatusStore.keyword,
          sort: searchStatusStore.sort,
          categories: searchStatusStore.categories,
          refresh: Uuid().v4(),
        ),
      ),
    );
  }
}
