import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/config/bika/bika_setting.dart';
import 'package:zephyr/config/global/global.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/model/unified_comic_list_item.dart';
import 'package:zephyr/model/unified_comic_list_item_mapper.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart';

import '../../../../cubit/int_select.dart';
import '../../../../cubit/string_select.dart';
import '../../../../main.dart';
import '../../../../object_box/model.dart';
import '../../../../type/enum.dart';
import '../../../../widgets/comic_entry/comic_entry.dart';
import '../../../../widgets/comic_simplify_entry/comic_simplify_entry_grid.dart';
import '../../../../widgets/comic_simplify_entry/comic_simplify_entry_mapper.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final comicChoice = context.watch<GlobalSettingCubit>().state.comicChoice;

    return BlocProvider(
      create: (_) => UserHistoryBloc()
        ..add(
          UserHistoryEvent(
            SearchEnter().copyWith(refresh: Uuid().v4()),
            comicChoice,
          ),
        ),
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
  int totalComicCount = 0;
  bool notice = false;

  ScrollController get _scrollController => scrollControllers['history']!;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    eventBus.on<HistoryEvent>().listen((event) {
      logger.d("event: $event");
      if (!mounted) return;
      if (event.type == EventType.showInfo) {
        context.read<StringSelectCubit>().setDate(totalComicCount.toString());
      } else if (event.type == EventType.refresh) {
        _refresh(true);
      }
    });
  }

  // 滚动监听方法
  void _scrollListener() {
    if (context.read<IntSelectCubit>().state == 1) {
      context.read<StringSelectCubit>().setDate(totalComicCount.toString());
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final currentTabIndex = context.watch<IntSelectCubit>().state;

    return BlocListener<UserHistoryBloc, UserHistoryState>(
      listener: (context, state) {
        if (state.status == UserHistoryStatus.success) {
          totalComicCount = state.comics.length;

          if (context.read<IntSelectCubit>().state == 1) {
            context.read<StringSelectCubit>().setDate(
              totalComicCount.toString(),
            );
          }
        }
      },
      child: BlocBuilder<UserHistoryBloc, UserHistoryState>(
        builder: (context, state) {
          return RefreshIndicator(
            displacement: 60.0,
            onRefresh: () async {
              if (currentTabIndex == 1) {
                // 使用 watch 到的状态
                _refresh(); // _refresh 不再需要参数
              }
            },
            child: _buildContent(state),
          );
        },
      ),
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
          ElevatedButton(onPressed: () => _refresh(), child: Text('点击重试')),
        ],
      ),
    );
  }

  Widget _buildList(UserHistoryState state) {
    if (state.comics.isEmpty) {
      return _buildEmptyState();
    }

    final bikaSettingCubit = context.read<BikaSettingCubit>();

    return bikaSettingCubit.state.brevity
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
            onPressed: () => _refresh(true),
            icon: const Icon(Icons.refresh),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // 构建简洁模式列表
  Widget _buildBrevityList(UserHistoryState state) {
    final list = mapToUnifiedComicSimplifyEntryInfoList(
      _toUnifiedComics(state.comics),
    );

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: _scrollController,
      slivers: [
        ComicSimplifyEntrySliverGrid(
          entries: list,
          type: ComicEntryType.history,
          refresh: () => _refresh(),
        ),
        SliverToBoxAdapter(child: _buildFooter()),
      ],
    );
  }

  // 构建详细模式列表
  Widget _buildDetailedList(UserHistoryState state) {
    final comics = _toUnifiedComics(state.comics);
    return _buildCommonListView(
      itemCount: comics.length + 1,
      itemBuilder: (context, index) => _buildListItem(
        context,
        index,
        comics.length,
        () => _refresh(),
        comics: comics,
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 10),
          IconButton(
            onPressed: () => _refresh(true),
            icon: const Icon(Icons.refresh),
          ),
          deletingDialog(context, () => _refresh(true), DeleteType.history),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // 公共列表构建方法
  ListView _buildCommonListView({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
  }) {
    return ListView.builder(
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
    List<UnifiedComicListItem>? comics,
  }) {
    if (index == dataLength) {
      return _buildFooter();
    }
    if (comics == null || index >= comics.length) {
      return const SizedBox.shrink();
    }

    return ComicEntryWidget(
      comic: comics[index],
      type: ComicEntryType.history,
      refresh: refreshCallback,
    );
  }

  List<UnifiedComicListItem> _toUnifiedComics(List<dynamic> comics) {
    return comics
        .map((e) => e as UnifiedComicHistory)
        .map(unifiedComicFromUnifiedHistory)
        .toList();
  }

  void _refresh([bool goToTop = false, bool clean = false]) {
    final searchStatusCubit = context.read<HistoryCubit>();

    if (clean) searchStatusCubit.resetSearch();

    final searchStatus = context.read<HistoryCubit>().state;
    final comicChoice = context.read<GlobalSettingCubit>().state.comicChoice;

    logger.d(searchStatus.toString());

    context.read<UserHistoryBloc>().add(
      UserHistoryEvent(
        SearchEnter(
          keyword: searchStatus.keyword,
          sort: searchStatus.sort,
          categories: searchStatus.categories,
          refresh: Uuid().v4(),
        ),
        comicChoice,
      ),
    );

    Future.delayed(Duration.zero).then((_) {
      if (_scrollController.hasClients && goToTop) {
        _scrollController.animateTo(
          0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      eventBus.fire(HistoryEvent(EventType.showInfo, false));
    });
  }
}
