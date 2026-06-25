import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/bookshelf/bloc/folder_shelf_bloc.dart';
import 'package:zephyr/page/bookshelf/models/shelf_page_mode.dart';
import 'package:zephyr/page/bookshelf/service/comic_folder_service.dart';
import 'package:zephyr/page/bookshelf/service/comic_link_service.dart';
import 'package:zephyr/page/bookshelf/widgets/folder_shelf_item.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_grid.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_info.dart';

class FolderShelfPage extends StatelessWidget {
  const FolderShelfPage({
    super.key,
    required this.mode,
    this.refreshSignal = 0,
  });

  final ShelfPageMode mode;
  final int refreshSignal;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          FolderShelfBloc(mode: mode)..add(const FolderShelfLoadRequested()),
      child: _FolderShelfPageContent(refreshSignal: refreshSignal),
    );
  }
}

class _FolderShelfPageContent extends StatefulWidget {
  const _FolderShelfPageContent({required this.refreshSignal});

  final int refreshSignal;

  @override
  State<_FolderShelfPageContent> createState() =>
      _FolderShelfPageContentState();
}

class _FolderShelfPageContentState extends State<_FolderShelfPageContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void didUpdateWidget(covariant _FolderShelfPageContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      context.read<FolderShelfBloc>().add(const FolderShelfLoadRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocListener<FolderShelfBloc, FolderShelfState>(
      listenWhen: (previous, current) =>
          current.error != null && current.error != previous.error,
      listener: (context, state) {
        final error = state.error;
        if (error != null && error.isNotEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
        }
      },
      child: Column(
        children: [
          _buildHeader(context),
          const Divider(height: 1),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return BlocBuilder<FolderShelfBloc, FolderShelfState>(
      builder: (context, state) {
        return Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: SafeArea(
            bottom: false,
            child: state.selectionMode
                ? _buildSelectionHeader(context, state)
                : _buildNormalHeader(context, state),
          ),
        );
      },
    );
  }

  Widget _buildNormalHeader(BuildContext context, FolderShelfState state) {
    return Row(
      children: [
        // 返回按钮
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: state.isRoot
              ? null
              : () => context.read<FolderShelfBloc>().add(
                  const FolderShelfGoBack(),
                ),
        ),
        // 面包屑
        Expanded(
          child: Text(
            state.breadcrumbTitle,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Home 按钮
        IconButton(
          icon: const Icon(Icons.home),
          onPressed: state.isRoot
              ? null
              : () => context.read<FolderShelfBloc>().add(
                  const FolderShelfGoHome(),
                ),
        ),
        // 管理菜单
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'new_folder':
                _showCreateFolderDialog(context);
              case 'manage':
                context.read<FolderShelfBloc>().add(
                  const FolderShelfEnterSelectionMode(),
                );
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'new_folder',
              child: Row(
                children: [
                  Icon(Icons.create_new_folder_outlined),
                  SizedBox(width: 12),
                  Text('新建文件夹'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'manage',
              child: Row(
                children: [
                  Icon(Icons.checklist),
                  SizedBox(width: 12),
                  Text('管理'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectionHeader(BuildContext context, FolderShelfState state) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.read<FolderShelfBloc>().add(
            const FolderShelfExitSelectionMode(),
          ),
        ),
        Expanded(
          child: Text(
            '已选择 ${state.selectedCount} 项',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.select_all),
          tooltip: '全选',
          onPressed: () =>
              context.read<FolderShelfBloc>().add(const FolderShelfSelectAll()),
        ),
        IconButton(
          icon: const Icon(Icons.drive_file_move_outline),
          tooltip: '移动到',
          onPressed: state.hasSelection
              ? () => _showTargetFolderDialog(
                  context,
                  onConfirmed: (targets) {
                    context.read<FolderShelfBloc>().add(
                      FolderShelfMoveSelected(targets),
                    );
                  },
                )
              : null,
        ),
        IconButton(
          icon: const Icon(Icons.folder_copy_outlined),
          tooltip: '复制到',
          onPressed: state.hasSelection
              ? () => _showTargetFolderDialog(
                  context,
                  onConfirmed: (targets) {
                    context.read<FolderShelfBloc>().add(
                      FolderShelfCopySelected(targets),
                    );
                  },
                )
              : null,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: '删除',
          onPressed: state.hasSelection
              ? () => _confirmDeleteSelected(context)
              : null,
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return BlocBuilder<FolderShelfBloc, FolderShelfState>(
      builder: (context, state) {
        if (state.isLoading && state.folders.isEmpty && state.comics.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final totalCount = state.folders.length + state.comics.length;
        if (totalCount == 0) {
          return _buildEmptyBody(context);
        }

        final comicType = _comicEntryTypeOf(state.mode);
        final folderSyncIdMap = _buildSyncIdMap(state.mode);
        String folderPathOf(ComicFolder f) =>
            ComicFolderService.folderPath(f, syncIdMap: folderSyncIdMap);

        return RefreshIndicator(
          onRefresh: () async {
            context.read<FolderShelfBloc>().add(
              const FolderShelfLoadRequested(),
            );
          },
          child: GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: buildComicSimplifyEntryGridDelegate(),
            itemCount: totalCount,
            itemBuilder: (context, index) {
              if (index < state.folders.length) {
                final folder = state.folders[index];
                final folderPath = folderPathOf(folder);
                final isSelected = state.selectedFolderPaths.contains(
                  folderPath,
                );
                return FolderShelfItem(
                  key: ValueKey('folder-${folder.uniqueKey}'),
                  folder: folder,
                  selectionMode: state.selectionMode,
                  isSelected: isSelected,
                  onTap: state.selectionMode
                      ? () => context.read<FolderShelfBloc>().add(
                          FolderShelfToggleFolderSelection(folderPath),
                        )
                      : () => context.read<FolderShelfBloc>().add(
                          FolderShelfEnterFolder(folderPath),
                        ),
                  onLongPress: state.selectionMode
                      ? () => context.read<FolderShelfBloc>().add(
                          FolderShelfToggleFolderSelection(folderPath),
                        )
                      : () => _showFolderActions(context, folder, folderPath),
                );
              }
              final comicIndex = index - state.folders.length;
              final comic = state.comics[comicIndex];
              final comicUniqueKey = '${comic.from.trim()}:${comic.id}';
              final isComicSelected = state.selectedComicKeys.contains(
                comicUniqueKey,
              );
              return ComicSimplifyEntry(
                key: ValueKey('comic-${comic.from}:${comic.id}'),
                info: comic,
                type: comicType,
                selectionMode: state.selectionMode,
                isSelected: isComicSelected,
                refresh: () => context.read<FolderShelfBloc>().add(
                  const FolderShelfLoadRequested(),
                ),
                onTapOverride: state.selectionMode
                    ? (info) => context.read<FolderShelfBloc>().add(
                        FolderShelfToggleComicSelection(
                          '${info.from.trim()}:${info.id}',
                        ),
                      )
                    : null,
                onLongPressOverride: state.selectionMode
                    ? (info) => context.read<FolderShelfBloc>().add(
                        FolderShelfToggleComicSelection(
                          '${info.from.trim()}:${info.id}',
                        ),
                      )
                    : (info) => _showComicActions(context, info),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyBody(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () async {
        context.read<FolderShelfBloc>().add(const FolderShelfLoadRequested());
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_open_outlined,
                      size: 72,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '啥都没有',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        context.read<FolderShelfBloc>().add(
                          const FolderShelfLoadRequested(),
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('刷新'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showCreateFolderDialog(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('新建文件夹'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: '文件夹名称'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  Navigator.of(dialogContext).pop(text);
                }
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (name != null && name.isNotEmpty && context.mounted) {
      context.read<FolderShelfBloc>().add(FolderShelfCreateFolder(name));
    }
  }

  void _showFolderActions(
    BuildContext context,
    ComicFolder folder,
    String folderPath,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('多选'),
                leading: const Icon(Icons.checklist),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.read<FolderShelfBloc>().add(
                    FolderShelfToggleFolderSelection(folderPath),
                  );
                },
              ),
              ListTile(
                title: const Text('重命名'),
                leading: const Icon(Icons.drive_file_rename_outline),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showRenameFolderDialog(context, folder, folderPath);
                },
              ),
              ListTile(
                title: const Text('删除'),
                leading: const Icon(Icons.delete_outline),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _confirmDeleteSingleFolder(context, folderPath);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteSingleFolder(
    BuildContext context,
    String path,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: const Text('确定要删除该文件夹吗？文件夹内的内容会被递归删除。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
    if (confirmed == true && context.mounted) {
      context.read<FolderShelfBloc>().add(FolderShelfDeleteFolder(path));
    }
  }

  Future<void> _showRenameFolderDialog(
    BuildContext context,
    ComicFolder folder,
    String folderPath,
  ) async {
    final controller = TextEditingController(text: folder.name);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('重命名文件夹'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: '新名称'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  Navigator.of(dialogContext).pop(text);
                }
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (name != null && name.isNotEmpty && context.mounted) {
      context.read<FolderShelfBloc>().add(
        FolderShelfRenameFolder(folderPath, name),
      );
    }
  }

  static ComicEntryType _comicEntryTypeOf(ShelfPageMode mode) {
    return switch (mode) {
      ShelfPageMode.favorite => ComicEntryType.favorite,
      ShelfPageMode.history => ComicEntryType.history,
      ShelfPageMode.download => ComicEntryType.download,
    };
  }

  void _showComicActions(BuildContext context, ComicSimplifyEntryInfo info) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('多选'),
                leading: const Icon(Icons.checklist),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.read<FolderShelfBloc>().add(
                    FolderShelfToggleComicSelection(
                      '${info.from.trim()}:${info.id}',
                    ),
                  );
                },
              ),
              ListTile(
                title: const Text('删除'),
                leading: const Icon(Icons.delete_outline),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _confirmRemoveComic(context, info);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmRemoveComic(
    BuildContext context,
    ComicSimplifyEntryInfo info,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('从文件夹移除'),
          content: Text('确定要从当前文件夹移除《${info.title}》吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('移除'),
            ),
          ],
        );
      },
    );
    if (confirmed == true && context.mounted) {
      final uniqueKey = '${info.from.trim()}:${info.id}';
      final state = context.read<FolderShelfBloc>().state;
      final folderType = switch (state.mode) {
        ShelfPageMode.favorite => ComicFolderType.favorite,
        ShelfPageMode.download => ComicFolderType.download,
        ShelfPageMode.history => ComicFolderType.history,
      };
      ComicLinkService.removeComic(
        uniqueKey,
        state.currentPath.isEmpty ? null : state.currentPath,
        folderType,
      );
      context.read<FolderShelfBloc>().add(const FolderShelfLoadRequested());
    }
  }
}

Future<void> _showTargetFolderDialog(
  BuildContext context, {
  required ValueChanged<Set<String>> onConfirmed,
}) async {
  final state = context.read<FolderShelfBloc>().state;
  final allFolders = ComicFolderService.listAllFolders(
    _folderTypeOf(state.mode),
  );
  final syncIdMap = _buildSyncIdMap(state.mode);
  final pathMap = {
    for (final folder in allFolders)
      folder.syncId: ComicFolderService.folderPath(
        folder,
        syncIdMap: syncIdMap,
      ),
  };
  final forest = _buildFolderForest(allFolders, pathMap);

  // 排除当前所在文件夹（仅自身）、被选中的文件夹及其子树
  final forbiddenSyncIds = <String>{};
  for (final path in state.selectedFolderPaths) {
    final folder = allFolders.firstWhereOrNull(
      (f) => pathMap[f.syncId] == path,
    );
    if (folder != null) {
      _collectForbiddenSyncIds(folder.syncId, allFolders, forbiddenSyncIds);
    }
  }
  final currentPath = state.currentPath;
  final isRoot = currentPath.isEmpty;
  final currentFolder = isRoot
      ? null
      : allFolders.firstWhereOrNull((f) => pathMap[f.syncId] == currentPath);
  final currentSyncId = currentFolder?.syncId;

  final selectedPaths = <String>{};

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final expandedPaths = <String>{};
      return StatefulBuilder(
        builder: (ctx, setState) {
          void togglePath(String path) {
            setState(() {
              if (selectedPaths.contains(path)) {
                selectedPaths.remove(path);
              } else {
                selectedPaths.add(path);
              }
            });
          }

          return AlertDialog(
            title: const Text('选择目标文件夹（可多选）'),
            content: SizedBox(
              width: 380,
              height: 400,
              child: ListView(
                children: [
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const SizedBox(width: 48),
                    title: const Text('根目录'),
                    trailing: Checkbox(
                      value: selectedPaths.contains(kComicFolderRootPath),
                      onChanged: isRoot
                          ? null
                          : (_) => togglePath(kComicFolderRootPath),
                    ),
                    onTap: isRoot
                        ? null
                        : () => togglePath(kComicFolderRootPath),
                  ),
                  const Divider(),
                  ...forest.map(
                    (node) => _buildFolderTreeTile(
                      context: ctx,
                      node: node,
                      pathMap: pathMap,
                      expandedPaths: expandedPaths,
                      forbiddenSyncIds: forbiddenSyncIds,
                      currentSyncId: currentSyncId,
                      selectedPaths: selectedPaths,
                      onToggleExpand: (path) => setState(() {
                        if (expandedPaths.contains(path)) {
                          expandedPaths.remove(path);
                        } else {
                          expandedPaths.add(path);
                        }
                      }),
                      onSelect: togglePath,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: selectedPaths.isEmpty
                    ? null
                    : () {
                        Navigator.of(dialogContext).pop();
                        onConfirmed(selectedPaths);
                      },
                child: const Text('确定'),
              ),
            ],
          );
        },
      );
    },
  );
}

class _FolderNode {
  final ComicFolder folder;
  final List<_FolderNode> children;

  _FolderNode(this.folder) : children = [];
}

List<_FolderNode> _buildFolderForest(
  List<ComicFolder> folders,
  Map<String, String> pathMap,
) {
  final sorted = folders.toList()
    ..sort(
      (a, b) => (pathMap[a.syncId] ?? '').compareTo(pathMap[b.syncId] ?? ''),
    );
  final map = <String, _FolderNode>{};
  final roots = <_FolderNode>[];
  for (final folder in sorted) {
    final node = _FolderNode(folder);
    map[folder.syncId] = node;
    final parentSyncId = folder.parentSyncId;
    if (parentSyncId == null || parentSyncId.isEmpty) {
      roots.add(node);
    } else {
      map[parentSyncId]?.children.add(node);
    }
  }
  return roots;
}

Map<String, ComicFolder> _buildSyncIdMap(ShelfPageMode mode) {
  final allFolders = ComicFolderService.listAllFolders(_folderTypeOf(mode));
  return {for (final folder in allFolders) folder.syncId: folder};
}

void _collectForbiddenSyncIds(
  String syncId,
  List<ComicFolder> allFolders,
  Set<String> result,
) {
  if (!result.add(syncId)) return;
  for (final child in allFolders) {
    if (child.parentSyncId == syncId) {
      _collectForbiddenSyncIds(child.syncId, allFolders, result);
    }
  }
}

Widget _buildFolderTreeTile({
  required BuildContext context,
  required _FolderNode node,
  required Map<String, String> pathMap,
  required Set<String> expandedPaths,
  required Set<String> forbiddenSyncIds,
  required String? currentSyncId,
  required Set<String> selectedPaths,
  required ValueChanged<String> onToggleExpand,
  required ValueChanged<String> onSelect,
}) {
  final path = pathMap[node.folder.syncId] ?? '/${node.folder.name}';
  final syncId = node.folder.syncId;
  final isExpanded = expandedPaths.contains(path);
  final isCurrentPath = currentSyncId != null && syncId == currentSyncId;
  final isForbidden = isCurrentPath || forbiddenSyncIds.contains(syncId);
  final hasChildren = node.children.isNotEmpty;
  final theme = Theme.of(context);
  final isSelected = selectedPaths.contains(path) && !isForbidden;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: hasChildren
            ? IconButton(
                icon: Icon(
                  isExpanded ? Icons.expand_more : Icons.chevron_right,
                ),
                onPressed: () => onToggleExpand(path),
              )
            : const SizedBox(width: 48),
        title: Text(
          node.folder.name,
          style: isForbidden ? TextStyle(color: theme.disabledColor) : null,
        ),
        trailing: Checkbox(
          value: isSelected,
          onChanged: isForbidden ? null : (_) => onSelect(path),
        ),
        onTap: isForbidden ? null : () => onSelect(path),
      ),
      if (isExpanded)
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: node.children
                .map(
                  (child) => _buildFolderTreeTile(
                    context: context,
                    node: child,
                    pathMap: pathMap,
                    expandedPaths: expandedPaths,
                    forbiddenSyncIds: forbiddenSyncIds,
                    currentSyncId: currentSyncId,
                    selectedPaths: selectedPaths,
                    onToggleExpand: onToggleExpand,
                    onSelect: onSelect,
                  ),
                )
                .toList(),
          ),
        ),
    ],
  );
}

ComicFolderType _folderTypeOf(ShelfPageMode mode) {
  return switch (mode) {
    ShelfPageMode.favorite => ComicFolderType.favorite,
    ShelfPageMode.download => ComicFolderType.download,
    ShelfPageMode.history => ComicFolderType.history,
  };
}

Future<void> _confirmDeleteSelected(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除选中的文件夹和漫画吗？文件夹会递归删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('删除'),
          ),
        ],
      );
    },
  );
  if (confirmed == true && context.mounted) {
    context.read<FolderShelfBloc>().add(const FolderShelfDeleteSelected());
  }
}
