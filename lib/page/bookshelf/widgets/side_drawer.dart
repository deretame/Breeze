import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart';

import '../../../mobx/int_select.dart';

class SideDrawer extends StatefulWidget {
  final IntSelectStore indexStore;
  final SearchStatusStore favoriteStore;
  final SearchStatusStore historyStore;
  final SearchStatusStore downloadStore;

  const SideDrawer({
    super.key,
    required this.indexStore,
    required this.favoriteStore,
    required this.historyStore,
    required this.downloadStore,
  });

  @override
  State<SideDrawer> createState() => _SideDrawerState();
}

class _SideDrawerState extends State<SideDrawer> {
  IntSelectStore get indexStore => widget.indexStore;

  SearchStatusStore get favoriteStore => widget.favoriteStore;

  SearchStatusStore get historyStore => widget.historyStore;

  SearchStatusStore get downloadStore => widget.downloadStore;

  late Map<String, bool> _categoriesShield;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Observer(
        builder: (context) {
          return Column(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    indexStore.date == 0
                        ? "收藏筛选"
                        : indexStore.date == 1
                            ? "历史筛选"
                            : "下载筛选",
                    style: TextStyle(fontSize: 24),
                  ),
                ),
              ),
              Container(color: globalSetting.textColor, height: 1),
              SizedBox(height: 16.0),
              if (indexStore.date == 0) favoriteFilter(),
              Spacer(),
              Padding(
                padding: const EdgeInsets.all(16.0), // 添加左右间距
                child: Row(
                  children: [
                    SizedBox(width: 8.0), // 左侧空间
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('返回'),
                      ),
                    ),
                    SizedBox(width: 16.0), // 按钮之间的空间
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          bikaSetting.setShieldCategoryMap(_categoriesShield);
                          eventBus.fire(FavoriteEvent());
                          Navigator.pop(context);
                        },
                        child: Text('确定'),
                      ),
                    ),
                    SizedBox(width: 8.0), // 右侧空间
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget favoriteFilter() {
    return TextButton(
        onPressed: () async {
          late var oldCategoriesMap =
              Map.of(bikaSetting.getShieldCategoryMap());
          final categoriesShield = await showShieldCategoryDialog(context);

          if (categoriesShield == null) {
            return;
          }

          if (oldCategoriesMap == categoriesShield) {
            return;
          }

          _categoriesShield = Map.of(categoriesShield);
        },
        child: Text('更新屏蔽分类'));
  }
}
