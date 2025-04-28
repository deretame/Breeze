import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/category/category.dart';

import '../../../config/global/global.dart';
import '../../../util/router/router.gr.dart';
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
            onPressed:
                () => AutoRouter.of(
                  context,
                ).push(SearchResultRoute(searchEnterConst: SearchEnterConst())),
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
          children: const [
            SizedBox(height: 10),
            KeywordPage(),
            CategoryWidget1(),
          ],
        ),
      ),
    );
  }
}
