import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/main.dart';

import '../bloc/get_category_bloc.dart';
import '../models/category.dart';
import '../widgets/category.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({
    super.key,
  });

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('主页'),
      ),
      body: BlocBuilder<GetCategoryBloc, GetCategoryState>(
        builder: (context, state) {
          switch (state.status) {
            case GetCategoryStatus.failure:
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(state.result!),
                    ElevatedButton(
                      onPressed: () {
                        context
                            .read<GetCategoryBloc>()
                            .add(GetCategoryStarted());
                      },
                      child: const Text('重新加载'),
                    ),
                  ],
                ),
              );
            case GetCategoryStatus.success:
              final Map<String, bool> shieldCategoryMap =
                  bikaSetting.shieldCategoryMap;

              List<HomeCategory> homeCategories = state.categories!
                  .where(
                      (category) => !(shieldCategoryMap[category.id] ?? false))
                  .toList();
              // 构建并返回组件
              var rows = buildCategoriesWidget(homeCategories);
              return SingleChildScrollView(
                child: Column(
                  children: [
                    ...rows,
                    SizedBox(
                      height: 50,
                    ),
                  ],
                ),
              );

            case GetCategoryStatus.initial:
              return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
