import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/model/unified_comic_list_item_mapper.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/bookshelf/models/shelf_page_mode.dart';
import 'package:zephyr/page/bookshelf/service/comic_folder_service.dart';
import 'package:zephyr/page/bookshelf/service/comic_link_service.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_info.dart';

const String kFolderShelfRootPath = '';

class FolderShelfState extends Equatable {
  const FolderShelfState({
    required this.mode,
    this.currentPath = kFolderShelfRootPath,
    this.folders = const <ComicFolder>[],
    this.comics = const <ComicSimplifyEntryInfo>[],
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
  const FolderShelfLoadRequested();
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
      final folders = ComicFolderService.listChildFolders(
        state.currentPath,
        _folderType,
        sortAscending: state.sortAscending,
      );
      final links = ComicLinkService.listLinks(
        state.currentPath.isEmpty ? null : state.currentPath,
        _folderType,
        sortAscending: state.sortAscending,
      );
      final comics = <ComicSimplifyEntryInfo>[];
      for (final link in links) {
        final info = _resolveComic(link.comicUniqueKey);
        if (info != null) {
          comics.add(info);
        }
      }
      emit(
        state.copyWith(
          folders: folders,
          comics: comics,
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

  ComicSimplifyEntryInfo? _resolveComic(String uniqueKey) {
    switch (_folderType) {
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
        return unifiedComicFromUnifiedFavorite(comic).toSimplifyEntryInfo();
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
        return unifiedComicFromUnifiedDownload(comic).toSimplifyEntryInfo();
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
        return unifiedComicFromUnifiedHistory(comic).toSimplifyEntryInfo();
    }
  }
}
