import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/home/category.dart';

import '../../../main.dart';

class CategoryWidget extends StatelessWidget {
  const CategoryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetCategoryBloc()..add(GetCategoryStarted()),
      child: _CategoryPage(),
    );
  }
}

class _CategoryPage extends StatefulWidget {
  @override
  State<_CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<_CategoryPage> {
  @override
  void initState() {
    eventBus.on<RefreshCategories>().listen((event) {
      refreshCategories();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GetCategoryBloc, GetCategoryState>(
      builder: (context, state) {
        switch (state.status) {
          case GetCategoryStatus.failure:
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(state.result!),
                  ElevatedButton(
                    onPressed: () => refreshCategories(),
                    child: const Text('重新加载'),
                  ),
                ],
              ),
            );
          case GetCategoryStatus.success:
            final Map<String, bool> shieldHomePageCategoryMap =
                bikaSetting.shieldHomePageCategoriesMap;

            List<HomeCategory> homeCategories =
                state.categories!
                    .where(
                      (category) =>
                          !(shieldHomePageCategoryMap[category.title] ?? false),
                    )
                    .toList();
            // 构建并返回组件
            var rows = buildCategoriesWidget(homeCategories);
            return Column(children: [...rows]);

          case GetCategoryStatus.initial:
            return const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(child: CircularProgressIndicator()),
            );
        }
      },
    );
  }

  void refreshCategories() {
    context.read<GetCategoryBloc>().add(GetCategoryStarted());
  }
}
