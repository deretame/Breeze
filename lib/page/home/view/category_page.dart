import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/util/router/router.gr.dart';

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
              if (state.result!.contains("1005") ||
                  state.result!.contains("401") ||
                  state.result!.contains("unauthorized") ||
                  bikaSetting.authorization == '') {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '登录状态无效，请重新登录',
                        style: TextStyle(fontSize: 20),
                      ),
                      SizedBox(height: 10), // 添加间距
                      ElevatedButton(
                        onPressed: () {
                          AutoRouter.of(context).push(LoginRoute());
                        },
                        child: Text('前往登录'),
                      ),
                    ],
                  ),
                );
              }
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
