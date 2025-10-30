import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/config/bika/bika_setting.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart';

import '../../../../config/global/global.dart';
import '../../../../main.dart';
import '../../../../cubit/int_select.dart';
import '../../../../cubit/string_select.dart';
import '../../../../object_box/model.dart';
import '../../../../type/enum.dart';
import '../../../../widgets/comic_entry/comic_entry.dart';
import '../../../../widgets/comic_simplify_entry/comic_simplify_entry.dart';
import '../../../../widgets/comic_simplify_entry/comic_simplify_entry_info.dart';

class DownloadPage extends StatelessWidget {
  const DownloadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UserDownloadBloc()..add(UserDownloadEvent(SearchEnter())),
      child: const _DownloadPage(),
    );
  }
}

class _DownloadPage extends StatefulWidget {
  const _DownloadPage();

  @override
  State<_DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<_DownloadPage>
    with AutomaticKeepAliveClientMixin {
  int totalComicCount = 0;
  bool notice = false;

  ScrollController get _scrollController => scrollControllers['download']!;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    eventBus.on<DownloadEvent>().listen((event) {
      if (!mounted) return;

      if (event.type == EventType.showInfo) {
        context.read<StringSelectCubit>().setDate(totalComicCount.toString());
      } else if (event.type == EventType.refresh) {
        _refresh();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _scrollListener() {
    final currentTabIndex = context.read<IntSelectCubit>().state;
    if (currentTabIndex == 2) {
      context.read<StringSelectCubit>().setDate(totalComicCount.toString());
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final currentTabIndex = context.watch<IntSelectCubit>().state;

    return BlocListener<UserDownloadBloc, UserDownloadState>(
      listener: (context, state) {
        if (state.status == UserDownloadStatus.success) {
          totalComicCount = state.comics.length;

          final tabIndex = context.read<IntSelectCubit>().state;
          if (tabIndex == 2) {
            context.read<StringSelectCubit>().setDate(
              totalComicCount.toString(),
            );
          }

          if (!notice && tabIndex == 1) {
            eventBus.fire(DownloadEvent(EventType.showInfo));
            notice = true;
          }
        }
      },
      child: BlocBuilder<UserDownloadBloc, UserDownloadState>(
        builder: (context, state) {
          return RefreshIndicator(
            displacement: 60.0,
            onRefresh: () async {
              if (currentTabIndex == 2) {
                _refresh(true);
              }
            },
            child: _buildContent(state),
          );
        },
      ),
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
          ElevatedButton(onPressed: () => _refresh(true), child: Text('点击重试')),
        ],
      ),
    );
  }

  Widget _buildList(UserDownloadState state) {
    final bikaSettingState = context.watch<BikaSettingCubit>().state;

    if (state.comics.isEmpty) {
      return _buildEmptyState();
    }

    // --- 9. 使用 context.watch 监听 TopBarCubit ---
    final topBarState = context.watch<TopBarCubit>().state;

    if (topBarState == 2) {
      // 使用 Cubit 状态
      return _buildBrevityList(state);
    }

    return bikaSettingState.brevity
        ? _buildBrevityList(state)
        : _buildDetailedList(state);
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
            onPressed: () => _refresh(),
            icon: const Icon(Icons.refresh),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // 构建简洁模式列表
  Widget _buildBrevityList(UserDownloadState state) {
    final elementsRows = generateResponsiveRows(
      context,
      _convertToEntryInfoList(state.comics),
    );

    return _buildCommonListView(
      itemCount: elementsRows.length + 1,
      itemBuilder: (context, index) => _buildListItem(
        context,
        index,
        elementsRows.length,
        () => _refresh(),
        isBrevity: true,
        elementsRows: elementsRows,
      ),
    );
  }

  // 构建详细模式列表
  Widget _buildDetailedList(UserDownloadState state) {
    return _buildCommonListView(
      itemCount: state.comics.length + 1,
      itemBuilder: (context, index) => _buildListItem(
        context,
        index,
        state.comics.length,
        () => _refresh(true),
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
    List<dynamic>? comics,
  }) {
    final topBarState = context.read<TopBarCubit>().state;

    if (index == dataLength) {
      return Center(
        child: Column(
          children: [
            SizedBox(height: 10),
            IconButton(
              onPressed: () => _refresh(true),
              icon: const Icon(Icons.refresh),
            ),
            deletingDialog(context, refreshCallback, DeleteType.download),
          ],
        ),
      );
    }

    if (topBarState == 1) {
      if (isBrevity) {
        return ComicSimplifyEntryRow(
          key: ValueKey(elementsRows![index].map((e) => e.id).join(',')),
          entries: elementsRows[index],
          type: ComicEntryType.download,
          refresh: refreshCallback,
        );
      } else {
        final temp = comics!.map((e) => e as BikaComicDownload).toList();
        return ComicEntryWidget(
          comicEntryInfo: downloadConvertToComicEntryInfo(temp[index]),
          type: ComicEntryType.download,
          refresh: refreshCallback,
        );
      }
    } else {
      return ComicSimplifyEntryRow(
        key: ValueKey(elementsRows![index].map((e) => e.id).join(',')),
        entries: elementsRows[index],
        type: ComicEntryType.download,
        refresh: refreshCallback,
      );
    }
  }

  // 转换数据格式
  List<ComicSimplifyEntryInfo> _convertToEntryInfoList(List<dynamic> comics) {
    final topBarState = context.read<TopBarCubit>().state;

    if (topBarState == 1) {
      final temp = comics.map((e) => e as BikaComicDownload).toList();

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
    } else {
      final temp = comics.map((e) => e as JmDownload).toList();

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
  }

  void _refresh([bool goToTop = false]) {
    if (_scrollController.hasClients && goToTop) {
      _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    notice = false;

    final searchStatus = context.read<DownloadCubit>().state;
    final topBarState = context.read<TopBarCubit>().state;

    context.read<UserDownloadBloc>().add(
      UserDownloadEvent(
        SearchEnter(
          keyword: searchStatus.keyword,
          sort: searchStatus.sort,
          categories: searchStatus.categories,
          refresh: Uuid().v4(),
        ),
      ),
    );
  }
}
