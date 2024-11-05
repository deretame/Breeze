import 'package:flutter/material.dart';

import '../../../type/search_enter.dart';
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
              navigateTo(context, '/search', extra: SearchEnter());
            },
          ),
        ],
      ),
    );
  }
}
