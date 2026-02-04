import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/page/search/widget/advanced_search_dialog.dart';
import 'package:zephyr/page/search_result/bloc/search_bloc.dart';

class BikaSearchBar extends StatelessWidget implements PreferredSizeWidget {
  final SearchEvent searchEvent;

  const BikaSearchBar({super.key, required this.searchEvent});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: colorScheme.surface,
      titleSpacing: 0, // 清除默认边距，完全自定义
      automaticallyImplyLeading: false, // 禁用默认返回键，我们自己画
      // 2. 核心内容区域
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            // 左侧返回按钮
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.maybePop(),
            ),

            // 中间伪装的搜索框 (点击返回上一页)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // 点击搜索框区域，返回上一页去输入关键词
                  context.maybePop();
                },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          searchEvent.searchStates.searchKeyword,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
              ),
            ),

            // 右侧高级搜索按钮
            IconButton(
              icon: const Icon(Icons.tune),
              onPressed: () async {
                final searchCubit = context.read<SearchCubit>();

                // 弹出之前写好的高级搜索 Dialog
                final SearchStates? newStates = await showDialog<SearchStates>(
                  context: context,
                  builder: (context) {
                    return AdvancedSearchDialog(
                      initialState: searchCubit.state,
                    );
                  },
                );

                if (newStates != null && context.mounted) {
                  searchCubit.update(newStates);
                }
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),

      // 3. 底部分割线 (你想要的风格)
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          thickness: 1,
          color: colorScheme.outlineVariant.withValues(alpha: 0.5), // 淡淡的分割线
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1); // 高度要加上分割线
}
