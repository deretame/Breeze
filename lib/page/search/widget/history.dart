import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/page/search_result/bloc/search_bloc.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/router/router.gr.dart';

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
    final searchCubit = context.read<SearchCubit>();
    final sortedHistory = _isNewestFirst
        ? historyList
        : historyList.reversed.toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: Wrap(
          spacing: 12.0,
          runSpacing: 12.0,
          alignment: WrapAlignment.start,
          children: sortedHistory.map((historyItem) {
            return InputChip(
              label: Text(historyItem),
              labelStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
              ),
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerLow,
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 1.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
              onPressed: () => _onSearch(historyItem),
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

  void _onSearch(String keyword) async {
    final searchCubit = context.read<SearchCubit>();
    searchCubit.update(searchCubit.state.copyWith(searchKeyword: keyword));
    if (searchCubit.state.from == From.jm) {
      if (keyword.let(toInt) >= 100) {
        context.pushRoute(
          ComicInfoRoute(
            comicId: keyword,
            type: ComicEntryType.normal,
            from: From.jm,
          ),
        );

        final settingCubit = context.read<GlobalSettingCubit>();
        final history = settingCubit.state.searchHistory.toList();
        history
          ..remove(keyword)
          ..insert(0, keyword);
        await Future.delayed(const Duration(milliseconds: 200));
        settingCubit.updateSearchHistory(history.take(200).toList());
        return;
      }
    }

    context.pushRoute(
      SearchResultRoute(
        searchEvent: SearchEvent().copyWith(searchStates: searchCubit.state),
        searchCubit: searchCubit,
      ),
    );
  }
}
