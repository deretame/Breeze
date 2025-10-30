import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/settings_hive_utils.dart';

import '../../../config/bika/bika_setting.dart';
import '../../../cubit/int_select.dart';

class SideDrawer extends StatefulWidget {
  const SideDrawer({super.key});

  @override
  State<SideDrawer> createState() => _SideDrawerState();
}

class _SideDrawerState extends State<SideDrawer> {
  Map<String, bool> _categoriesShield = Map.of(
    SettingsHiveUtils.bikaShieldCategoryMap,
  );
  List<String> categories = [];
  SortType sortType = SortType.nullValue;
  int page = 0;
  String sort = 'dd';
  String keyword = '';

  @override
  void initState() {
    super.initState();
    eventBus.on<HistoryEvent>().listen((event) {
      if (!mounted) return;
      if (event.type == EventType.showInfo) {
        final tabIndex = context.read<IntSelectCubit>().state;
        if (tabIndex == 1) {
          sort = context.read<HistoryCubit>().state.sort;
        } else if (tabIndex == 2) {
          sort = context.read<DownloadCubit>().state.sort;
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
    final tabIndex = context.watch<IntSelectCubit>().state;
    final topBarState = context.watch<TopBarCubit>().state;

    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppBar(
            title: Text(
              tabIndex == 0
                  ? "收藏"
                  : tabIndex == 1
                  ? "历史"
                  : "下载",
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
          Container(color: context.textColor, height: 1),
          SizedBox(height: 16),
          if (topBarState == 1) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _shieldCategory(),
            ),
            SizedBox(height: 16),
          ],
          if (topBarState == 0) ...[
            if (tabIndex == 0) ...[
              // 收藏
              if (topBarState == 2) ...[
                // 禁漫
                Builder(
                  builder: (context) {
                    // 读取 JmFavoriteCubit 的状态
                    final jmState = context.watch<JmFavoriteCubit>().state;
                    // 用 Cubit 状态初始化本地 `sort` 变量
                    sort = jmState.sort;

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          // 假设 SortWidget 已被重构
                          child: SortWidget(
                            initialSort: jmState.sort, // 传递初始值
                            onSortChanged: (value) {
                              sort = value; // 更新本地 state
                            },
                          ),
                        ),
                        // 假设 keywordSearch 已被重构
                        keywordSearch(
                          initialKeyword: jmState.keyword, // 传递初始值
                          onSubmitted: (value) {
                            keyword = value; // 更新本地 state
                          },
                        ),
                      ],
                    );
                  },
                ),
              ] else ...[
                historyPageSkip(),
              ],
            ],
            if (tabIndex == 1) ...[
              // 历史
              Builder(
                builder: (context) {
                  final historyState = context.watch<HistoryCubit>().state;
                  sort = historyState.sort; // 初始化本地 sort
                  categories = historyState.categories; // 初始化本地 categories

                  return Column(
                    children: [
                      if (topBarState != 2) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          // 10. _choiceCategory 现在接收 List<String>
                          child: _choiceCategory(historyState.categories),
                        ),
                        SizedBox(height: 8),
                      ],
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: SortWidget(
                          initialSort: historyState.sort,
                          onSortChanged: (value) {
                            sort = value;
                          },
                        ),
                      ),
                      keywordSearch(
                        initialKeyword: historyState.keyword,
                        onSubmitted: (value) {
                          keyword = value;
                        },
                      ),
                    ],
                  );
                },
              ),
            ],

            if (tabIndex == 2) ...[
              // 下载
              Builder(
                builder: (context) {
                  final downloadState = context.watch<DownloadCubit>().state;
                  sort = downloadState.sort; // 初始化
                  categories = downloadState.categories; // 初始化

                  return Column(
                    children: [
                      if (topBarState != 2) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: _choiceCategory(
                            downloadState.categories,
                          ), // 传递数据
                        ),
                        SizedBox(height: 8),
                      ],
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: SortWidget(
                          initialSort: downloadState.sort,
                          onSortChanged: (value) {
                            sort = value;
                          },
                        ),
                      ),
                      keywordSearch(
                        initialKeyword: downloadState.keyword,
                        onSubmitted: (value) {
                          keyword = value;
                        },
                      ),
                    ],
                  );
                },
              ),
            ],

            Spacer(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('取消'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // --- 11. _onTap 逻辑会重构 ---
                      _onTap();
                      Navigator.pop(context);
                    },
                    child: Text('确定'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _shieldCategory() {
    final bikaSettingCubit = context.read<BikaSettingCubit>();
    return GestureDetector(
      onTap: () async {
        late var oldCategoriesMap = Map.of(
          bikaSettingCubit.state.shieldCategoryMap,
        );
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
        style: TextStyle(
          fontSize: 16,
          color: context.theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _choiceCategory(List<String> initialCategories) {
    return GestureDetector(
      onTap: () async {
        // 1. 从 `initialCategories` (来自 Cubit) 初始化 oldCategoriesMap
        Map<String, bool> oldCategoriesMap = Map.from(categoryMap);
        for (String category in initialCategories) {
          if (oldCategoriesMap.containsKey(category)) {
            oldCategoriesMap[category] = true;
          }
        }

        // 2. 调用重构后的 showCategoryDialog
        final categoriesSelected = await showCategoryDialog(
          context,
          initialCategories, // 传递数据
        );

        if (categoriesSelected == null ||
            oldCategoriesMap == categoriesSelected) {
          return;
        }

        var temp = categoriesSelected.entries
            .where((entry) => entry.value == true)
            .map((entry) => entry.key)
            .toList();

        // 3. 更新本地 state
        setState(() {
          categories = temp;
        });
      },
      child: Text(
        '选择分类',
        style: TextStyle(
          fontSize: 16,
          color: context.theme.colorScheme.primary,
        ),
      ),
    );
  }

  // --- 13. _onTap (提交) 重构 ---
  void _onTap() {
    // 1. 读取 Cubit 状态来决定要更新 *哪个* Cubit
    final bikaSettingCubit = context.read<BikaSettingCubit>();
    final tabIndex = context.read<IntSelectCubit>().state;
    final topBarState = context.read<TopBarCubit>().state;

    if (tabIndex == 0) {
      // 收藏
      if (topBarState == 2) {
        // 禁漫
        // 2. 使用 context.read 更新 Cubit
        final cubit = context.read<JmFavoriteCubit>();
        cubit.setSort(sort);
        cubit.setKeyword(keyword);
        eventBus.fire(JmFavoriteEvent(EventType.refresh));
        return;
      }
      // 哔咔
      bikaSettingCubit.updateShieldCategoryMap(_categoriesShield);
      context.read<FavoriteCubit>().setKeyword(keyword);

      if (page != -1 && page != 0) {
        eventBus.fire(FavoriteEvent(EventType.pageSkip, sortType, page));
      } else {
        eventBus.fire(FavoriteEvent(EventType.updateShield, sortType, page));
      }
    }

    if (tabIndex == 1) {
      bikaSettingCubit.updateShieldCategoryMap(_categoriesShield);
      final cubit = context.read<HistoryCubit>();
      cubit.setSort(sort);
      cubit.setCategories(categories);
      cubit.setKeyword(keyword);

      eventBus.fire(HistoryEvent(EventType.refresh));
    }

    if (tabIndex == 2) {
      bikaSettingCubit.updateShieldCategoryMap(_categoriesShield);
      final cubit = context.read<DownloadCubit>();
      cubit.setSort(sort);
      cubit.setCategories(categories);
      cubit.setKeyword(keyword);

      eventBus.fire(DownloadEvent(EventType.refresh));
    }
  }

  Widget historyPageSkip() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: TextField(
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
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

  Widget keywordSearch({
    required String initialKeyword,
    required ValueChanged<String> onSubmitted,
  }) {
    final TextEditingController controller = TextEditingController(
      text: initialKeyword,
    );

    keyword = initialKeyword;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: '搜索漫画，请输入关键字'),
          onSubmitted: onSubmitted,
        ),
      ),
    );
  }
}
