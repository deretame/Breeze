import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/page/search_result/models/search_enter.dart';

import '../../../util/router/router.gr.dart';

@RoutePage()
class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('搜索本子'),
      ),
      body: Stack(
        children: [
          // 其他内容可以放在这里
          // Center(child: Text('主内容')),
          Positioned(
            bottom: 80, // 调整这个值以设置 FloatingActionButton 距离底部的距离
            right: 16,
            child: FloatingActionButton(
              child: const Icon(Icons.search),
              onPressed: () {
                AutoRouter.of(context).push(
                  SearchResultRoute(
                    searchEnterConst: SearchEnterConst(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
