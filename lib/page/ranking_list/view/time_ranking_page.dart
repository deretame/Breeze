import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/page/ranking_list/view/plugin_paged_comic_list_view.dart';
import 'package:zephyr/type/enum.dart';

const _jmRankingTypeMap = {
  '最新': 'new',
  '最多点赞': 'tf',
  '总排行': 'mv',
  '月排行': 'mv_m',
  '周排行': 'mv_w',
  '日排行': 'mv_t',
};

const _jmCategoryMap = {
  '最新a漫': '0',
  '同人': {
    '全部': 'doujin',
    '汉化': 'doujin_chinese',
    '日语': 'doujin_japanese',
    'CG图集': 'doujin_CG',
  },
  '单本': {
    '全部': 'single',
    '汉化': 'single_chinese',
    '日语': 'single_japanese',
    '青年漫': 'single_youth',
  },
  '短篇': {'全部': 'short', '汉化': 'short_chinese', '日语': 'short_japanese'},
  '其他类': {
    '全部': 'another',
    '其他漫画': 'another_other',
    '3D': 'another_3d',
    '角色扮演': 'another_cosplay',
  },
  '韩漫': {'全部': 'hanman', '汉化': 'hanman_chinese'},
  'English Manga': {
    '全部': 'meiman',
    'IRODORI': 'meiman_irodori',
    'FAKKU': 'meiman_fakku',
    '18scan': 'meiman_18scan',
    'Manhwa': 'meiman_manhwa',
    'Comic': 'meiman_comic',
    'Other': 'meiman_other',
  },
  'Cosplay': 'another_cosplay',
  '3D': '3D',
  '禁漫汉化组': '禁漫汉化组',
};

@RoutePage()
class TimeRankingPage extends StatefulWidget {
  final String? title;
  final String tag;

  const TimeRankingPage({super.key, required this.tag, this.title});

  @override
  State<TimeRankingPage> createState() => _TimeRankingPageState();
}

class _TimeRankingPageState extends State<TimeRankingPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final TabController _tabController;
  late final List<String> tabs;

  String get tag => widget.tag;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    tabs = _jmRankingTypeMap.keys.toList();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final body = Column(
      children: [
        TabBar(
          isScrollable: true,
          controller: _tabController,
          tabs: tabs.map((e) => Tab(text: e)).toList(),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: tabs.map((String tab) {
              if (_jmCategoryMap[tag] is Map<String, String>) {
                return _CategoryTabsView(
                  tag: tag,
                  time: _jmRankingTypeMap[tab]!,
                );
              }

              return PluginPagedComicListView(
                from: From.jm,
                fnPath: 'getRankingData',
                coreBuilder: (page) => {'page': page},
                externBuilder: (_) => {
                  'type': _jmCategoryMap[tag].toString(),
                  'order': _jmRankingTypeMap[tab]!,
                  'source': 'ranking',
                },
                itemMapper: (item) => item,
              );
            }).toList(),
          ),
        ),
      ],
    );

    if (widget.title != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title!)),
        body: body,
      );
    }

    return body;
  }
}

class _CategoryTabsView extends StatefulWidget {
  const _CategoryTabsView({required this.tag, required this.time});

  final String tag;
  final String time;

  @override
  State<_CategoryTabsView> createState() => _CategoryTabsViewState();
}

class _CategoryTabsViewState extends State<_CategoryTabsView>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final TabController _tabController;
  late final Map<String, String> categoryMap;
  late final List<String> tabs;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    categoryMap = _jmCategoryMap[widget.tag]! as Map<String, String>;
    tabs = categoryMap.keys.toList();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        TabBar(
          isScrollable: true,
          controller: _tabController,
          tabs: tabs.map((e) => Tab(text: e)).toList(),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: tabs.map((String tab) {
              return PluginPagedComicListView(
                from: From.jm,
                fnPath: 'getRankingData',
                coreBuilder: (page) => {'page': page},
                externBuilder: (_) => {
                  'type': categoryMap[tab]!,
                  'order': widget.time,
                  'source': 'ranking',
                },
                itemMapper: (item) => item,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
