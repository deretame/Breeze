import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:zephyr/page/search_result/search_cursor/search_cursor_record.dart';

/// 搜索游标本地存储（shared_preferences JSON 列表）。
class SearchCursorStore {
  static const _recordsKey = 'search_cursor.records.v1';
  static const _probeBudgetKey = 'search_cursor.probe_budget.v1';
  static const _maxRecords = 50;

  Future<List<SearchCursorRecord>> loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recordsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return list
          .map(SearchCursorRecord.fromJson)
          .whereType<SearchCursorRecord>()
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// 保存游标：同 (pluginId, keyword, sortBy, anchorComicId) 覆盖旧记录
  /// （同一关键词允许挂多个不同锚点的游标），新记录排最前。
  Future<List<SearchCursorRecord>> saveRecord(SearchCursorRecord record) async {
    // loadRecords 的空态/异常态返回 const []（不可变），复制成可变列表再改。
    final records = (await loadRecords()).toList();
    records.removeWhere(
      (item) =>
          item.pluginId == record.pluginId &&
          item.keyword == record.keyword &&
          item.sortBy == record.sortBy &&
          item.anchorComicId == record.anchorComicId,
    );
    final next = [record, ...records].take(_maxRecords).toList();
    await _writeRecords(next);
    return next;
  }

  Future<List<SearchCursorRecord>> deleteRecord(
    SearchCursorRecord record,
  ) async {
    final records = (await loadRecords()).toList();
    records.removeWhere(
      (item) =>
          item.pluginId == record.pluginId &&
          item.keyword == record.keyword &&
          item.sortBy == record.sortBy &&
          item.anchorComicId == record.anchorComicId,
    );
    await _writeRecords(records);
    return records;
  }

  Future<void> _writeRecords(List<SearchCursorRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _recordsKey,
      jsonEncode(records.map((item) => item.toJson()).toList()),
    );
  }

  Future<int> loadProbeBudget() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_probeBudgetKey);
    if (value == null) return defaultSearchCursorProbeBudget;
    return value.clamp(1, maxSearchCursorProbeBudget);
  }

  Future<void> saveProbeBudget(int budget) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _probeBudgetKey,
      budget.clamp(1, maxSearchCursorProbeBudget),
    );
  }
}
