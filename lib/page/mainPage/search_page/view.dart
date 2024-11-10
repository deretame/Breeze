import 'package:flutter/material.dart';
import 'package:zephyr/page/search_result/models/search_enter.dart';

import '../../../util/router.dart';

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
              navigateTo(context, '/searchResult', extra: SearchEnterConst());
            },
          ),
        ],
      ),
    );
  }
}
