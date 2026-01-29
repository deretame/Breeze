import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';

class HistoryWidget extends StatefulWidget {
  const HistoryWidget({super.key});

  @override
  State<HistoryWidget> createState() => _HistoryWidgetState();
}

class _HistoryWidgetState extends State<HistoryWidget> {
  bool _isNewestFirst = true;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final globalSettingState = context.watch<GlobalSettingCubit>().state;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
          child: Row(
            children: [
              Text(
                '搜索历史',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),

              // 排序按钮
              if (globalSettingState.searchHistory.isNotEmpty) ...[
                _buildSortButton(),

                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: '清空历史',
                  color: colorScheme.outline,
                  onPressed: _resetHistory,
                ),
              ],
            ],
          ),
        ),

        // --- 3. 历史记录内容区域 ---
        Expanded(
          child: globalSettingState.searchHistory.isEmpty
              ? _buildEmpty()
              : _buildHistoryList(globalSettingState.searchHistory),
        ),
      ],
    );
  }

  Widget _buildSortButton() {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: _isNewestFirst ? "当前：最近搜索在前" : "当前：最早搜索在前",
      child: TextButton.icon(
        // 既然是文字+图标，用TextButton更紧凑
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: const Size(0, 36),
        ),
        icon: Icon(
          _isNewestFirst ? Icons.history : Icons.history_toggle_off, // 图标随状态变
          size: 18,
          color: colorScheme.primary,
        ),
        label: Text(
          _isNewestFirst ? "时间倒序" : "时间正序",
          style: TextStyle(fontSize: 12, color: colorScheme.primary),
        ),
        onPressed: () {
          setState(() {
            _isNewestFirst = !_isNewestFirst;
          });
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.manage_search,
            size: 64,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          const SizedBox(height: 16),
          Text(
            "暂无搜索记录",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<String> historyList) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: Wrap(
          // 1. 加大间距，防止挤在一起
          spacing: 12.0, // 水平间距
          runSpacing: 12.0, // 垂直间距 (换行后的间距)
          alignment: WrapAlignment.start,
          children: historyList.map((historyItem) {
            return InputChip(
              label: Text(historyItem),
              labelStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
              ),
              // 2. 背景色改淡一点，或者直接用白色配合边框
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerLow,

              // 3. 【关键】加回边框，使用标准的浅灰色
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 1.0,
              ),

              // 4. 调整形状和内边距，让它看起来不那么局促
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 2,
                vertical: 0,
              ), // 整体微调

              onPressed: () => {},
              deleteIcon: Icon(
                Icons.close,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              onDeleted: () => _deleteSingle(historyItem),

              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            );
          }).toList(),
        ),
      ),
    );
  }

  void _deleteSingle(String historyItem) {
    final globalSettingCubit = context.read<GlobalSettingCubit>();
    final List<String> newHistory = List.from(
      globalSettingCubit.state.searchHistory,
    );
    newHistory.remove(historyItem);
    globalSettingCubit.updateSearchHistory(newHistory);
  }

  void _resetHistory() {
    final globalSettingCubit = context.read<GlobalSettingCubit>();
    globalSettingCubit.resetSearchHistory();
  }
}
