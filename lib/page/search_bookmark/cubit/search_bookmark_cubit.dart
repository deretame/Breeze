import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';

/// 搜索书签无需插件声明：快照只是搜索参数重放，全插件可用。

/// 单槽揭示总线：管理页跳转时把整条书签传给结果页，
/// 落地后按“页内序号”精确定位并高亮。
class SearchBookmarkReveal {
  SearchBookmarkReveal._();

  static SearchBookmark? _pending;

  static void request(SearchBookmark bookmark) => _pending = bookmark;

  static SearchBookmark? consume() {
    final value = _pending;
    _pending = null;
    return value;
  }
}

enum SearchBookmarkStatus { initial, loading, success, failure }

class SearchBookmarkState {
  const SearchBookmarkState({
    this.status = SearchBookmarkStatus.initial,
    this.items = const [],
    this.result = '',
    this.selectedSources = const {},
    this.sortAscending = false,
  });

  final SearchBookmarkStatus status;
  final List<SearchBookmark> items;
  final String result;

  /// 选中的插件 source 集合：空表示全部。
  final Set<String> selectedSources;

  /// 时间排序方向：false=最新在前（默认），true=最早在前。
  final bool sortAscending;

  /// 筛选+排序后的可见列表。
  List<SearchBookmark> get visibleItems {
    final filtered = selectedSources.isEmpty
        ? items.toList()
        : items.where((item) => selectedSources.contains(item.source)).toList();
    filtered.sort(
      (a, b) => sortAscending
          ? a.updatedAt.compareTo(b.updatedAt)
          : b.updatedAt.compareTo(a.updatedAt),
    );
    return filtered;
  }

  /// 有书签的插件 source 列表。
  List<String> get availableSources {
    final set = <String>{};
    for (final item in items) {
      if (item.source.trim().isNotEmpty) set.add(item.source.trim());
    }
    return set.toList();
  }

  SearchBookmarkState copyWith({
    SearchBookmarkStatus? status,
    List<SearchBookmark>? items,
    String? result,
    Set<String>? selectedSources,
    bool? sortAscending,
  }) {
    return SearchBookmarkState(
      status: status ?? this.status,
      items: items ?? this.items,
      result: result ?? this.result,
      selectedSources: selectedSources ?? this.selectedSources,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }
}

/// 搜索书签：ObjectBox 直读写，无同步、无墓碑，删了就是删了。
class SearchBookmarkCubit extends Cubit<SearchBookmarkState> {
  SearchBookmarkCubit() : super(const SearchBookmarkState());

  /// 全量加载所有插件的书签（不再按 source 过滤）。
  void loadAll() {
    emit(state.copyWith(status: SearchBookmarkStatus.loading));
    try {
      final items = objectbox.searchBookmarkBox.getAll();
      if (isClosed) return;
      emit(state.copyWith(status: SearchBookmarkStatus.success, items: items));
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: SearchBookmarkStatus.failure,
          result: e.toString(),
        ),
      );
    }
  }

  void applyFilter({required Set<String> sources, required bool ascending}) {
    if (isClosed) return;
    emit(
      state.copyWith(
        selectedSources: Set<String>.from(sources),
        sortAscending: ascending,
      ),
    );
  }

  /// 添加书签：同 uniqueKey 覆盖（更新 updatedAt 并排最前）。
  Future<SearchBookmark> add({
    required String source,
    required String keyword,
    required Map<String, dynamic> extern,
    required String anchorComicId,
    required String anchorTitle,
    required String anchorCover,
    required int anchorPage,
    int anchorIndex = 0,
  }) async {
    final now = DateTime.now();
    final uniqueKey = searchBookmarkUniqueKey(source, keyword, anchorComicId);
    final query = objectbox.searchBookmarkBox
        .query(SearchBookmark_.uniqueKey.equals(uniqueKey))
        .build();
    final existing = query.findFirst();
    query.close();
    final entity = SearchBookmark(
      id: existing?.id ?? 0,
      uniqueKey: uniqueKey,
      source: source.trim(),
      keyword: keyword.trim(),
      externJson: jsonEncode(extern),
      anchorComicId: anchorComicId.trim(),
      anchorTitle: anchorTitle,
      anchorCover: anchorCover,
      anchorPage: anchorPage,
      anchorIndex: anchorIndex < 0 ? 0 : anchorIndex,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    objectbox.searchBookmarkBox.put(entity);
    if (!isClosed) loadAll();
    return entity;
  }

  Future<void> remove(SearchBookmark bookmark) async {
    objectbox.searchBookmarkBox.remove(bookmark.id);
    if (!isClosed) loadAll();
  }
}
