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
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              AutoRouter.of(context).push(
                SearchResultRoute(
                  searchEnterConst: SearchEnterConst(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
