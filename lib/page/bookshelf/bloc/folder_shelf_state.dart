import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/bookshelf/cubit/search_status.dart';
import 'package:zephyr/page/bookshelf/models/shelf_page_mode.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_info.dart';

part 'folder_shelf_state.freezed.dart';

const String kFolderShelfRootPath = '';

@freezed
abstract class FolderShelfState with _$FolderShelfState {
  const factory FolderShelfState({
    required ShelfPageMode mode,
    @Default(kFolderShelfRootPath) String currentPath,
    @Default(<ComicFolder>[]) List<ComicFolder> folders,
    @Default(<String, int>{}) Map<String, int> folderComicCounts,
    @Default(<ComicSimplifyEntryInfo>[]) List<ComicSimplifyEntryInfo> comics,
    @Default(<String, String>{}) Map<String, String> comicSearchTexts,
    SearchStatusState? search,
    @Default(false) bool isLoading,
    String? error,
    @Default(false) bool sortAscending,
    @Default(false) bool selectionMode,
    @Default(<String>{}) Set<String> selectedFolderPaths,
    @Default(<String>{}) Set<String> selectedComicKeys,
  }) = _FolderShelfState;

  const FolderShelfState._();

  bool get isRoot => currentPath == kFolderShelfRootPath;

  bool get hasSelection =>
      selectedFolderPaths.isNotEmpty || selectedComicKeys.isNotEmpty;

  int get selectedCount =>
      selectedFolderPaths.length + selectedComicKeys.length;

  String get breadcrumbTitle {
    if (currentPath.isEmpty) {
      return _modeLabel(mode);
    }
    final parts = currentPath.split('/')..removeWhere((e) => e.isEmpty);
    return '${_modeLabel(mode)} > ${parts.join(' > ')}';
  }

  static String _modeLabel(ShelfPageMode mode) {
    return switch (mode) {
      ShelfPageMode.favorite => t.bookshelf.favorite,
      ShelfPageMode.history => t.bookshelf.history,
      ShelfPageMode.download => t.bookshelf.download,
    };
  }
}
