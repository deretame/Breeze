import 'package:flutter/material.dart';
import 'package:zephyr/util/router.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          // backgroundColor: const Color(0xFFFBFBFB),
          // elevation: 0,
          title: const Text('搜索本子'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                navigateTo(context, '/search');
              },
            ),
          ],
          // titleSpacing: 0,
          automaticallyImplyLeading: false, // 去掉左侧的leading
        ),
        body: const Center());
  }
}
