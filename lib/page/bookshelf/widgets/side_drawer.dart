import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/bika/bika_setting.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/config/jm/jm_setting.dart';
import 'package:zephyr/cubit/list_select.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart';
import 'package:zephyr/page/bookshelf/json/jm_cloud_favorite/jm_cloud_favorite_json.dart'
    show FolderList;
import 'package:zephyr/page/bookshelf/widgets/jm/cloud_favorite_category.dart';
import 'package:zephyr/page/bookshelf/widgets/jm/cloud_favorite_sort.dart';
import 'package:zephyr/page/bookshelf/widgets/jm/favorite_switch.dart';
import 'package:zephyr/type/pipe.dart';

import '../../../cubit/int_select.dart';

class SideDrawer extends StatefulWidget {
  const SideDrawer({super.key});

  @override
  State<SideDrawer> createState() => _SideDrawerState();
}

class _SideDrawerState extends State<SideDrawer> {
  late final BikaSettingState settings;
  late final Map<String, bool> _categoriesShield;
  List<String> categories = [];
  SortType sortType = SortType.nullValue;
  int page = 0;
  String sort = 'dd';
  String keyword = '';

  @override
  void initState() {
    super.initState();
    settings = objectbox.userSettingBox.get(1)!.bikaSetting;
    _categoriesShield = Map.of(settings.shieldCategoryMap);
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
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDrawerHeader(tabIndex),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                children: [
                  if (comicChoice == 1) ...[
                    _shieldCategory(),
                    const SizedBox(height: 12),
                  ],
                  if (_showChoiceCategory(tabIndex, comicChoice)) ...[
                    _buildChoiceCategoryTile(tabIndex),
                    const SizedBox(height: 12),
                  ],
                  _buildSectionCard(
                    child: _buildMainContent(tabIndex, comicChoice),
                  ),
                  if (_showSearchCard(tabIndex, comicChoice)) ...[
                    const SizedBox(height: 12),
                    _buildSectionCard(
                      child: _buildSearchContent(tabIndex, comicChoice),
                    ),
                  ],
                ],
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(int tabIndex) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Icon(_tabIcon(tabIndex), color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _tabTitle(tabIndex),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
          IconButton.filledTonal(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context);
            },
            tooltip: '关闭',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: child,
    );
  }

  Widget _buildBottomActions() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.close),
                label: const Text('取消'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  _onTap();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check),
                label: const Text('确定'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _tabTitle(int tabIndex) {
    if (tabIndex == 0) return '收藏';
    if (tabIndex == 1) return '历史';
    return '下载';
  }

  IconData _tabIcon(int tabIndex) {
    if (tabIndex == 0) return Icons.favorite_rounded;
    if (tabIndex == 1) return Icons.history_rounded;
    return Icons.download_rounded;
  }

  bool _showChoiceCategory(int tabIndex, int comicChoice) {
    return tabIndex != 0 && comicChoice != 2;
  }

  Widget _buildChoiceCategoryTile(int tabIndex) {
    if (tabIndex == 1) {
      return Builder(
        builder: (context) {
          final historyState = context.watch<HistoryCubit>().state;
          categories = historyState.categories;
          return _choiceCategory(historyState.categories);
        },
      );
    }

    if (tabIndex == 2) {
      return Builder(
        builder: (context) {
          final downloadState = context.watch<DownloadCubit>().state;
          categories = downloadState.categories;
          return _choiceCategory(downloadState.categories);
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildMainContent(int tabIndex, int comicChoice) {
    if (tabIndex == 0) {
      return _buildFavoriteContent(context, comicChoice);
    }
    if (tabIndex == 1) {
      return _buildHistoryContent(context, comicChoice);
    }
    return _buildDownloadContent(context, comicChoice);
  }

  bool _showSearchCard(int tabIndex, int comicChoice) {
    if (tabIndex == 1 || tabIndex == 2) {
      return true;
    }

    if (tabIndex == 0 && comicChoice == 2) {
      return context.watch<JmSettingCubit>().state.favoriteSet == 1;
    }

    return false;
  }

  Widget _buildSearchContent(int tabIndex, int comicChoice) {
    if (tabIndex == 1) {
      return Builder(
        builder: (context) {
          final historyState = context.watch<HistoryCubit>().state;
          keyword = historyState.keyword;

          return _KeywordSearchField(
            initialKeyword: historyState.keyword,
            onSubmitted: (value) {
              keyword = value;
            },
          );
        },
      );
    }

    if (tabIndex == 2) {
      return Builder(
        builder: (context) {
          final downloadState = context.watch<DownloadCubit>().state;
          keyword = downloadState.keyword;

          return _KeywordSearchField(
            initialKeyword: downloadState.keyword,
            onSubmitted: (value) {
              keyword = value;
            },
          );
        },
      );
    }

    if (tabIndex == 0 && comicChoice == 2) {
      return Builder(
        builder: (context) {
          final jmState = context.watch<JmFavoriteCubit>().state;
          keyword = jmState.keyword;

          return _KeywordSearchField(
            initialKeyword: jmState.keyword,
            onSubmitted: (value) {
              keyword = value;
            },
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  /// 构建“收藏”Tab对应的表单
  Widget _buildFavoriteContent(BuildContext context, int topBarState) {
    logger.d("topBarState: $topBarState");
    if (topBarState == 2) {
      // 禁漫
      final jmState = context.watch<ListSelectCubit<FolderList>>().state;
      final jmSortState = context.watch<JmCloudFavoriteCubit>().state;
      late final String initialState;
      if (jmSortState.categories.isNotEmpty) {
        initialState = jmSortState.categories.first;
      } else {
        initialState = "";
      }
      final jmCubitState = context.watch<JmSettingCubit>().state;
      final jmCubit = context.read<JmSettingCubit>();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: FavoriteSwitch(
              initialSort: jmCubitState.favoriteSet.toString(),
              onSortChanged: (value) {
                final jmFavoriteCubit = context.read<JmFavoriteCubit>();
                jmFavoriteCubit.resetSearch();
                jmCubit.updateFavoriteSet(value.let(toInt));
                context.read<StringSelectCubit>().setDate("");
              },
            ),
          ),
          if (jmCubitState.favoriteSet == 0) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CloudFavoriteCategory(
                initialSort: initialState,
                list: jmState,
                onSortChanged: (value) {
                  categories = [value];
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CloudFavoriteSort(
                initialSort: jmSortState.sort,
                onSortChanged: (value) {
                  sort = value;
                },
              ),
            ),
          ] else ...[
            Builder(
              builder: (context) {
                final jmState = context.watch<JmFavoriteCubit>().state;
                sort = jmState.sort;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: SortWidget(
                        initialSort: jmState.sort,
                        onSortChanged: (value) {
                          sort = value;
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      );
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SortWidget(
                initialSort: historyState.sort,
                onSortChanged: (value) {
                  sort = value;
                },
              ),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SortWidget(
                initialSort: downloadState.sort,
                onSortChanged: (value) {
                  sort = value;
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _shieldCategory() {
    final bikaSettingCubit = context.read<BikaSettingCubit>();
    return _buildActionTile(
      title: '屏蔽分类',
      icon: Icons.visibility_off_outlined,
      onTap: () async {
        final oldCategoriesMap = Map.of(
          bikaSettingCubit.state.shieldCategoryMap,
        );
        final categoriesShield = await showShieldCategoryDialog(context);

        if (categoriesShield == null || oldCategoriesMap == categoriesShield) {
          return;
        }

        _categoriesShield
          ..clear()
          ..addAll(categoriesShield);
      },
    );
  }

  Widget _choiceCategory(List<String> initialCategories) {
    return _buildActionTile(
      title: '选择分类',
      icon: Icons.category_outlined,
      onTap: () async {
        final oldCategoriesMap = Map<String, bool>.from(categoryMap);
        for (String category in initialCategories) {
          if (oldCategoriesMap.containsKey(category)) {
            oldCategoriesMap[category] = true;
          }
        }

        final categoriesSelected = await showCategoryDialog(
          context,
          oldCategoriesMap,
        );
        if (categoriesSelected == null) {
          return;
        }
        var temp = categoriesSelected.entries
            .where((entry) => entry.value == true)
            .map((entry) => entry.key)
            .toList();
        categories = temp;
      },
    );
  }

  Widget _buildActionTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTap() {
    final bikaSettingCubit = context.read<BikaSettingCubit>();
    final tabIndex = context.read<IntSelectCubit>().state;
    final comicChoice = context.read<GlobalSettingCubit>().state.comicChoice;
    final jmSettingCubit = context.read<JmSettingCubit>();

    if (tabIndex == 0) {
      if (comicChoice == 2) {
        if (jmSettingCubit.state.favoriteSet == 1) {
          final cubit = context.read<JmFavoriteCubit>();
          cubit.setSort(sort);
          cubit.setKeyword(keyword);
          eventBus.fire(JmFavoriteEvent(EventType.refresh));
          return;
        } else {
          final cubit = context.read<JmCloudFavoriteCubit>();
          cubit.setCategories(categories);
          cubit.setSort(sort);
          eventBus.fire(JmCloudFavoriteEvent(EventType.refresh));
          return;
        }
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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          labelText: '跳页',
          hintText: '请输入页数',
          prefixIcon: const Icon(Icons.low_priority_rounded),
          filled: true,
          fillColor: theme.colorScheme.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: '搜索',
          hintText: '请输入关键字',
          prefixIcon: const Icon(Icons.search_rounded),
          filled: true,
          fillColor: theme.colorScheme.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onSubmitted: widget.onSubmitted,
      ),
    );
  }
}
