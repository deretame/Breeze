import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/model/unified_comic_list_item.dart';
import 'package:zephyr/model/unified_comic_list_item_mapper.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart';
import 'package:zephyr/page/bookshelf/service/favorite_folder_service.dart';
import 'package:zephyr/page/comic_list/view/plugin_comic_grid_sliver.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/get_path.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_mapper.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_info.dart';
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
      categories: state.categories,
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

    final deleteTitle = switch (widget.mode) {
      ShelfPageMode.favorite => '删除收藏',
      ShelfPageMode.history => '删除历史记录',
      ShelfPageMode.download => '删除下载记录',
    };
    final deleteContent = switch (widget.mode) {
      ShelfPageMode.favorite => '确定要删除选中的 ${selected.length} 条收藏记录吗？',
      ShelfPageMode.history => '确定要删除选中的 ${selected.length} 条历史记录吗？',
      ShelfPageMode.download => '确定要删除选中的 ${selected.length} 条下载记录及文件吗？',
    };

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(deleteTitle),
        content: Text(deleteContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final folderKey = FavoriteFolderService.parseFolderKeyFromSources(
        _currentSearchState().sources,
      );
      final inAllFolder =
          folderKey == null || folderKey == kFavoriteFolderAllKey;
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
            break;
          case ShelfPageMode.download:
            final temp = objectbox.unifiedDownloadBox
                .query(UnifiedComicDownload_.uniqueKey.equals(uniqueKey))
                .build()
                .findFirst();
            if (temp != null) {
              objectbox.unifiedDownloadBox.remove(temp.id);
              final downloadPath = await getDownloadPath();
              final path = p.join(
                downloadPath,
                entry.from,
                'original',
                entry.id,
              );
              await deleteDirectory(path);
            }
            break;
        }
      }

      _cancelSelectionMode();
      _dispatch();
      showSuccessToast('已删除 ${selected.length} 条记录');
    } catch (_) {
      showErrorToast('批量删除失败');
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
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == BookshelfLoadStatus.failure) {
            return _buildError(state.result);
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

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: _dispatch, child: const Text('点击重试')),
        ],
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
      return Center(
        child: Column(
          children: [
            const Spacer(),
            const Text('啥都没有', style: TextStyle(fontSize: 20.0)),
            const SizedBox(height: 10),
            IconButton(onPressed: _dispatch, icon: const Icon(Icons.refresh)),
            const Spacer(),
          ],
        ),
      );
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
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: '取消',
                              onPressed: _cancelSelectionMode,
                              icon: const Icon(Icons.close),
                            ),
                            Text('已选择 ${_selectedKeys.length} 项'),
                            const Spacer(),
                            TextButton(
                              onPressed: () => _selectAll(entries),
                              child: const Text('全选'),
                            ),
                            if (widget.mode == ShelfPageMode.favorite)
                              IconButton(
                                tooltip: '加入收藏夹',
                                onPressed: () => _addSelectedToFolder(entries),
                                icon: const Icon(
                                  Icons.create_new_folder_outlined,
                                ),
                              ),
                            IconButton(
                              tooltip: '删除选中',
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
      ],
    );
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
      showErrorToast('请先创建自定义收藏夹');
      return;
    }
    final selectedFolderKeys = await _showFolderPickDialog(folders);
    if (selectedFolderKeys.isEmpty) {
      return;
    }
    for (final folderKey in selectedFolderKeys) {
      FavoriteFolderService.addMembers(folderKey, selected.map(_entryKey));
    }
    showSuccessToast('已加入收藏夹');
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
                title: const Text('选择收藏夹（可多选）'),
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
                    child: const Text('取消'),
                  ),
                  FilledButton(
                    onPressed: selected.isEmpty
                        ? null
                        : () => Navigator.of(context).pop(selected.toList()),
                    child: const Text('确定'),
                  ),
                ],
              );
            },
          ),
        )) ??
        const <String>[];
  }
}
