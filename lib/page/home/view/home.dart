import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/bookshelf/widgets/top_tab_bar.dart';
import 'package:zephyr/page/home/category.dart';
import 'package:zephyr/page/jm/jm_promote/view/jm_promote.dart';

import '../../../config/global/global.dart';
import '../../../util/router/router.gr.dart';
import '../../jm/jm_search_result/bloc/jm_search_result_bloc.dart';
import '../../search_result/models/search_enter.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("首页"),
        flexibleSpace: Column(
          children: [
            SizedBox(height: statusBarHeight),
            const Spacer(),
            Center(
              child: TopTabBar(
                onValueChanged: (value) {
                  setState(() => _currentIndex = value);
                },
              ),
            ),
            const Spacer(),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return SimpleDialog(
                    children: [
                      // 第一个 Chip
                      SimpleDialogOption(
                        onPressed: () {
                          context.pop();
                          context.pushRoute(
                            SearchResultRoute(
                              searchEnter: SearchEnter.initial(),
                            ),
                          );
                        },
                        child: const Chip(
                          label: Text("哔咔漫画"),
                          backgroundColor: Colors.pink,
                          labelStyle: TextStyle(color: Colors.white),
                        ),
                      ),
                      // 第二个 Chip
                      SimpleDialogOption(
                        onPressed: () {
                          context.pop();
                          context.pushRoute(
                            JmSearchResultRoute(event: JmSearchResultEvent()),
                          );
                        },
                        child: const Chip(
                          label: Text("禁漫天堂"),
                          backgroundColor: Colors.orange,
                          labelStyle: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (_currentIndex == 1) {
            eventBus.fire(RefreshCategories());
          } else {
            // TODO：添加刷新禁漫界面的功能
          }
        },
        child:
            _currentIndex == 1
                ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  controller: scrollControllers['category']!,
                  children: const [KeywordPage(), CategoryWidget()],
                )
                : const JmPromotePage(),
      ),
    );
  }
}
