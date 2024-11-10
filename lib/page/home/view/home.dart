import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/home/bloc/get_category_bloc.dart';

import 'category_page.dart';

// 主页的搜索页面
class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (_) => GetCategoryBloc()..add(GetCategoryStarted()),
        child: const CategoryPage(),
      ),
    );
  }
}
