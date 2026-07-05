import 'dart:convert';
import 'package:flutter/services.dart';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:worker_manager/worker_manager.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/model/unified_comic_list_item_mapper.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/object_box/object_box.dart';
import 'package:zephyr/page/bookshelf/cubit/search_status.dart';
import 'package:zephyr/page/bookshelf/models/shelf_page_mode.dart';
import 'package:zephyr/page/bookshelf/service/comic_folder_service.dart';
import 'package:zephyr/page/bookshelf/service/comic_link_service.dart';
import 'package:zephyr/page/bookshelf/service/download_folder_service.dart';
import 'package:zephyr/page/bookshelf/service/favorite_folder_service.dart';
import 'package:zephyr/util/rust_loader.dart';
import 'package:zephyr/util/sundry.dart';
import 'package:zephyr/util/worker_isolate.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_info.dart';

const String kFolderShelfRootPath = '';

class FolderShelfState extends Equatable {
  const FolderShelfState({
    required this.mode,
    this.currentPath = kFolderShelfRootPath,
    this.folders = const <ComicFolder>[],
    this.comics = const <ComicSimplifyEntryInfo>[],
    this.comicSearchTexts = const <String, String>{},
    this.search,
    this.isLoading = false,
    this.error,
    this.sortAscending = false,
    this.selectionMode = false,
    this.selectedFolderPaths = const <String>{},
    this.selectedComicKeys = const <String>{},
  });

  final ShelfPageMode mode;
  final String currentPath;
  final List<ComicFolder> folders;
  final List<ComicSimplifyEntryInfo> comics;
  final Map<String, String> comicSearchTexts;
  final SearchStatusState? search;
  final bool isLoading;
  final String? error;
  final bool sortAscending;
  final bool selectionMode;
  final Set<String> selectedFolderPaths;
  final Set<String> selectedComicKeys;

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

  FolderShelfState copyWith({
    ShelfPageMode? mode,
    String? currentPath,
    List<ComicFolder>? folders,
    List<ComicSimplifyEntryInfo>? comics,
    Map<String, String>? comicSearchTexts,
    SearchStatusState? search,
    bool? isLoading,
    String? error,
    bool? sortAscending,
    bool? selectionMode,
    Set<String>? selectedFolderPaths,
    Set<String>? selectedComicKeys,
  }) {
    return FolderShelfState(
      mode: mode ?? this.mode,
      currentPath: currentPath ?? this.currentPath,
      folders: folders ?? this.folders,
      comics: comics ?? this.comics,
      comicSearchTexts: comicSearchTexts ?? this.comicSearchTexts,
      search: search ?? this.search,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      sortAscending: sortAscending ?? this.sortAscending,
      selectionMode: selectionMode ?? this.selectionMode,
      selectedFolderPaths: selectedFolderPaths ?? this.selectedFolderPaths,
      selectedComicKeys: selectedComicKeys ?? this.selectedComicKeys,
    );
  }

  @override
  List<Object?> get props => [
    mode,
    currentPath,
    folders,
    comics,
    comicSearchTexts,
    search,
    isLoading,
    error,
    sortAscending,
    selectionMode,
    selectedFolderPaths,
    selectedComicKeys,
  ];

  static String _modeLabel(ShelfPageMode mode) {
    return switch (mode) {
      ShelfPageMode.favorite => '收藏',
      ShelfPageMode.history => '历史',
      ShelfPageMode.download => '下载',
    };
  }
}

sealed class FolderShelfEvent extends Equatable {
  const FolderShelfEvent();

  @override
  List<Object?> get props => [];
}

class FolderShelfLoadRequested extends FolderShelfEvent {
  const FolderShelfLoadRequested({this.search});

  final SearchStatusState? search;

  @override
  List<Object?> get props => [search];
}

class FolderShelfEnterFolder extends FolderShelfEvent {
  const FolderShelfEnterFolder(this.path);

  final String path;

  @override
  List<Object?> get props => [path];
}

class FolderShelfGoBack extends FolderShelfEvent {
  const FolderShelfGoBack();
}

class FolderShelfGoHome extends FolderShelfEvent {
  const FolderShelfGoHome();
}

class FolderShelfToggleSort extends FolderShelfEvent {
  const FolderShelfToggleSort();
}

class FolderShelfCreateFolder extends FolderShelfEvent {
  const FolderShelfCreateFolder(this.name);

  final String name;

  @override
  List<Object?> get props => [name];
}

class FolderShelfDeleteFolder extends FolderShelfEvent {
  const FolderShelfDeleteFolder(this.path);

  final String path;

  @override
  List<Object?> get props => [path];
}

class FolderShelfRenameFolder extends FolderShelfEvent {
  const FolderShelfRenameFolder(this.path, this.newName);

  final String path;
  final String newName;

  @override
  List<Object?> get props => [path, newName];
}

class FolderShelfEnterSelectionMode extends FolderShelfEvent {
  const FolderShelfEnterSelectionMode();
}

class FolderShelfExitSelectionMode extends FolderShelfEvent {
  const FolderShelfExitSelectionMode();
}

class FolderShelfToggleFolderSelection extends FolderShelfEvent {
  const FolderShelfToggleFolderSelection(this.path);

  final String path;

  @override
  List<Object?> get props => [path];
}

class FolderShelfToggleComicSelection extends FolderShelfEvent {
  const FolderShelfToggleComicSelection(this.comicUniqueKey);

  final String comicUniqueKey;

  @override
  List<Object?> get props => [comicUniqueKey];
}

class FolderShelfSelectAll extends FolderShelfEvent {
  const FolderShelfSelectAll();
}

class FolderShelfMoveSelected extends FolderShelfEvent {
  const FolderShelfMoveSelected(this.targetPaths);

  final Set<String> targetPaths;

  @override
  List<Object?> get props => [targetPaths];
}

class FolderShelfCopySelected extends FolderShelfEvent {
  const FolderShelfCopySelected(this.targetPaths);

  final Set<String> targetPaths;

  @override
  List<Object?> get props => [targetPaths];
}

class FolderShelfDeleteSelected extends FolderShelfEvent {
  const FolderShelfDeleteSelected();
}

class FolderShelfBloc extends Bloc<FolderShelfEvent, FolderShelfState> {
  FolderShelfBloc({required ShelfPageMode mode})
    : super(FolderShelfState(mode: mode)) {
    on<FolderShelfLoadRequested>(_onLoadRequested);
    on<FolderShelfEnterFolder>(_onEnterFolder);
    on<FolderShelfGoBack>(_onGoBack);
    on<FolderShelfGoHome>(_onGoHome);
    on<FolderShelfToggleSort>(_onToggleSort);
    on<FolderShelfCreateFolder>(_onCreateFolder);
    on<FolderShelfDeleteFolder>(_onDeleteFolder);
    on<FolderShelfRenameFolder>(_onRenameFolder);
    on<FolderShelfEnterSelectionMode>(_onEnterSelectionMode);
    on<FolderShelfExitSelectionMode>(_onExitSelectionMode);
    on<FolderShelfToggleFolderSelection>(_onToggleFolderSelection);
    on<FolderShelfToggleComicSelection>(_onToggleComicSelection);
    on<FolderShelfSelectAll>(_onSelectAll);
    on<FolderShelfMoveSelected>(_onMoveSelected);
    on<FolderShelfCopySelected>(_onCopySelected);
    on<FolderShelfDeleteSelected>(_onDeleteSelected);
  }

  ComicFolderType get _folderType => _toFolderType(state.mode);

  static ComicFolderType _toFolderType(ShelfPageMode mode) {
    return switch (mode) {
      ShelfPageMode.favorite => ComicFolderType.favorite,
      ShelfPageMode.history => ComicFolderType.history,
      ShelfPageMode.download => ComicFolderType.download,
    };
  }

  Future<void> _onLoadRequested(
    FolderShelfLoadRequested event,
    Emitter<FolderShelfState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final search = event.search ?? state.search;
      final currentMode = state.mode;
      final currentPath = state.currentPath;
      final token = captureWorkerIsolateToken();
      final payload = {
        'mode': currentMode.name,
        'currentPath': currentPath,
        'keyword': search?.keyword ?? '',
        'sort': search?.sort ?? 'dd',
        'sources': search?.sources ?? const <String>[],
      };
      final result = await workerManager.execute<Map<String, dynamic>>(
        () => _runFolderShelfLoadTask(payload, token),
      );

      final error = result['error']?.toString() ?? '';
      if (error.isNotEmpty) {
        throw Exception(error);
      }

      emit(
        state.copyWith(
          folders: result['folders'] as List<ComicFolder>,
          comics: result['comics'] as List<ComicSimplifyEntryInfo>,
          comicSearchTexts:
              (result['comicSearchTexts'] as Map?)?.cast<String, String>() ??
              const <String, String>{},
          search: search,
          sortAscending: search?.sort == 'da',
          isLoading: false,
          error: null,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onEnterFolder(
    FolderShelfEnterFolder event,
    Emitter<FolderShelfState> emit,
  ) async {
    emit(state.copyWith(currentPath: event.path));
    add(const FolderShelfLoadRequested());
  }

  Future<void> _onGoBack(
    FolderShelfGoBack event,
    Emitter<FolderShelfState> emit,
  ) async {
    if (state.isRoot) return;
    final lastIndex = state.currentPath.lastIndexOf('/');
    final parentPath = lastIndex <= 0
        ? kFolderShelfRootPath
        : state.currentPath.substring(0, lastIndex);
    emit(state.copyWith(currentPath: parentPath));
    add(const FolderShelfLoadRequested());
  }

  Future<void> _onGoHome(
    FolderShelfGoHome event,
    Emitter<FolderShelfState> emit,
  ) async {
    if (state.isRoot) return;
    emit(state.copyWith(currentPath: kFolderShelfRootPath));
    add(const FolderShelfLoadRequested());
  }

  Future<void> _onToggleSort(
    FolderShelfToggleSort event,
    Emitter<FolderShelfState> emit,
  ) async {
    emit(state.copyWith(sortAscending: !state.sortAscending));
    add(const FolderShelfLoadRequested());
  }

  Future<void> _onCreateFolder(
    FolderShelfCreateFolder event,
    Emitter<FolderShelfState> emit,
  ) async {
    try {
      ComicFolderService.createFolder(
        state.currentPath,
        event.name,
        _folderType,
      );
      add(const FolderShelfLoadRequested());
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onDeleteFolder(
    FolderShelfDeleteFolder event,
    Emitter<FolderShelfState> emit,
  ) async {
    try {
      ComicFolderService.deleteFolder(event.path, _folderType);
      ComicLinkService.removeLinksInFolderTree(event.path, _folderType);
      add(const FolderShelfLoadRequested());
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onRenameFolder(
    FolderShelfRenameFolder event,
    Emitter<FolderShelfState> emit,
  ) async {
    try {
      ComicFolderService.renameFolder(event.path, event.newName, _folderType);
      add(const FolderShelfLoadRequested());
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onEnterSelectionMode(
    FolderShelfEnterSelectionMode event,
    Emitter<FolderShelfState> emit,
  ) async {
    emit(state.copyWith(selectionMode: true));
  }

  Future<void> _onExitSelectionMode(
    FolderShelfExitSelectionMode event,
    Emitter<FolderShelfState> emit,
  ) async {
    emit(
      state.copyWith(
        selectionMode: false,
        selectedFolderPaths: const <String>{},
        selectedComicKeys: const <String>{},
      ),
    );
  }

  Future<void> _onToggleFolderSelection(
    FolderShelfToggleFolderSelection event,
    Emitter<FolderShelfState> emit,
  ) async {
    final selected = Set<String>.from(state.selectedFolderPaths);
    if (selected.contains(event.path)) {
      selected.remove(event.path);
    } else {
      selected.add(event.path);
    }
    emit(state.copyWith(selectionMode: true, selectedFolderPaths: selected));
  }

  Future<void> _onToggleComicSelection(
    FolderShelfToggleComicSelection event,
    Emitter<FolderShelfState> emit,
  ) async {
    final selected = Set<String>.from(state.selectedComicKeys);
    if (selected.contains(event.comicUniqueKey)) {
      selected.remove(event.comicUniqueKey);
    } else {
      selected.add(event.comicUniqueKey);
    }
    emit(state.copyWith(selectionMode: true, selectedComicKeys: selected));
  }

  Future<void> _onSelectAll(
    FolderShelfSelectAll event,
    Emitter<FolderShelfState> emit,
  ) async {
    final syncIdMap = _buildSyncIdMap(_folderType);
    final allFolders = state.folders
        .map((f) => ComicFolderService.folderPath(f, syncIdMap: syncIdMap))
        .toSet();
    final allComics = state.comics
        .map((c) => '${c.from.trim()}:${c.id}')
        .toSet();
    emit(
      state.copyWith(
        selectionMode: true,
        selectedFolderPaths: allFolders,
        selectedComicKeys: allComics,
      ),
    );
  }

  Map<String, ComicFolder> _buildSyncIdMap(ComicFolderType type) {
    final all = ComicFolderService.listAllFolders(type);
    return {for (final folder in all) folder.syncId: folder};
  }

  Future<void> _onMoveSelected(
    FolderShelfMoveSelected event,
    Emitter<FolderShelfState> emit,
  ) async {
    try {
      final targetPaths = event.targetPaths;
      if (state.selectedFolderPaths.isNotEmpty && targetPaths.length > 1) {
        throw StateError('移动文件夹时只能选择一个目标文件夹');
      }
      for (final targetPath in targetPaths) {
        if (state.selectedFolderPaths.isNotEmpty) {
          ComicFolderService.batchMoveFolders(
            state.selectedFolderPaths,
            targetPath,
            _folderType,
          );
        }
        ComicLinkService.batchMoveComics(
          state.selectedComicKeys,
          state.currentPath.isEmpty ? null : state.currentPath,
          targetPath,
          _folderType,
        );
      }
      _exitSelectionAndRefresh();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onCopySelected(
    FolderShelfCopySelected event,
    Emitter<FolderShelfState> emit,
  ) async {
    try {
      for (final targetPath in event.targetPaths) {
        ComicFolderService.batchCopyFolders(
          state.selectedFolderPaths,
          targetPath,
          _folderType,
        );
        ComicLinkService.batchCopyComics(
          state.selectedComicKeys,
          targetPath,
          _folderType,
        );
      }
      _exitSelectionAndRefresh();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onDeleteSelected(
    FolderShelfDeleteSelected event,
    Emitter<FolderShelfState> emit,
  ) async {
    try {
      ComicFolderService.batchDeleteFolders(
        state.selectedFolderPaths,
        _folderType,
      );
      for (final folderPath in state.selectedFolderPaths) {
        ComicLinkService.removeLinksInFolderTree(folderPath, _folderType);
      }
      ComicLinkService.batchRemoveComics(
        state.selectedComicKeys,
        state.currentPath.isEmpty ? null : state.currentPath,
        _folderType,
      );
      _exitSelectionAndRefresh();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void _exitSelectionAndRefresh() {
    add(const FolderShelfExitSelectionMode());
    add(const FolderShelfLoadRequested());
  }
}

Future<Map<String, dynamic>> _runFolderShelfLoadTask(
  Map<String, dynamic> payload,
  RootIsolateToken? token,
) async {
  try {
    ensureWorkerIsolateInitialized(token);
    await initRustLib(silent: true);
    objectbox = await ObjectBox.create();

    final mode = ShelfPageMode.values.byName(payload['mode'] as String);
    final folderType = FolderShelfBloc._toFolderType(mode);
    final currentPath = payload['currentPath'] as String;
    final keyword = payload['keyword']?.toString() ?? '';
    final sort = payload['sort']?.toString() ?? 'dd';
    final sources =
        (payload['sources'] as List?)?.cast<String>() ?? const <String>[];
    final search = SearchStatusState(
      keyword: keyword,
      sort: sort,
      sources: sources,
    );

    final sortAscending = sort == 'da';
    final sourceFilter = _sourceFilterFromSearch(search, folderType);
    final folderMembers = _folderMembersFromSearch(search, folderType);

    // 搜索时不应被“当前所在文件夹”限制，而是全局搜索该类型下的全部漫画。
    final isSearching = keyword.trim().isNotEmpty;
    final normalizedKeyword = isSearching ? _normalizeSearchText(keyword) : '';
    final folders = isSearching
        ? <ComicFolder>[]
        : ComicFolderService.listChildFolders(
            currentPath,
            folderType,
            sortAscending: sortAscending,
          );
    final links = isSearching
        ? ComicLinkService.listAllLinks(
            folderType,
            sortAscending: sortAscending,
          )
        : ComicLinkService.listLinks(
            currentPath.isEmpty ? null : currentPath,
            folderType,
            sortAscending: sortAscending,
          );

    final comics = <ComicSimplifyEntryInfo>[];
    final comicSearchTexts = <String, String>{};
    final seenKeys = <String>{};
    for (final link in links) {
      if (folderMembers != null &&
          !folderMembers.contains(link.comicUniqueKey)) {
        continue;
      }
      final resolved = _resolveComic(link.comicUniqueKey, folderType);
      if (resolved == null) continue;
      if (sourceFilter != null &&
          !sourceFilter.contains(resolved.info.source)) {
        continue;
      }
      final key = '${resolved.info.from.trim()}:${resolved.info.id}';
      if (!seenKeys.add(key)) continue;
      if (isSearching && !resolved.searchText.contains(normalizedKeyword)) {
        continue;
      }
      comics.add(resolved.info);
      comicSearchTexts[key] = resolved.searchText;
    }

    return {
      'folders': folders,
      'comics': comics,
      'comicSearchTexts': comicSearchTexts,
    };
  } catch (e) {
    return {
      'error': e.toString(),
      'folders': <ComicFolder>[],
      'comics': <ComicSimplifyEntryInfo>[],
      'comicSearchTexts': <String, String>{},
    };
  }
}

Set<String>? _sourceFilterFromSearch(
  SearchStatusState? search,
  ComicFolderType folderType,
) {
  if (search == null) return null;
  final sources = switch (folderType) {
    ComicFolderType.favorite => FavoriteFolderService.stripFolderSourceTokens(
      search.sources,
    ),
    ComicFolderType.download => DownloadFolderService.stripFolderSourceTokens(
      search.sources,
    ),
    ComicFolderType.history => search.sources,
  };
  final cleaned = sources
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toSet();
  if (cleaned.isEmpty) return null;
  return cleaned;
}

Set<String>? _folderMembersFromSearch(
  SearchStatusState? search,
  ComicFolderType folderType,
) {
  if (search == null) return null;
  final folderKey = switch (folderType) {
    ComicFolderType.favorite => FavoriteFolderService.parseFolderKeyFromSources(
      search.sources,
    ),
    ComicFolderType.download => DownloadFolderService.parseFolderKeyFromSources(
      search.sources,
    ),
    ComicFolderType.history => null,
  };
  if (folderKey == null) return null;
  final isAllFolder = switch (folderType) {
    ComicFolderType.favorite => folderKey == kFavoriteFolderAllKey,
    ComicFolderType.download => folderKey == kDownloadFolderAllKey,
    ComicFolderType.history => true,
  };
  if (isAllFolder) return null;
  final members = switch (folderType) {
    ComicFolderType.favorite => FavoriteFolderService.membersOf(folderKey),
    ComicFolderType.download => DownloadFolderService.membersOf(folderKey),
    ComicFolderType.history => const <String>{},
  };
  if (members.isEmpty) return const <String>{};
  return members;
}

({ComicSimplifyEntryInfo info, String searchText})? _resolveComic(
  String uniqueKey,
  ComicFolderType folderType,
) {
  switch (folderType) {
    case ComicFolderType.favorite:
      final comic = objectbox.unifiedFavoriteBox
          .query(
            UnifiedComicFavorite_.uniqueKey
                .equals(uniqueKey)
                .and(UnifiedComicFavorite_.deleted.equals(false)),
          )
          .build()
          .findFirst();
      if (comic == null) return null;
      return (
        info: unifiedComicFromUnifiedFavorite(comic).toSimplifyEntryInfo(),
        searchText: _buildComicSearchText(comic),
      );
    case ComicFolderType.download:
      final comic = objectbox.unifiedDownloadBox
          .query(
            UnifiedComicDownload_.uniqueKey
                .equals(uniqueKey)
                .and(UnifiedComicDownload_.deleted.equals(false)),
          )
          .build()
          .findFirst();
      if (comic == null) return null;
      return (
        info: unifiedComicFromUnifiedDownload(comic).toSimplifyEntryInfo(),
        searchText: _buildComicSearchText(comic),
      );
    case ComicFolderType.history:
      final comic = objectbox.unifiedHistoryBox
          .query(
            UnifiedComicHistory_.uniqueKey
                .equals(uniqueKey)
                .and(UnifiedComicHistory_.deleted.equals(false)),
          )
          .build()
          .findFirst();
      if (comic == null) return null;
      return (
        info: unifiedComicFromUnifiedHistory(comic).toSimplifyEntryInfo(),
        searchText: _buildComicSearchText(comic),
      );
  }
}

String _buildComicSearchText(dynamic comic) {
  final text = [
    comic.comicId?.toString() ?? '',
    comic.title?.toString() ?? '',
    comic.description?.toString() ?? '',
    _creatorName(comic.creator?.toString() ?? ''),
    comic.titleMeta?.toString() ?? '',
    comic.metadata?.toString() ?? '',
    comic.source?.toString() ?? '',
  ].join();
  return _normalizeSearchText(text);
}

String _creatorName(String raw) {
  if (raw.trim().isEmpty) return '';
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) return decoded['name']?.toString() ?? '';
  } catch (_) {}
  return '';
}

String _normalizeSearchText(String text) {
  final lower = text.trim().toLowerCase();
  if (lower.isEmpty) return '';
  try {
    return t2s(lower);
  } catch (_) {
    return lower;
  }
}
