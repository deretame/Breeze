import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart';

import '../../../config/bika/bika_setting.dart';
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

  Map<String, bool> _categoriesShield = Map.of(bikaSetting.shieldCategoryMap);
  List<String> categories = [];
  SortType sortType = SortType.nullValue;
  int page = 0;
  String sort = 'dd';
  String keyword = '';

  @override
  void initState() {
    super.initState();
    eventBus.on<HistoryEvent>().listen((event) {
      if (event.type == EventType.showInfo) {
        if (indexStore.date == 1) {
          sort = historyStore.sort;
        } else if (indexStore.date == 2) {
          sort = downloadStore.sort;
        }
      }
    });
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
                title: Text(
                  indexStore.date == 0
                      ? "收藏筛选"
                      : indexStore.date == 1
                      ? "历史筛选"
                      : "下载筛选",
                ),
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
              SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _shieldCategory(),
              ),
              SizedBox(height: 16),
              if (indexStore.date == 0) historyPageSkip(),
              if (indexStore.date == 1) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _choiceCategory(historyStore),
                ),
                SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    sort = historyStore.sort;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: SortWidget(
                        searchStatusStore: historyStore,
                        onSortChanged: (value) {
                          sort = value;
                        },
                      ),
                    );
                  },
                ),
                keywordSearch(historyStore),
              ],
              if (indexStore.date == 2) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _choiceCategory(downloadStore),
                ),
                SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    sort = downloadStore.sort;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: SortWidget(
                        searchStatusStore: downloadStore,
                        onSortChanged: (value) {
                          sort = value;
                        },
                      ),
                    );
                  },
                ),
                keywordSearch(downloadStore),
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
                        Navigator.pop(context);
                      },
                      child: Text('取消'),
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

  Widget _shieldCategory() {
    return GestureDetector(
      onTap: () async {
        late var oldCategoriesMap = Map.of(bikaSetting.shieldCategoryMap);
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
        '屏蔽分类',
        style: TextStyle(fontSize: 16, color: materialColorScheme.primary),
      ),
    );
  }

  Widget _choiceCategory(SearchStatusStore store) {
    return GestureDetector(
      onTap: () async {
        categories = store.categories;
        Map<String, bool> oldCategoriesMap = Map.from(categoryMap);
        for (String category in store.categories) {
          if (oldCategoriesMap.containsKey(category)) {
            oldCategoriesMap[category] = true;
          }
        }

        final categoriesSelected = await showCategoryDialog(context, store);

        if (categoriesSelected == null) {
          return;
        }

        if (oldCategoriesMap == categoriesSelected) {
          return;
        }

        var temp =
            categoriesSelected.entries
                .where((entry) => entry.value == true)
                .map((entry) => entry.key)
                .toList();

        categories = temp;
      },
      child: Text(
        '选择分类',
        style: TextStyle(fontSize: 16, color: materialColorScheme.primary),
      ),
    );
  }

  void _onTap() {
    if (indexStore.date == 0) {
      bikaSetting.setShieldCategoryMap(_categoriesShield);

      if (page != -1 && page != 0) {
        eventBus.fire(FavoriteEvent(EventType.pageSkip, sortType, page));
      } else {
        eventBus.fire(FavoriteEvent(EventType.updateShield, sortType, page));
      }
      favoriteStore.sort = SortType.dd.toString().split('.').last;
    }

    if (indexStore.date == 1) {
      bikaSetting.setShieldCategoryMap(_categoriesShield);
      historyStore.setCategories(categories);
      historyStore.setSort(sort);
      historyStore.setKeyword(keyword);

      eventBus.fire(HistoryEvent(EventType.refresh));
    }

    if (indexStore.date == 2) {
      bikaSetting.setShieldCategoryMap(_categoriesShield);
      downloadStore.setCategories(categories);
      downloadStore.setSort(sort);
      downloadStore.setKeyword(keyword);

      eventBus.fire(DownloadEvent(EventType.refresh));
    }
  }

  Widget historyPageSkip() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: TextField(
          keyboardType: TextInputType.number, // 设置键盘类型为数字
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly, // 只允许输入数字
          ],
          decoration: InputDecoration(hintText: '跳页，请输入页数'),
          onSubmitted: (value) {
            if (value.isEmpty) {
              page = -1;
            }
            page = int.parse(value);
          },
        ),
      ),
    );
  }

  Widget keywordSearch(SearchStatusStore store) {
    final TextEditingController controller = TextEditingController(
      text: store.keyword,
    );

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: '搜索漫画，请输入关键字'),
          onSubmitted: (value) => keyword = value,
        ),
      ),
    );
  }
}
