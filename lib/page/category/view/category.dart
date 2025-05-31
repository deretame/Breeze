import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/category/category.dart';

import '../../../config/global/global.dart';
import '../../../util/router/router.gr.dart';
import '../../jm/jm_search_result/bloc/jm_search_result_bloc.dart';
import '../../search_result/models/search_enter.dart';

@RoutePage()
class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("分类"),
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
          eventBus.fire(RefreshCategories());
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: scrollControllers['category']!,
          children: const [KeywordPage(), CategoryWidget()],
        ),
      ),
    );
  }
}
