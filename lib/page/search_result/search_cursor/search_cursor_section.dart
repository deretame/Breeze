import 'package:material_ui/material_ui.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/page/search_result/search_cursor/search_cursor.dart';

/// 高级搜索对话框里的「搜索游标」区块（实验性）。
///
/// [pluginId] 为当前搜索图源：非空时只展示该插件的游标，空（尚未选择
/// 图源/未搜索）时展示全部支持插件的游标。图源不受支持时整块隐藏。
///
/// [onAdd] 传 null 时隐藏「添加游标」按钮（例如尚未产生搜索结果的搜索页）。
/// 跳转由宿主对话框处理：点击记录回调 [onJump]。
class SearchCursorSection extends StatefulWidget {
  const SearchCursorSection({
    super.key,
    required this.onJump,
    this.pluginId,
    this.onAdd,
    this.currentSortBy = searchCursorSupportedSortBy,
    this.currentExtern = const <String, dynamic>{},
  });

  final ValueChanged<SearchCursorRecord> onJump;
  final VoidCallback? onAdd;

  /// 当前图源插件 id，空表示未选择（展示全部游标）。
  final String? pluginId;

  /// 当前应用层排序值（用于判断是否“最新优先”）。
  final int currentSortBy;

  /// 当前搜索 extern（用于判断是否纯关键词搜索）。
  final Map<String, dynamic> currentExtern;

  @override
  State<SearchCursorSection> createState() => _SearchCursorSectionState();
}

class _SearchCursorSectionState extends State<SearchCursorSection> {
  final SearchCursorStore _store = SearchCursorStore();
  List<SearchCursorRecord> _records = const [];
  int _probeBudget = defaultSearchCursorProbeBudget;

  /// 当前图源对应的支持描述；图源为空（未选择）时视为可用占位。
  SearchCursorPluginSupport? get _support {
    final id = widget.pluginId?.trim() ?? '';
    return id.isEmpty ? null : searchCursorPlugins[id];
  }

  bool get _visible =>
      (widget.pluginId?.trim() ?? '').isEmpty || _support != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await _store.loadRecords();
    final budget = await _store.loadProbeBudget();
    if (!mounted) return;
    setState(() {
      final id = widget.pluginId?.trim() ?? '';
      _records = id.isEmpty
          ? records
          : records.where((item) => item.pluginId == id).toList();
      _probeBudget = budget;
    });
  }

  Future<void> _updateBudget(int value) async {
    final budget = value.clamp(1, maxSearchCursorProbeBudget);
    await _store.saveProbeBudget(budget);
    if (!mounted) return;
    setState(() => _probeBudget = budget);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    final support = _support;
    final addEnabled =
        widget.onAdd != null &&
        support != null &&
        widget.currentSortBy == support.newestSortBy &&
        isPlainKeywordExtern(widget.currentExtern);
    final wrongSort =
        widget.onAdd != null &&
        support != null &&
        widget.currentSortBy != support.newestSortBy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        Text(
          t.searchResult.cursorSectionTitle,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (wrongSort)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              t.searchResult.cursorOnlyNewestSort,
              style: textTheme.bodySmall,
            ),
          ),
        if (_records.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(t.searchResult.cursorEmpty, style: textTheme.bodySmall),
          )
        else
          ..._records.map(_buildRow),
        if (widget.onAdd != null) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: addEnabled ? widget.onAdd : null,
            icon: const Icon(Icons.flag_outlined),
            label: Text(t.searchResult.cursorAdd),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: Text(t.searchResult.cursorProbeBudget)),
            DropdownButton<int>(
              value: _probeBudget.clamp(1, maxSearchCursorProbeBudget),
              items: [
                for (var i = 1; i <= maxSearchCursorProbeBudget; i++)
                  DropdownMenuItem<int>(value: i, child: Text('$i')),
              ],
              onChanged: (value) {
                if (value != null) {
                  _updateBudget(value);
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(SearchCursorRecord record) {
    final title = record.anchorTitle.trim();
    final createdAt = record.createdAt > 0
        ? DateTime.fromMillisecondsSinceEpoch(record.createdAt)
        : null;
    final timeText = createdAt == null
        ? ''
        : '${createdAt.year.toString().padLeft(4, '0')}-'
              '${createdAt.month.toString().padLeft(2, '0')}-'
              '${createdAt.day.toString().padLeft(2, '0')} '
              '${createdAt.hour.toString().padLeft(2, '0')}:'
              '${createdAt.minute.toString().padLeft(2, '0')}';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Row(
        children: [
          Expanded(
            child: Text(
              record.keyword,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(timeText, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      subtitle: Text(
        t.searchResult.cursorAnchorSubtitle(
          title: title.isEmpty ? record.anchorComicId : title,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => widget.onJump(record),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () async {
          await _store.deleteRecord(record);
          if (!mounted) return;
          _load();
        },
      ),
    );
  }
}
