import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/widgets/comic_entry/models/models.dart';

import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart';
import 'package:zephyr/page/bookshelf/service/comic_link_service.dart';
import 'package:zephyr/page/bookshelf/service/download_folder_service.dart';
import 'package:zephyr/page/bookshelf/service/favorite_folder_service.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/page/comic_list/view/plugin_comic_grid_sliver.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_info.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_mapper.dart';
import 'package:zephyr/widgets/toast.dart';

class LocalShelfPage extends StatefulWidget {
  const LocalShelfPage({
    super.key,
    required this.mode,
    required this.refreshSignal,
  });

  final ShelfPageMode mode;
  final int refreshSignal;

  @override
  State<LocalShelfPage> createState() => _LocalShelfPageState();
}

class _LocalShelfPageState extends State<LocalShelfPage>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  late final BookshelfSectionBloc _bloc;
  bool _autoLoadArmed = true;
  bool _selectionMode = false;
  final Set<String> _selectedKeys = <String>{};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _bloc = BookshelfSectionBloc(mode: widget.mode);
    _scrollController.addListener(_onScroll);
    _dispatch();
  }

  @override
  void didUpdateWidget(covariant LocalShelfPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      _dispatch();
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _bloc.close();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final extentAfter = _scrollController.position.extentAfter;
    if (extentAfter > 640) {
      _autoLoadArmed = true;
      return;
    }
    if (!_autoLoadArmed || extentAfter > 320) {
      return;
    }
    _autoLoadArmed = false;
    _tryAutoLoadMore();
  }

  void _tryAutoLoadMore() {
    final section = _bloc.state;
    if (section.status != BookshelfLoadStatus.success) {
      return;
    }
    if (section.hasReachedMax ||
        section.isLoadingMore ||
        section.loadMoreFailed) {
      return;
    }
    _dispatch(append: true);
  }

  SearchEnter _buildSearchEnter(SearchStatusState state) {
    return SearchEnter(
      keyword: state.keyword,
      sort: state.sort,
      sources: state.sources,
      refresh: const Uuid().v4(),
    );
  }

  SearchStatusState _currentSearchState() {
    return context.read<BookshelfSearchCubit>().state.stateOf(widget.mode);
  }

  void _dispatch({bool append = false}) {
    _bloc.add(
      BookshelfLoadRequested(
        searchEnterConst: _buildSearchEnter(_currentSearchState()),
        append: append,
      ),
    );
  }

  void _handleItemDeleted(String uniqueKey) {
    _bloc.add(BookshelfItemRemoved(uniqueKey: uniqueKey));
  }

  String _entryKey(ComicSimplifyEntryInfo info) =>
      '${info.from.trim()}:${info.id}';

  void _enterSelectionModeWith(ComicSimplifyEntryInfo info) {
    final key = _entryKey(info);
    setState(() {
      _selectionMode = true;
      _selectedKeys.add(key);
    });
  }

  void _toggleSelection(ComicSimplifyEntryInfo info) {
    final key = _entryKey(info);
    setState(() {
      if (_selectedKeys.contains(key)) {
        _selectedKeys.remove(key);
      } else {
        _selectedKeys.add(key);
      }
      if (_selectedKeys.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  void _cancelSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedKeys.clear();
    });
  }

  void _selectAll(List<ComicSimplifyEntryInfo> entries) {
    setState(() {
      _selectedKeys
        ..clear()
        ..addAll(entries.map(_entryKey));
      _selectionMode = _selectedKeys.isNotEmpty;
    });
  }

  Future<void> _confirmBatchDelete(List<ComicSimplifyEntryInfo> entries) async {
    if (_selectedKeys.isEmpty) return;
    final selected = entries
        .where((entry) => _selectedKeys.contains(_entryKey(entry)))
        .toList();
    if (selected.isEmpty) {
      _cancelSelectionMode();
      return;
    }

    final currentFolderKey = switch (widget.mode) {
      ShelfPageMode.favorite => FavoriteFolderService.parseFolderKeyFromSources(
        _currentSearchState().sources,
      ),
      ShelfPageMode.download => DownloadFolderService.parseFolderKeyFromSources(
        _currentSearchState().sources,
      ),
      _ => null,
    };
    final inCustomFolder =
        widget.mode != ShelfPageMode.history &&
        currentFolderKey != null &&
        currentFolderKey != kFavoriteFolderAllKey &&
        currentFolderKey != kDownloadFolderAllKey;

    final deleteTitle = switch (widget.mode) {
      ShelfPageMode.favorite =>
        inCustomFolder
            ? t.bookshelf.removeFromFavoriteFolder
            : t.bookshelf.deleteFavorite,
      ShelfPageMode.history => t.bookshelf.deleteHistory,
      ShelfPageMode.download =>
        inCustomFolder
            ? t.bookshelf.removeFromDownloadFolder
            : t.bookshelf.deleteDownload,
    };
    final deleteContent = switch (widget.mode) {
      ShelfPageMode.favorite =>
        inCustomFolder
            ? t.bookshelf.confirmRemoveFromCurrentFolder
            : t.bookshelf.confirmDeleteSelectedFavorites(
                count: selected.length,
              ),
      ShelfPageMode.history => t.bookshelf.confirmDeleteSelectedHistory(
        count: selected.length,
      ),
      ShelfPageMode.download =>
        inCustomFolder
            ? t.bookshelf.confirmRemoveFromCurrentFolder
            : t.bookshelf.confirmDeleteSelectedDownloads(
                count: selected.length,
              ),
    };

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(deleteTitle),
        content: Text(deleteContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.common.ok),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final folderKey = switch (widget.mode) {
        ShelfPageMode.favorite =>
          FavoriteFolderService.parseFolderKeyFromSources(
            _currentSearchState().sources,
          ),
        ShelfPageMode.download =>
          DownloadFolderService.parseFolderKeyFromSources(
            _currentSearchState().sources,
          ),
        _ => null,
      };
      final inAllFolder =
          folderKey == null ||
          folderKey == kFavoriteFolderAllKey ||
          folderKey == kDownloadFolderAllKey;
      for (final entry in selected) {
        final uniqueKey = _entryKey(entry);
        switch (widget.mode) {
          case ShelfPageMode.favorite:
            if (!inAllFolder) {
              FavoriteFolderService.removeMembers(folderKey, [uniqueKey]);
            } else {
              final temp = objectbox.unifiedFavoriteBox
                  .query(UnifiedComicFavorite_.uniqueKey.equals(uniqueKey))
                  .build()
                  .findFirst();
              if (temp != null) {
                temp.deleted = true;
                temp.updatedAt = DateTime.now().toUtc();
                objectbox.unifiedFavoriteBox.put(temp);
                FavoriteFolderService.removeMemberFromAllFolders(uniqueKey);
                ComicLinkService.removeComicFromAll(
                  uniqueKey,
                  ComicFolderType.favorite,
                );
              }
            }
            break;
          case ShelfPageMode.history:
            final temp = objectbox.unifiedHistoryBox
                .query(UnifiedComicHistory_.uniqueKey.equals(uniqueKey))
                .build()
                .findFirst();
            if (temp != null) {
              temp.deleted = true;
              temp.updatedAt = DateTime.now().toUtc();
              objectbox.unifiedHistoryBox.put(temp);
            }
            ComicLinkService.removeComicFromAll(
              uniqueKey,
              ComicFolderType.history,
            );
            break;
          case ShelfPageMode.download:
            if (!inAllFolder) {
              DownloadFolderService.removeMembers(folderKey, [uniqueKey]);
            } else {
              final temp = objectbox.unifiedDownloadBox
                  .query(UnifiedComicDownload_.uniqueKey.equals(uniqueKey))
                  .build()
                  .findFirst();
              if (temp != null) {
                objectbox.unifiedDownloadBox.remove(temp.id);
                DownloadFolderService.removeMemberFromAllFolders(uniqueKey);
                ComicLinkService.removeComicFromAll(
                  uniqueKey,
                  ComicFolderType.download,
                );
                await deleteComicDownloadDirectory(entry.from, entry.id);
              }
            }
            break;
        }
      }

      _cancelSelectionMode();
      _dispatch();
      showSuccessToast(t.bookshelf.deletedRecords(count: selected.length));
    } catch (_) {
      showErrorToast(t.bookshelf.batchDeleteFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<BookshelfSectionBloc, BookshelfSectionState>(
        builder: (context, state) {
          if (state.status == BookshelfLoadStatus.initial) {
            return const Stack(
              children: [
                BookshelfGridShimmer(),
                Center(child: BookshelfLoadingView()),
              ],
            );
          }
          if (state.status == BookshelfLoadStatus.failure) {
            return BookshelfEmptyView(
              title: state.result.isEmpty
                  ? t.common.loadingFailed
                  : state.result,
              icon: Icons.error_outline,
              onRefresh: _dispatch,
            );
          }

          return switch (widget.mode) {
            ShelfPageMode.favorite => _buildList(
              state.comics
                  .cast<UnifiedComicFavorite>()
                  .map(unifiedComicFromUnifiedFavorite)
                  .toList(),
              type: ComicEntryType.favorite,
              hasReachedMax: state.hasReachedMax,
              isLoadingMore: state.isLoadingMore,
              loadMoreFailed: state.loadMoreFailed,
            ),
            ShelfPageMode.history => _buildList(
              state.comics
                  .cast<UnifiedComicHistory>()
                  .map(unifiedComicFromUnifiedHistory)
                  .toList(),
              type: ComicEntryType.history,
              deleteType: DeleteType.history,
              hasReachedMax: state.hasReachedMax,
              isLoadingMore: state.isLoadingMore,
              loadMoreFailed: state.loadMoreFailed,
            ),
            ShelfPageMode.download => _buildList(
              state.comics
                  .cast<UnifiedComicDownload>()
                  .map(unifiedComicFromUnifiedDownload)
                  .toList(),
              type: ComicEntryType.download,
              deleteType: DeleteType.download,
              hasReachedMax: state.hasReachedMax,
              isLoadingMore: state.isLoadingMore,
              loadMoreFailed: state.loadMoreFailed,
            ),
          };
        },
      ),
    );
  }

  Widget _buildList(
    List<UnifiedComicListItem> comics, {
    required ComicEntryType type,
    DeleteType? deleteType,
    required bool hasReachedMax,
    required bool isLoadingMore,
    required bool loadMoreFailed,
  }) {
    if (comics.isEmpty) {
      return BookshelfEmptyView(onRefresh: _dispatch);
    }

    final entries = mapToUnifiedComicSimplifyEntryInfoList(comics);
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async => _dispatch(),
          child: PluginComicGridSliver(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            entries: entries,
            type: type,
            refresh: _dispatch,
            onDeleteSuccess: _handleItemDeleted,
            hasReachedMax: hasReachedMax,
            isLoadingMore: isLoadingMore,
            loadMoreFailed: loadMoreFailed,
            onRetryLoadMore: () => _dispatch(append: true),
            onLoadMore: () => _dispatch(append: true),
            selectionMode: _selectionMode,
            isEntrySelected: (entry) =>
                _selectedKeys.contains(_entryKey(entry)),
            onEntryLongPress: (entry) {
              if (!_selectionMode) {
                _enterSelectionModeWith(entry);
                return;
              }
              _toggleSelection(entry);
            },
            onEntryTap: _selectionMode
                ? (entry) => _toggleSelection(entry)
                : null,
          ),
        ),
        Positioned(
          bottom: 8,
          left: 8,
          right: 8,
          child: IgnorePointer(
            ignoring: !_selectionMode,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              offset: _selectionMode ? Offset.zero : const Offset(0, 1.0),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                opacity: _selectionMode ? 1 : 0,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Material(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          reverse: true,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                tooltip: t.common.cancel,
                                onPressed: _cancelSelectionMode,
                                icon: const Icon(Icons.close),
                              ),
                              Text(
                                t.bookshelf.selectedCount(
                                  count: _selectedKeys.length,
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () => _selectAll(entries),
                                child: Text(t.common.selectAll),
                              ),
                              if (widget.mode == ShelfPageMode.favorite)
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  tooltip: t.bookshelf.addToFavorite,
                                  onPressed: () =>
                                      _addSelectedToFolder(entries),
                                  icon: const Icon(
                                    Icons.create_new_folder_outlined,
                                  ),
                                ),
                              if (widget.mode == ShelfPageMode.download)
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  tooltip: t.bookshelf.addToDownloadFolder,
                                  onPressed: () =>
                                      _addSelectedToDownloadFolder(entries),
                                  icon: const Icon(
                                    Icons.create_new_folder_outlined,
                                  ),
                                ),
                              if (widget.mode == ShelfPageMode.download)
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  tooltip: t.bookshelf.batchExport,
                                  onPressed: () =>
                                      _batchExportSelected(entries),
                                  icon: const Icon(Icons.file_upload_outlined),
                                ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                tooltip: t.bookshelf.deleteSelected,
                                onPressed: () => _confirmBatchDelete(entries),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _batchExportSelected(
    List<ComicSimplifyEntryInfo> entries,
  ) async {
    if (_selectedKeys.isEmpty) return;
    final selected = entries
        .where((entry) => _selectedKeys.contains(_entryKey(entry)))
        .toList();
    if (selected.isEmpty) return;

    try {
      final success = await batchExportComics(
        context: context,
        comics: selected,
      );
      if (!mounted) return;
      showSuccessToast(
        t.bookshelf.batchExportCompleted(
          success: success,
          total: selected.length,
        ),
      );
      _cancelSelectionMode();
    } catch (e) {
      if (!mounted) return;
      showErrorToast(t.bookshelf.batchExportFailed(error: e.toString()));
    }
  }

  Future<void> _addSelectedToFolder(
    List<ComicSimplifyEntryInfo> entries,
  ) async {
    if (_selectedKeys.isEmpty) return;
    final selected = entries
        .where((entry) => _selectedKeys.contains(_entryKey(entry)))
        .toList();
    if (selected.isEmpty) return;
    final folders = FavoriteFolderService.listFolders()
        .where((item) => !item.isAll)
        .toList();
    if (folders.isEmpty) {
      showErrorToast(t.bookshelf.createFavoriteFolderFirst);
      return;
    }
    final selectedFolderKeys = await _showFolderPickDialog(folders);
    if (selectedFolderKeys.isEmpty) {
      return;
    }
    for (final folderKey in selectedFolderKeys) {
      FavoriteFolderService.addMembers(folderKey, selected.map(_entryKey));
    }
    showSuccessToast(t.bookshelf.addedToFavorite);
  }

  Future<void> _addSelectedToDownloadFolder(
    List<ComicSimplifyEntryInfo> entries,
  ) async {
    if (_selectedKeys.isEmpty) return;
    final selected = entries
        .where((entry) => _selectedKeys.contains(_entryKey(entry)))
        .toList();
    if (selected.isEmpty) return;
    final folders = DownloadFolderService.listFolders()
        .where((item) => !item.isAll)
        .toList();
    if (folders.isEmpty) {
      showErrorToast(t.bookshelf.createDownloadFolderFirst);
      return;
    }
    final selectedFolderKeys = await _showDownloadFolderPickDialog(folders);
    if (selectedFolderKeys.isEmpty) {
      return;
    }
    for (final folderKey in selectedFolderKeys) {
      DownloadFolderService.addMembers(folderKey, selected.map(_entryKey));
    }
    showSuccessToast(t.bookshelf.addedToDownloadFolder);
  }

  Future<List<String>> _showFolderPickDialog(
    List<FavoriteFolderView> folders,
  ) async {
    final selected = <String>{};
    return (await showDialog<List<String>>(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(t.bookshelf.selectFavoriteFolder),
                content: SizedBox(
                  width: 360,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final folder in folders)
                        CheckboxListTile(
                          value: selected.contains(folder.key),
                          title: Text(folder.name),
                          onChanged: (value) => setState(() {
                            if (value == true) {
                              selected.add(folder.key);
                            } else {
                              selected.remove(folder.key);
                            }
                          }),
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(t.common.cancel),
                  ),
                  FilledButton(
                    onPressed: selected.isEmpty
                        ? null
                        : () => Navigator.of(context).pop(selected.toList()),
                    child: Text(t.common.ok),
                  ),
                ],
              );
            },
          ),
        )) ??
        const <String>[];
  }

  Future<List<String>> _showDownloadFolderPickDialog(
    List<DownloadFolderView> folders,
  ) async {
    final selected = <String>{};
    return (await showDialog<List<String>>(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(t.bookshelf.selectDownloadFolder),
                content: SizedBox(
                  width: 360,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final folder in folders)
                        CheckboxListTile(
                          value: selected.contains(folder.key),
                          title: Text(folder.name),
                          onChanged: (value) => setState(() {
                            if (value == true) {
                              selected.add(folder.key);
                            } else {
                              selected.remove(folder.key);
                            }
                          }),
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(t.common.cancel),
                  ),
                  FilledButton(
                    onPressed: selected.isEmpty
                        ? null
                        : () => Navigator.of(context).pop(selected.toList()),
                    child: Text(t.common.ok),
                  ),
                ],
              );
            },
          ),
        )) ??
        const <String>[];
  }
}
