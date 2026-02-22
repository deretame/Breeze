import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/config/global/global.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart';
import 'package:zephyr/util/debouncer.dart';

import '../../../../cubit/int_select.dart';
import '../../../../cubit/string_select.dart';
import '../../../../main.dart';
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
      child: const _FavoritePage(),
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
      if (!mounted) return;

      if (event.type == EventType.showInfo) {
        // --- 5. 使用 context.read 更新 Cubit ---
        context.read<StringSelectCubit>().setDate(totalComicCount.toString());
      } else if (event.type == EventType.refresh) {
        // --- 6. 调用重构后的 _refresh ---
        _refresh(true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _eventSubscription.cancel(); // 取消事件订阅
    super.dispose();
  }

  void _scrollListener() {
    if (context.read<IntSelectCubit>().state == 0) {
      context.read<StringSelectCubit>().setDate(totalComicCount.toString());
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // --- 8. 添加 BlocListener 来处理副作用 ---
    return BlocListener<JmFavouriteBloc, JmFavouriteState>(
      listener: (context, state) {
        if (state.status == JmFavouriteStatus.success) {
          totalComicCount = state.comics.length;

          if (context.read<IntSelectCubit>().state == 0) {
            context.read<StringSelectCubit>().setDate(
              totalComicCount.toString(),
            );
          }
        }
      },
      child: BlocBuilder<JmFavouriteBloc, JmFavouriteState>(
        builder: (context, state) {
          return RefreshIndicator(
            displacement: 60.0,
            onRefresh: () async {
              // --- 9. 使用 context.read 并调用新 _refresh ---
              if (context.read<IntSelectCubit>().state == 0) {
                _refresh(true); // 传入 goToTop
              }
            },
            child: _buildContent(state),
          );
        },
      ),
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
          ElevatedButton(onPressed: () => _refresh(true), child: Text('点击重试')),
        ],
      ),
    );
  }

  Widget _buildList(JmFavouriteState state) {
    totalComicCount = state.comics.length;

    if (state.comics.isEmpty) {
      return _buildEmptyState();
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
            onPressed: () => _refresh(true),
            icon: const Icon(Icons.refresh),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // 构建简洁模式列表
  Widget _buildBrevityList(JmFavouriteState state) {
    final list = _convertToEntryInfoList(state.comics);
    final maxExtent = isTabletWithOutContext() ? 200.0 : 150.0;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: _scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(10),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: maxExtent,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              return ComicSimplifyEntry(
                key: ValueKey(list[index].id),
                info: list[index],
                type: ComicEntryType.favorite,
              );
            }, childCount: list.length),
          ),
        ),
      ],
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
            pictureType: PictureType.cover,
            from: From.jm,
          ),
        )
        .toList();
  }

  void _refresh([bool goToTop = false]) {
    if (_scrollController.hasClients && goToTop) {
      _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    final searchStatus = context.read<JmFavoriteCubit>().state;

    context.read<JmFavouriteBloc>().add(
      JmFavouriteEvent(
        searchEnterConst: SearchEnter(
          keyword: searchStatus.keyword,
          sort: searchStatus.sort,
          categories: searchStatus.categories,
          refresh: Uuid().v4(),
        ),
      ),
    );
  }
}
