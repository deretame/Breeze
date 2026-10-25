import 'package:flutter/material.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/page/search_result/models/unified_plugin_search.dart';
import 'package:zephyr/page/search_result/search_cursor/search_cursor_locator.dart';
import 'package:zephyr/page/search_result/search_cursor/search_cursor_record.dart';
import 'package:zephyr/page/search_result/search_cursor/search_cursor_store.dart';
import 'package:zephyr/widgets/toast.dart';

/// 跨页面传递游标揭示锚点。
///
/// 搜索页跳转游标时直接 pushRoute 新建结果页，无法通过构造参数把
/// “落地后滚动到锚点并高亮”的意图传给新页面，用这个一次性总线中转：
/// 跳转前 request，结果页首次加载成功时 consume。
class SearchCursorReveal {
  SearchCursorReveal._();

  static String? _pendingAnchorId;

  static void request(String anchorId) => _pendingAnchorId = anchorId;

  static String? consume() {
    final value = _pendingAnchorId;
    _pendingAnchorId = null;
    return value;
  }
}

/// 通过插件 searchComic 抓取一页搜索结果，构造游标定位探测快照。
Future<SearchCursorPageSnapshot> fetchSearchCursorProbePage({
  required String pluginId,
  required String keyword,
  required int page,
  required Map<String, dynamic> extern,
}) async {
  final support = searchCursorPlugins[pluginId];
  final response = await callUnifiedComicPlugin(
    pluginId: pluginId,
    fnPath: 'searchComic',
    core: {'keyword': keyword, 'page': page},
    extern: extern,
  );
  final parsed = UnifiedPluginSearchResponse.fromMap(response);
  final items = parsed.items
      .map(
        (item) => SearchCursorPageSnapshotItem(
          id: item.id,
          // 排序键字段随插件不同（JM: update_at Unix 秒；Bika: updated_at ISO）。
          updateAt: support == null ? 0 : support.sortKeyOf(item.raw),
        ),
      )
      .toList();
  return SearchCursorPageSnapshot(
    page: page,
    items: items,
    endReached: items.isEmpty || parsed.paging.hasReachedMax,
  );
}

/// 定位游标所在页（封装 fetcher + 预算读取）。
Future<SearchCursorLocateResult> locateSearchCursorPage({
  required SearchCursorRecord record,
  required int probeBudget,
}) {
  // 复现记录时的完整 extern（Bika 的分类筛选会改变结果集）。
  final extern = record.extern.isNotEmpty
      ? record.extern
      : <String, dynamic>{'sortBy': record.sortBy};
  return locateSearchCursor(
    fetchPage: (page) => fetchSearchCursorProbePage(
      pluginId: record.pluginId,
      keyword: record.keyword,
      page: page,
      extern: extern,
    ),
    anchorId: record.anchorComicId,
    anchorUpdateAt: record.anchorUpdateAt,
    anchorPage: record.anchorPage,
    budget: probeBudget,
    probeInterval: searchCursorProbeInterval,
  );
}

/// 带进度弹窗的游标定位：成功/近似/失败均有 toast。
/// 返回 null 表示定位失败（弹窗已关闭）。
Future<SearchCursorLocateResult?> locateCursorWithProgress(
  BuildContext context,
  SearchCursorRecord record,
) async {
  final support = searchCursorPlugins[record.pluginId];
  if (support == null || record.sortBy != support.newestSortBy) {
    showWarningToast(t.searchResult.cursorOnlyNewestSort);
    return null;
  }
  final probeBudget = await SearchCursorStore().loadProbeBudget();
  if (!context.mounted) return null;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 16),
          Expanded(child: Text(t.searchResult.cursorLocating)),
        ],
      ),
    ),
  );
  SearchCursorLocateResult result;
  try {
    result = await locateSearchCursorPage(
      record: record,
      probeBudget: probeBudget,
    );
  } catch (error, stack) {
    logger.e(
      'cursor locate failed: keyword=${record.keyword} '
      'anchor=${record.anchorComicId}',
      error: error,
      stackTrace: stack,
    );
    if (!context.mounted) return null;
    Navigator.of(context).pop();
    showWarningToast(t.searchResult.cursorJumpFailed);
    return null;
  }
  if (!context.mounted) return null;
  Navigator.of(context).pop();
  logger.d(
    'cursor locate done: found=${result.found} page=${result.page} '
    'probes=${result.probesUsed}',
  );
  if (result.found) {
    showSuccessToast(t.searchResult.cursorJumpedSuccess(page: result.page));
  } else {
    showWarningToast(t.searchResult.cursorJumpApproximate(page: result.page));
  }
  return result;
}
