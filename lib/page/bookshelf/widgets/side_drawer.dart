import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  SortType sortType = SortType.nullValue;
  int page = 0;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppBar(
                title: Text(indexStore.date == 0
                    ? "收藏筛选"
                    : indexStore.date == 1
                        ? "历史筛选"
                        : "下载筛选"),
                automaticallyImplyLeading: false, // 不显示默认的返回按钮
                actions: [
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context); // 关闭Drawer
                    },
                  ),
                ],
              ),
              Container(color: globalSetting.textColor, height: 1),
              SizedBox(height: 8), // 添加一些间距
              SizedBox(height: 8), // 添加一些间距
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0), // 添加左右间距
                child: favoriteFilter(),
              ),
              SizedBox(height: 8), // 添加一些间距
              if (indexStore.date == 0) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  // 添加左右间距
                  child: Row(
                    children: [
                      Text('跳页', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 8), // 添加一些间距
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number, // 设置键盘类型为数字
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly, // 只允许输入数字
                          ],
                          decoration: InputDecoration(hintText: '请输入页数'),
                          onSubmitted: (value) {
                            if (value.isEmpty) {
                              page = -1;
                            }
                            page = int.parse(value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Spacer(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  // 确保按钮水平居中且间距均匀
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _refresh();
                        Navigator.pop(context);
                      },
                      child: Text('刷新当前页面'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _onTap();
                        Navigator.pop(context);
                      },
                      child: Text('确定'),
                    ),
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
    return GestureDetector(
        onTap: () async {
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
        child: Text(
          '选择屏蔽分类',
          style: TextStyle(fontSize: 16, color: materialColorScheme.primary),
        ));
  }

  void _onTap() {
    if (indexStore.date == 0) {
      try {
        _categoriesShield;
        bikaSetting.setShieldCategoryMap(_categoriesShield);
      } catch (_) {}

      if (page != -1 && page != 0) {
        eventBus.fire(FavoriteEvent(EventType.pageSkip, sortType, page));
      } else {
        eventBus.fire(FavoriteEvent(EventType.updateShield, sortType, page));
      }
      favoriteStore.sort = SortType.dd.toString().split('.').last;
    }
  }

  void _refresh() {
    if (indexStore.date == 0) {
      eventBus.fire(FavoriteEvent(EventType.refresh, sortType, 0));
    }
  }
}
