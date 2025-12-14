import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/config/jm/jm_setting.dart';
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
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabIndex = context.watch<IntSelectCubit>().state;
    final comicChoice = context.read<GlobalSettingCubit>().state.comicChoice;

    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                AppBar(
                  title: Text(
                    tabIndex == 0
                        ? "收藏"
                        : tabIndex == 1
                        ? "历史"
                        : "下载",
                  ),
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                Container(color: context.textColor, height: 1),
                SizedBox(height: 16),
                if (comicChoice == 1) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _shieldCategory(),
                  ),
                  SizedBox(height: 16),
                ],

                if (tabIndex == 0)
                  _buildFavoriteContent(context, comicChoice)
                else if (tabIndex == 1)
                  _buildHistoryContent(context, comicChoice)
                else if (tabIndex == 2)
                  _buildDownloadContent(context, comicChoice),
              ],
            ),
          ),

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
                    _onTap();
                    Navigator.pop(context);
                  },
                  child: Text('确定'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建“收藏”Tab对应的表单
  Widget _buildFavoriteContent(BuildContext context, int topBarState) {
    if (topBarState == 2) {
      // 禁漫
      final jmState = context.watch<JmSettingCubit>().state;
      if (jmState.favoriteSet == 0) {
        return Builder(
          builder: (context) {
            final jmState = context.watch<JmFavoriteCubit>().state;
            sort = jmState.sort; // 仍然在 build 时初始化本地 state

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SortWidget(
                    initialSort: jmState.sort,
                    onSortChanged: (value) {
                      sort = value; // 更新本地 state
                    },
                  ),
                ),
                // --- 4. 使用新的 Stateful Widget ---
                _KeywordSearchField(
                  initialKeyword: jmState.keyword,
                  onSubmitted: (value) {
                    keyword = value; // 更新本地 state
                  },
                ),
              ],
            );
          },
        );
      } else {
        // TODO: 云端收藏操作
        return SizedBox.shrink();
      }
    } else {
      // 哔咔 (收藏)
      // --- 4. 使用新的 Stateful Widget ---
      return _PageSkipField(
        onSubmitted: (value) {
          page = value; // 更新本地 state
        },
      );
    }
  }

  /// 构建“历史”Tab对应的表单
  Widget _buildHistoryContent(BuildContext context, int topBarState) {
    return Builder(
      builder: (context) {
        final historyState = context.watch<HistoryCubit>().state;
        sort = historyState.sort;
        categories = historyState.categories;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (topBarState != 2) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
            // --- 4. 使用新的 Stateful Widget ---
            _KeywordSearchField(
              initialKeyword: historyState.keyword,
              onSubmitted: (value) {
                keyword = value;
              },
            ),
          ],
        );
      },
    );
  }

  /// 构建“下载”Tab对应的表单
  Widget _buildDownloadContent(BuildContext context, int topBarState) {
    return Builder(
      builder: (context) {
        final downloadState = context.watch<DownloadCubit>().state;
        sort = downloadState.sort;
        categories = downloadState.categories;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (topBarState != 2) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _choiceCategory(downloadState.categories),
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
            // --- 4. 使用新的 Stateful Widget ---
            _KeywordSearchField(
              initialKeyword: downloadState.keyword,
              onSubmitted: (value) {
                keyword = value;
              },
            ),
          ],
        );
      },
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

        if (categoriesShield == null || oldCategoriesMap == categoriesShield) {
          return;
        }

        _categoriesShield = Map.of(categoriesShield); // 更新本地字段
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
        Map<String, bool> oldCategoriesMap = Map.from(categoryMap);
        for (String category in initialCategories) {
          if (oldCategoriesMap.containsKey(category)) {
            oldCategoriesMap[category] = true;
          }
        }

        final categoriesSelected = await showCategoryDialog(
          context,
          initialCategories,
        );
        if (categoriesSelected == null /* ... */ ) {
          return;
        }
        var temp = categoriesSelected.entries
            .where((entry) => entry.value == true)
            .map((entry) => entry.key)
            .toList();
        categories = temp;
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

  void _onTap() {
    final bikaSettingCubit = context.read<BikaSettingCubit>();
    final tabIndex = context.read<IntSelectCubit>().state;
    final comicChoice = context.read<GlobalSettingCubit>().state.comicChoice;

    if (tabIndex == 0) {
      if (comicChoice == 2) {
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

      logger.d(categories);

      eventBus.fire(HistoryEvent(EventType.refresh, false));
    }

    if (tabIndex == 2) {
      bikaSettingCubit.updateShieldCategoryMap(_categoriesShield);
      final cubit = context.read<DownloadCubit>();
      cubit.setSort(sort);
      cubit.setCategories(categories);
      cubit.setKeyword(keyword);

      eventBus.fire(DownloadEvent(EventType.refresh, false));
    }
  }
}

class _PageSkipField extends StatefulWidget {
  const _PageSkipField({required this.onSubmitted});

  final ValueChanged<int> onSubmitted;

  @override
  State<_PageSkipField> createState() => _PageSkipFieldState();
}

class _PageSkipFieldState extends State<_PageSkipField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(hintText: '跳页，请输入页数'),
        onSubmitted: (value) {
          int page = -1;
          if (value.isNotEmpty) {
            page = int.parse(value);
          }
          widget.onSubmitted(page);
        },
      ),
    );
  }
}

class _KeywordSearchField extends StatefulWidget {
  const _KeywordSearchField({
    required this.initialKeyword,
    required this.onSubmitted,
  });

  final String initialKeyword;
  final ValueChanged<String> onSubmitted;

  @override
  State<_KeywordSearchField> createState() => _KeywordSearchFieldState();
}

class _KeywordSearchFieldState extends State<_KeywordSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialKeyword);
  }

  @override
  void didUpdateWidget(_KeywordSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialKeyword != oldWidget.initialKeyword &&
        _controller.text != widget.initialKeyword) {
      _controller.text = widget.initialKeyword;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(hintText: '搜索漫画，请输入关键字'),
        onSubmitted: widget.onSubmitted,
      ),
    );
  }
}
