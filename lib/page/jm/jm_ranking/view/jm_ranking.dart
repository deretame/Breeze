import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class JmRankingPage extends StatefulWidget {
  final String type;

  const JmRankingPage({super.key, this.type = ''});

  @override
  State<JmRankingPage> createState() => _JmRankingPageState();
}

class _JmRankingPageState extends State<JmRankingPage>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  final List<String> tabs = [
    '最新a漫',
    '同人',
    '单本',
    '短篇',
    '其他类',
    '韩漫',
    'English Manga',
    'Cosplay',
    '3D',
    '禁漫汉化组',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          isScrollable: true,
          controller: _tabController,
          tabs: tabs.map((e) => Tab(text: e)).toList(),
        ),
        Expanded(
          // 使用 .map() 方法将 tabs 列表（字符串列表）转换为 Widget 列表
          child: TabBarView(
            controller: _tabController,
            // 为每个 tab 创建一个简单的 Text Widget 来显示其内容
            children:
                tabs.map((String tab) {
                  // 你可以为每个 tab 返回任何你想要的 Widget
                  // 这里我们简单地在屏幕中央显示 tab 的名字
                  return Center(
                    child: Text(
                      tab,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }
}
