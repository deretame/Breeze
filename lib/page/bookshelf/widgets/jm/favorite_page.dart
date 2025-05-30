import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/config/global/global.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart';
import '../../../../main.dart';
import '../../../../mobx/int_select.dart';
import '../../../../mobx/string_select.dart';
import '../../../../object_box/model.dart';
import '../../../../type/enum.dart';
import '../../../../widgets/comic_simplify_entry/comic_simplify_entry.dart';
import '../../../../widgets/comic_simplify_entry/comic_simplify_entry_info.dart';

class JmFavoritePage extends StatelessWidget {
  const JmFavoritePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => JmFavouriteBloc()..add(JmFavouriteEvent()),
      child: _FavoritePage(),
    );
  }
}

class _FavoritePage extends StatefulWidget {
  const _FavoritePage();

  @override
  State<_FavoritePage> createState() => __FavoritePageState();
}

class __FavoritePageState extends State<_FavoritePage>
    with AutomaticKeepAliveClientMixin {
  SearchStatusStore get searchStatusStore => bookshelfStore.jmFavoriteStore;

  StringSelectStore get stringSelectStore => bookshelfStore.stringSelectStore;

  IntSelectStore get indexStore => bookshelfStore.indexStore;

  int totalComicCount = 0;
  bool notice = false;

  ScrollController get _scrollController => scrollControllers['jmFavorite']!;

  // 保存事件订阅，方便在dispose中取消
  late final StreamSubscription _eventSubscription;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    _eventSubscription = eventBus.on<JmFavoriteEvent>().listen((event) {
      if (!mounted) return; // 确保组件仍然挂载

      if (event.type == EventType.showInfo) {
        stringSelectStore.setDate(totalComicCount.toString());
      } else if (event.type == EventType.refresh) {
        _refresh(searchStatusStore, true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _eventSubscription.cancel(); // 取消事件订阅
    super.dispose();
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
    return BlocBuilder<JmFavouriteBloc, JmFavouriteState>(
      builder: (context, state) {
        return RefreshIndicator(
          displacement: 60.0,
          onRefresh: () async {
            if (bookshelfStore.indexStore.date == 0) {
              _refresh(bookshelfStore.jmFavoriteStore);
            }
          },
          child: _buildContent(state),
        );
      },
    );
  }

  Widget _buildContent(JmFavouriteState state) {
    switch (state.status) {
      case JmFavouriteStatus.initial:
        return const Center(child: CircularProgressIndicator());
      case JmFavouriteStatus.failure:
        return _buildError(state);
      case JmFavouriteStatus.success:
        return _buildList(state);
    }
  }

  Widget _buildError(JmFavouriteState state) {
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
            onPressed: () => _refresh(searchStatusStore, true),
            child: Text('点击重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildList(JmFavouriteState state) {
    totalComicCount = state.comics.length;

    _showNoticeIfNeeded();

    if (state.comics.isEmpty) {
      return _buildEmptyState();
    }

    return _buildBrevityList(state);
  }

  // 显示通知（如果条件满足）
  void _showNoticeIfNeeded() {
    if (!notice && bookshelfStore.indexStore.date == 1) {
      eventBus.fire(JmFavoriteEvent(EventType.showInfo));
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
            onPressed: () => _refresh(bookshelfStore.jmFavoriteStore, true),
            icon: const Icon(Icons.refresh),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // 构建简洁模式列表
  Widget _buildBrevityList(JmFavouriteState state) {
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
  }) {
    if (index == dataLength) {
      return Column(
        children: [
          SizedBox(height: 10),
          IconButton(
            onPressed: () => _refresh(searchStatusStore, true),
            icon: const Icon(Icons.refresh),
          ),
          deletingDialog(context, refreshCallback, DeleteType.history),
        ],
      );
    }

    return ComicSimplifyEntryRow(
      key: ValueKey(elementsRows![index].map((e) => e.id).join(',')),
      entries: elementsRows[index],
      type: ComicEntryType.history,
      refresh: refreshCallback,
    );
  }

  // 转换数据格式
  List<ComicSimplifyEntryInfo> _convertToEntryInfoList(List<dynamic> comics) {
    final temp = comics.map((e) => e as JmFavorite).toList();

    return temp
        .map(
          (element) => ComicSimplifyEntryInfo(
            title: element.name,
            id: element.comicId.toString(),
            fileServer: getJmCoverUrl(element.comicId.toString()),
            path: "${element.comicId}.jpg",
            pictureType: 'cover',
            from: 'jm',
          ),
        )
        .toList();
  }

  void _refresh(SearchStatusStore searchStatusStore, [bool refresh = false]) {
    if (_scrollController.hasClients && refresh) {
      _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    notice = false;
    eventBus.fire(JmFavoriteEvent(EventType.showInfo));
    context.read<JmFavouriteBloc>().add(
      JmFavouriteEvent(
        searchEnterConst: SearchEnter(
          keyword: searchStatusStore.keyword,
          sort: searchStatusStore.sort,
          categories: searchStatusStore.categories,
          refresh: Uuid().v4(),
        ),
      ),
    );
  }
}
