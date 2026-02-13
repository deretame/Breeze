import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/jm/jm_setting.dart';
import 'package:zephyr/cubit/list_select.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/page/bookshelf/bloc/jm/cloud_favourite/bloc/jm_cloud_favourite_bloc.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart';
import 'package:zephyr/page/bookshelf/json/jm_cloud_favorite/jm_cloud_favorite_json.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_info.dart';

class JmCloudFavoritePage extends StatelessWidget {
  const JmCloudFavoritePage({super.key});

  @override
  Widget build(BuildContext context) {
    final jmSettingState = context.watch<JmSettingCubit>().state;

    if (jmSettingState.loginStatus == LoginStatus.loggingIn) {
      return const Center(child: CircularProgressIndicator());
    } else if (jmSettingState.loginStatus == LoginStatus.logout) {
      return Center(
        child: TextButton(
          onPressed: () {
            context.pushRoute(LoginRoute(from: From.jm));
          },
          child: Text("前往登录"),
        ),
      );
    } else {
      return BlocProvider(
        create: (_) => JmCloudFavouriteBloc()..add(JmCloudFavouriteEvent()),
        child: const _JmCloudFavoritePage(),
      );
    }
  }
}

class _JmCloudFavoritePage extends StatefulWidget {
  const _JmCloudFavoritePage();

  @override
  State<_JmCloudFavoritePage> createState() => _JmCloudFavoritePageState();
}

class _JmCloudFavoritePageState extends State<_JmCloudFavoritePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ScrollController _scrollController = ScrollController();
  var jmCloudFavouriState = JmCloudFavouriteState();
  late final StreamSubscription _eventSubscription;
  int totalComicCount = 0;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);
    _eventSubscription = eventBus.on<JmCloudFavoriteEvent>().listen((event) {
      if (!mounted) return;

      if (event.type == EventType.showInfo) {
        context.read<StringSelectCubit>().setDate(totalComicCount.toString());
      } else if (event.type == EventType.refresh) {
        _refresh(goTop: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _eventSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<JmCloudFavouriteBloc, JmCloudFavouriteState>(
      builder: (context, state) {
        return _buildContent(state);
      },
    );
  }

  Widget _buildContent(JmCloudFavouriteState state) {
    jmCloudFavouriState = state;
    switch (state.status) {
      case JmCloudFavouriteStatus.initial:
        return const Center(child: CircularProgressIndicator());
      case JmCloudFavouriteStatus.failure:
        return _buildError(state);
      case JmCloudFavouriteStatus.loadingMore:
      case JmCloudFavouriteStatus.loadMoreFail:
      case JmCloudFavouriteStatus.success:
        return _buildList(state);
    }
  }

  Widget _buildError(JmCloudFavouriteState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${state.result.toString()}\n加载失败',
            style: TextStyle(fontSize: 20),
          ),
          SizedBox(height: 10),
          ElevatedButton(onPressed: () => _refresh(), child: Text('点击重试')),
        ],
      ),
    );
  }

  Widget _buildList(JmCloudFavouriteState state) {
    if (state.status == JmCloudFavouriteStatus.success && state.list.isEmpty) {
      return _buildEmptyState();
    } else {
      context.read<ListSelectCubit<FolderList>>().setList(state.folderList);
    }

    return _buildBrevityList(state);
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
  Widget _buildBrevityList(JmCloudFavouriteState state) {
    final elementsRows = generateResponsiveRows(
      context,
      _convertToEntryInfoList(state.list),
    );

    final itemCount = elementsRows.length + 1;

    return _buildCommonListView(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index < elementsRows.length) {
          return _buildListItem(
            context,
            index,
            itemCount,
            () => _refresh(),
            isBrevity: true,
            elementsRows: elementsRows,
          );
        }

        if (index == elementsRows.length) {
          if (state.status == JmCloudFavouriteStatus.loadingMore) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(),
              ),
            );
          } else if (state.status == JmCloudFavouriteStatus.loadMoreFail) {
            return _loadingMoreFailureWidget();
          } else if (!state.hasMore) {
            return Column(
              children: [
                const SizedBox(height: 10),
                IconButton(
                  onPressed: () => _refresh(goTop: true),
                  icon: const Icon(Icons.refresh),
                ),
                const Center(
                  child: Text('没有更多了', style: TextStyle(fontSize: 20.0)),
                ),
                const SizedBox(height: 10),
              ],
            );
          }
        }

        return SizedBox.shrink();
      },
    );
  }

  Widget _loadingMoreFailureWidget() => Center(
    child: Column(
      children: [
        const SizedBox(height: 10),
        ElevatedButton(onPressed: () => _loadMore(), child: const Text('点击重试')),
      ],
    ),
  );

  // 公共列表构建方法
  Widget _buildCommonListView({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
  }) {
    return RefreshIndicator(
      onRefresh: () async => _refresh(goTop: false),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _scrollController,
        itemCount: itemCount,
        itemBuilder: itemBuilder,
      ),
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
            onPressed: () => _refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      );
    }

    return ComicSimplifyEntryRow(
      key: ValueKey(elementsRows![index].map((e) => e.id).join(',')),
      entries: elementsRows[index],
      type: ComicEntryType.favorite,
      refresh: refreshCallback,
    );
  }

  // 转换数据格式
  List<ComicSimplifyEntryInfo> _convertToEntryInfoList(
    List<ListElement> comics,
  ) {
    return comics
        .map(
          (element) => ComicSimplifyEntryInfo(
            title: element.name,
            id: element.id.toString(),
            fileServer: getJmCoverUrl(element.id.toString()),
            path: "${element.id}.jpg",
            pictureType: PictureType.cover,
            from: From.jm,
          ),
        )
        .toList();
  }

  void _refresh({bool goTop = false}) {
    final searchStatus = context.read<JmCloudFavoriteCubit>().state;

    String order;
    if (searchStatus.sort != 'mr' && searchStatus.sort != 'mp') {
      order = 'mr';
    } else {
      order = searchStatus.sort;
    }

    String id;
    if (searchStatus.categories.isEmpty) {
      id = '';
    } else {
      id = searchStatus.categories.first;
    }

    context.read<JmCloudFavouriteBloc>().add(
      JmCloudFavouriteEvent(id: id, order: order),
    );

    if (goTop) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onScroll() {
    if (_isBottom) {
      _loadMore();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _loadMore() {
    context.read<JmCloudFavouriteBloc>().add(
      jmCloudFavouriState.event.copyWith(
        page: jmCloudFavouriState.event.page + 1,
        status: JmCloudFavouriteStatus.loadingMore,
      ),
    );
  }
}
