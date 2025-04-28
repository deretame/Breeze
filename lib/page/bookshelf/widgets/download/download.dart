import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart';

import '../../../../config/global/global.dart';
import '../../../../main.dart';
import '../../../../mobx/int_select.dart';
import '../../../../mobx/string_select.dart';
import '../../../../object_box/model.dart';
import '../../../../widgets/comic_entry/comic_entry.dart';
import '../../../../widgets/comic_simplify_entry/comic_simplify_entry.dart';
import '../../../../widgets/comic_simplify_entry/comic_simplify_entry_info.dart';

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

  ScrollController get _scrollController => scrollControllers['download']!;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    eventBus.on<DownloadEvent>().listen((event) {
      if (event.type == EventType.showInfo) {
        stringSelectStore.setDate(totalComicCount.toString());
      } else if (event.type == EventType.refresh) {
        _refresh(searchStatusStore);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (widget.indexStore.date == 2) {
      stringSelectStore.setDate(totalComicCount.toString());
    }
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
          SizedBox(height: 10),
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
    if (!notice && widget.indexStore.date == 1) {
      eventBus.fire(DownloadEvent(EventType.showInfo));
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
            onPressed: () => _refresh(searchStatusStore),
            icon: const Icon(Icons.refresh),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // 构建简洁模式列表
  Widget _buildBrevityList(UserDownloadState state) {
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
  Widget _buildDetailedList(UserDownloadState state) {
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
      controller: scrollControllers['download']!,
      physics: const AlwaysScrollableScrollPhysics(),
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
    List<BikaComicDownload>? comics,
  }) {
    if (index == dataLength) {
      return Column(
        children: [
          SizedBox(height: 10),
          IconButton(
            onPressed: refreshCallback,
            icon: const Icon(Icons.refresh),
          ),
          deletingDialog(context, refreshCallback, DeleteType.download),
        ],
      );
    }

    return isBrevity
        ? ComicSimplifyEntryRow(
          key: ValueKey(elementsRows![index].map((e) => e.id).join(',')),
          entries: elementsRows[index],
          type: ComicEntryType.download,
          refresh: refreshCallback,
        )
        : ComicEntryWidget(
          comicEntryInfo: downloadConvertToComicEntryInfo(comics![index]),
          type: ComicEntryType.download,
          refresh: refreshCallback,
        );
  }

  // 转换数据格式
  List<ComicSimplifyEntryInfo> _convertToEntryInfoList(
    List<BikaComicDownload> comics,
  ) {
    return comics
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
    eventBus.fire(DownloadEvent(EventType.showInfo));
    context.read<UserDownloadBloc>().add(
      UserDownloadEvent(
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
