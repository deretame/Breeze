import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/ranking_list/cubit/comic_filter_cubit.dart';
import 'package:zephyr/util/context/context_extensions.dart';

class ComicFilterDialog extends StatelessWidget {
  const ComicFilterDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ComicFilterCubit, ComicFilterState>(
      builder: (context, state) {
        return AlertDialog(
          title: const Text('筛选漫画'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('分类'),
                _buildMainCategoryChips(context, state),

                // 动态判断是否显示子分类
                if (ComicFilterCubit.categoryMap[state.mainKey] is Map) ...[
                  const Divider(height: 24),
                  _buildSectionTitle('子分类'),
                  _buildSubCategoryChips(
                    context,
                    state,
                    ComicFilterCubit.categoryMap[state.mainKey] as Map,
                  ),
                ],

                const Divider(height: 24),
                _buildSectionTitle('排序'),
                _buildRankingChips(context, state),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                // 直接从 Cubit 获取结果并返回
                final result = context
                    .read<ComicFilterCubit>()
                    .generateResult();
                Navigator.pop(context, result);
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  // --- Chip 构建逻辑 ---

  Widget _buildChip(
    BuildContext context,
    String label,
    bool isSelected,
    VoidCallback onSelected,
  ) {
    final colorScheme = context.theme.colorScheme;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) onSelected();
      },
      showCheckmark: false,
      selectedColor: colorScheme.primary,
      backgroundColor: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6.0),
        side: BorderSide(
          color: isSelected ? Colors.transparent : colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      labelStyle: TextStyle(
        color: isSelected
            ? colorScheme.onPrimary
            : colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildMainCategoryChips(BuildContext context, ComicFilterState state) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: ComicFilterCubit.categoryMap.keys.map((key) {
        return _buildChip(
          context,
          key,
          state.mainKey == key, // 判断选中
          () => context.read<ComicFilterCubit>().setMainKey(key), // 触发事件
        );
      }).toList(),
    );
  }

  Widget _buildSubCategoryChips(
    BuildContext context,
    ComicFilterState state,
    Map subMap,
  ) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: subMap.keys.map((key) {
        return _buildChip(
          context,
          '$key',
          state.subKey == key,
          () => context.read<ComicFilterCubit>().setSubKey(key as String),
        );
      }).toList(),
    );
  }

  Widget _buildRankingChips(BuildContext context, ComicFilterState state) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: ComicFilterCubit.rankingTypeMap.keys.map((key) {
        return _buildChip(
          context,
          key,
          state.rankingKey == key,
          () => context.read<ComicFilterCubit>().setRankingKey(key),
        );
      }).toList(),
    );
  }
}
