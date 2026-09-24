import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/bookshelf/bloc/folder_shelf_bloc.dart';
import 'package:zephyr/page/bookshelf/cubit/bookshelf_search_cubit.dart';
import 'package:zephyr/page/bookshelf/cubit/search_status.dart';
import 'package:zephyr/page/bookshelf/method/method.dart';
import 'package:zephyr/page/bookshelf/models/shelf_page_mode.dart';
import 'package:zephyr/page/bookshelf/service/comic_folder_service.dart';
import 'package:zephyr/page/bookshelf/service/comic_link_service.dart';
import 'package:zephyr/page/bookshelf/widgets/bookshelf_empty_view.dart';
import 'package:zephyr/page/bookshelf/widgets/bookshelf_grid_shimmer.dart';
import 'package:zephyr/page/bookshelf/widgets/bookshelf_loading_view.dart';
import 'package:zephyr/page/bookshelf/widgets/folder_shelf_item.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/text/chinese_convert.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_grid.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_info.dart';
import 'package:zephyr/widgets/fluent_dropdown.dart';
import 'package:zephyr/widgets/toast.dart';

class FolderShelfPage extends StatelessWidget {
  const FolderShelfPage({
    super.key,
    required this.mode,
    this.refreshSignal = 0,
    this.isActive = true,
  });

  final ShelfPageMode mode;
  final int refreshSignal;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final search = context.read<BookshelfSearchCubit>().state.stateOf(mode);
    return BlocProvider(
      create: (_) =>
          FolderShelfBloc(mode: mode)
            ..add(FolderShelfLoadRequested(search: search)),
      child: _FolderShelfPageContent(
        refreshSignal: refreshSignal,
        search: search,
        isActive: isActive,
      ),
    );
  }
}

class _FolderShelfPageContent extends StatefulWidget {
  const _FolderShelfPageContent({
    required this.refreshSignal,
    required this.search,
    required this.isActive,
  });

  final int refreshSignal;
  final SearchStatusState search;
  final bool isActive;

  @override
  State<_FolderShelfPageContent> createState() =>
      _FolderShelfPageContentState();
}

class _FolderShelfPageContentState extends State<_FolderShelfPageContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (_isDesktop) {
      HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    }
  }

  @override
  void dispose() {
    if (_isDesktop) {
      HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    }
    super.dispose();
  }

  static bool get _isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (event.logicalKey != LogicalKeyboardKey.escape) return false;
    if (!mounted || !widget.isActive) return false;
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) return false;

    final bloc = context.read<FolderShelfBloc>();
    if (bloc.state.isRoot) return false;

    bloc.add(const FolderShelfGoBack());
    return true;
  }

  @override
  void didUpdateWidget(covariant _FolderShelfPageContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      context.read<FolderShelfBloc>().add(
        FolderShelfLoadRequested(search: widget.search),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocConsumer<FolderShelfBloc, FolderShelfState>(
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
      builder: (context, state) {
        return PopScope(
          canPop: state.isRoot,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && !state.isRoot) {
              context.read<FolderShelfBloc>().add(const FolderShelfGoBack());
            }
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: _onGridScroll,
            child: Stack(
              children: [
                Positioned.fill(child: _buildBody(context)),
                // 顶部悬浮导航：选择模式下隐藏，由底部悬浮操作条接管。
                if (!state.selectionMode) ..._buildFloatingNav(context, state),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 顶部悬浮物的显隐（滚动联动），变化时才 setState，避免逐帧重建。
  bool _navVisible = true;

  void _setNavVisible(bool visible) {
    if (_navVisible == visible || !mounted) {
      return;
    }
    setState(() => _navVisible = visible);
  }

  /// 列表滚动方向联动悬浮物：上滑浏览时隐藏，下滑/回顶时显示。
  /// 只处理垂直主列表的通知，底部横向操作条不参与；不吞通知，RefreshIndicator 照常工作。
  bool _onGridScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }
    if (notification.metrics.pixels <= notification.metrics.minScrollExtent) {
      _setNavVisible(true);
    } else if (notification is ScrollUpdateNotification &&
        notification.dragDetails != null) {
      // 手指拖动中按手指方向直接判定（比 UserScroll 更跟手）；
      // 惯性/程序滚动（dragDetails 为空）不参与，避免回顶动画中途闪烁。
      final dy = notification.dragDetails!.delta.dy;
      if (dy < 0) {
        _setNavVisible(false);
      } else if (dy > 0) {
        _setNavVisible(true);
      }
    } else if (notification is UserScrollNotification) {
      switch (notification.direction) {
        case ScrollDirection.reverse:
          _setNavVisible(false);
        case ScrollDirection.forward:
          _setNavVisible(true);
        case ScrollDirection.idle:
          break;
      }
    }
    return false;
  }

  /// 顶部悬浮物，拆成两个独立 Positioned：
  /// - 右边 ⋮ 常驻（根/非根功能一致，无出现动画）；
  /// - 面包屑只在子文件夹出现，右端留 68px 避让常驻按钮（48 按钮 + 8 间隙），滑入淡出。
  List<Widget> _buildFloatingNav(BuildContext context, FolderShelfState state) {
    // 面包屑：子文件夹 + 未上滑隐藏时才出现；右边按钮：只跟随滚动显隐。
    final pillHidden = state.isRoot || !_navVisible;
    return [
      Positioned(
        top: 8,
        right: 12,
        child: IgnorePointer(
          ignoring: !_navVisible,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            offset: _navVisible ? Offset.zero : const Offset(0, -1),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              opacity: _navVisible ? 1 : 0,
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                elevation: 4,
                child: _buildNavMenuButton(context, state),
              ),
            ),
          ),
        ),
      ),
      Positioned(
        top: 8,
        left: 12,
        right: 68,
        child: IgnorePointer(
          ignoring: pillHidden,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            offset: pillHidden ? const Offset(0, -1) : Offset.zero,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              opacity: pillHidden ? 0 : 1,
              child: _buildBreadcrumbPill(context, state),
            ),
          ),
        ),
      ),
    ];
  }

  /// 面包屑：返回 / 路径 / 回根。菜单由右端常驻按钮负责，这里不重复放。
  Widget _buildBreadcrumbPill(BuildContext context, FolderShelfState state) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.arrow_back),
              tooltip: t.common.back,
              onPressed: () => context.read<FolderShelfBloc>().add(
                const FolderShelfGoBack(),
              ),
            ),
            Expanded(
              child: Text(
                state.breadcrumbTitle,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.home),
              onPressed: () => context.read<FolderShelfBloc>().add(
                const FolderShelfGoHome(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 全局操作菜单。长按条目 → 多选已覆盖“管理”入口，这里不再重复放。
  /// 用 child 传压缩图标：14 + 20 + 14 = 48px 高，与面包屑胶囊同高。
  Widget _buildNavMenuButton(BuildContext context, FolderShelfState state) {
    return FluentPopupMenuButton<String>(
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Icon(Icons.more_vert, size: 20),
      ),
      onSelected: (value) => _onNavMenuSelected(context, value),
      itemBuilder: (context) => [
        FluentPopupMenuItem(
          value: 'multi_select',
          leading: const Icon(Icons.checklist),
          title: Text(t.bookshelf.multiSelect),
        ),
        FluentPopupMenuItem(
          value: 'new_folder',
          leading: const Icon(Icons.create_new_folder_outlined),
          title: Text(t.bookshelf.newFolder),
        ),
        if (state.mode == ShelfPageMode.download)
          FluentPopupMenuItem(
            value: 'import',
            leading: const Icon(Icons.file_download_outlined),
            title: Text(t.bookshelf.importComic),
          ),
        FluentPopupMenuItem(
          value: 'help',
          leading: const Icon(Icons.help_outline),
          title: Text(t.common.help),
        ),
      ],
    );
  }

  void _onNavMenuSelected(BuildContext context, String value) {
    switch (value) {
      case 'multi_select':
        context.read<FolderShelfBloc>().add(
          const FolderShelfEnterSelectionMode(),
        );
      case 'new_folder':
        _showCreateFolderDialog(context);
      case 'import':
        _importComic(context);
      case 'help':
        _showShelfHelpDialog(context);
    }
  }

  Future<void> _showShelfHelpDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.bookshelf.folderHint),
        content: Text(t.bookshelf.helpContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t.common.gotIt),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return BlocBuilder<BookshelfSearchCubit, BookshelfSearchState>(
      builder: (context, searchState) {
        return BlocBuilder<FolderShelfBloc, FolderShelfState>(
          builder: (context, state) {
            final keyword = _normalizeSearchText(
              searchState.stateOf(state.mode).keyword,
            );
            // 搜索时只展示漫画，不展示文件夹。
            final filteredFolders = keyword.isEmpty
                ? state.folders
                : <ComicFolder>[];
            final filteredComics = keyword.isEmpty
                ? state.comics
                : state.comics.where((c) {
                    final key = '${c.from.trim()}:${c.id}';
                    final searchText = state.comicSearchTexts[key] ?? '';
                    return searchText.contains(keyword);
                  }).toList();

            final totalCount = filteredFolders.length + filteredComics.length;
            final isInitialLoading = state.isLoading && totalCount == 0;

            if (isInitialLoading) {
              return const Stack(
                children: [
                  BookshelfGridShimmer(),
                  Center(child: BookshelfLoadingView()),
                ],
              );
            }

            if (totalCount == 0) {
              return BookshelfEmptyView(
                onRefresh: () => context.read<FolderShelfBloc>().add(
                  const FolderShelfLoadRequested(),
                ),
              );
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
              child: Stack(
                children: [
                  GridView.builder(
                    // 悬浮物盖在列表上层：子文件夹有面包屑浮栏，留 64px 顶部滚动边距；
                    // 根目录只有右上 ⋮（纯覆盖不占位），选择模式无悬浮物，均保持 10。
                    padding: EdgeInsets.fromLTRB(
                      10,
                      state.selectionMode ? 10 : (state.isRoot ? 10 : 64),
                      10,
                      10,
                    ),
                    gridDelegate: buildComicSimplifyEntryGridDelegate(),
                    itemCount: totalCount,
                    itemBuilder: (context, index) {
                      if (index < filteredFolders.length) {
                        final folder = filteredFolders[index];
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
                              ? (details) =>
                                    context.read<FolderShelfBloc>().add(
                                      FolderShelfToggleFolderSelection(
                                        folderPath,
                                      ),
                                    )
                              : (details) => _showFolderActions(
                                  context,
                                  folder,
                                  folderPath,
                                  details.globalPosition,
                                ),
                          onSecondaryTapDown: state.selectionMode
                              ? null
                              : (details) => _showFolderActions(
                                  context,
                                  folder,
                                  folderPath,
                                  details.globalPosition,
                                ),
                        );
                      }
                      final comicIndex = index - filteredFolders.length;
                      final comic = filteredComics[comicIndex];
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
                            ? (info, details) =>
                                  context.read<FolderShelfBloc>().add(
                                    FolderShelfToggleComicSelection(
                                      '${info.from.trim()}:${info.id}',
                                    ),
                                  )
                            : (info, details) => _showComicActions(
                                context,
                                info,
                                details.globalPosition,
                              ),
                        onSecondaryTapDown: state.selectionMode
                            ? null
                            : (info, details) => _showComicActions(
                                context,
                                info,
                                details.globalPosition,
                              ),
                      );
                    },
                  ),
                  if (state.isLoading)
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  _buildSelectionBar(context, state),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSelectionBar(BuildContext context, FolderShelfState state) {
    return Positioned(
      bottom: 8,
      left: 8,
      right: 8,
      child: IgnorePointer(
        ignoring: !state.selectionMode,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          offset: state.selectionMode ? Offset.zero : const Offset(0, 1.0),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 160),
            opacity: state.selectionMode ? 1 : 0,
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
                            onPressed: () => context
                                .read<FolderShelfBloc>()
                                .add(const FolderShelfExitSelectionMode()),
                            icon: const Icon(Icons.close),
                          ),
                          Text(
                            t.bookshelf.selectedCount(
                              count: state.selectedCount,
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => context
                                .read<FolderShelfBloc>()
                                .add(const FolderShelfSelectAll()),
                            child: Text(t.common.selectAll),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: t.bookshelf.moveTo,
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
                            icon: const Icon(Icons.drive_file_move_outline),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: t.bookshelf.copyTo,
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
                            icon: const Icon(Icons.folder_copy_outlined),
                          ),
                          if (state.mode == ShelfPageMode.download)
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              tooltip: t.bookshelf.batchExport,
                              onPressed: state.hasSelection
                                  ? () => _batchExportSelected(context, state)
                                  : null,
                              icon: const Icon(Icons.file_upload_outlined),
                            ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: t.common.delete,
                            onPressed: state.hasSelection
                                ? () => _confirmDeleteSelected(context)
                                : null,
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
    );
  }

  Future<void> _showCreateFolderDialog(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(t.bookshelf.createFolder),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: t.bookshelf.folderName),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(t.common.cancel),
            ),
            TextButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  Navigator.of(dialogContext).pop(text);
                }
              },
              child: Text(t.common.ok),
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
    Offset position,
  ) {
    final anchor = Rect.fromCenter(center: position, width: 1, height: 1);

    FluentPopupMenu.show<String>(
      context: context,
      anchor: anchor,
      items: [
        FluentPopupMenuItem(
          value: 'rename',
          leading: const Icon(Icons.drive_file_rename_outline),
          title: Text(t.common.rename),
        ),
        FluentPopupMenuItem(
          value: 'move',
          leading: const Icon(Icons.drive_file_move_outline),
          title: Text(t.bookshelf.moveTo),
        ),
        FluentPopupMenuItem(
          value: 'delete',
          leading: const Icon(Icons.delete_outline),
          title: Text(t.common.delete),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'rename':
            _showRenameFolderDialog(context, folder, folderPath);
          case 'move':
            unawaited(
              _showTargetFolderDialog(
                context,
                selectedFolderPaths: {folderPath},
                onConfirmed: (targets) {
                  context.read<FolderShelfBloc>().add(
                    FolderShelfMoveSelected(
                      targets,
                      sourceFolderPaths: {folderPath},
                    ),
                  );
                },
              ),
            );
          case 'delete':
            _confirmDeleteSingleFolder(context, folderPath);
        }
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
          title: Text(t.bookshelf.confirmDeleteFolderTitle),
          content: Text(t.bookshelf.confirmDeleteFolderContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(t.common.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(t.common.delete),
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
          title: Text(t.bookshelf.renameFolder),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: t.common.rename),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(t.common.cancel),
            ),
            TextButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  Navigator.of(dialogContext).pop(text);
                }
              },
              child: Text(t.common.ok),
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

  static String _normalizeSearchText(String text) {
    final lower = text.trim().toLowerCase();
    if (lower.isEmpty) return '';
    try {
      return t2s(lower);
    } catch (_) {
      return lower;
    }
  }

  void _showComicActions(
    BuildContext context,
    ComicSimplifyEntryInfo info,
    Offset position,
  ) {
    final anchor = Rect.fromCenter(center: position, width: 1, height: 1);

    FluentPopupMenu.show<String>(
      context: context,
      anchor: anchor,
      items: [
        FluentPopupMenuItem(
          value: 'multi_select',
          leading: const Icon(Icons.checklist),
          title: Text(t.bookshelf.multiSelect),
        ),
        FluentPopupMenuItem(
          value: 'delete',
          leading: const Icon(Icons.delete_outline),
          title: Text(t.common.delete),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'multi_select':
            context.read<FolderShelfBloc>().add(
              FolderShelfToggleComicSelection('${info.from.trim()}:${info.id}'),
            );
          case 'delete':
            _confirmRemoveComic(context, info);
        }
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
          title: Text(t.bookshelf.confirmRemoveComicTitle),
          content: Text(
            t.bookshelf.confirmRemoveComicContent(title: info.title),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(t.common.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(t.common.remove),
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
  Set<String>? selectedFolderPaths,
  required ValueChanged<Set<String>> onConfirmed,
}) async {
  final state = context.read<FolderShelfBloc>().state;
  final sourceFolderPaths = selectedFolderPaths ?? state.selectedFolderPaths;
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
  for (final path in sourceFolderPaths) {
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
            title: Text(t.bookshelf.selectTargetFolder),
            content: SizedBox(
              width: 380,
              height: 400,
              child: ListView(
                children: [
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const SizedBox(width: 48),
                    title: Text(t.common.root),
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
                child: Text(t.common.cancel),
              ),
              FilledButton(
                onPressed: selectedPaths.isEmpty
                    ? null
                    : () {
                        Navigator.of(dialogContext).pop();
                        onConfirmed(selectedPaths);
                      },
                child: Text(t.common.ok),
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

Future<void> _importComic(BuildContext context) async {
  String? importRoot;
  String? cleanupDir;
  try {
    if (Platform.isAndroid) {
      importRoot = await pickComicZipAndroid();
      if (importRoot != null) {
        cleanupDir = p.dirname(p.dirname(importRoot));
      }
    } else {
      final file = await openFile(
        acceptedTypeGroups: [
          const XTypeGroup(
            label: 'zip',
            extensions: ['zip'],
            uniformTypeIdentifiers: ['public.zip-archive'],
          ),
        ],
      );
      importRoot = file?.path;
    }
    if (importRoot == null || importRoot.trim().isEmpty) return;

    if (!context.mounted) return;
    showSuccessToast(t.bookshelf.importStarted);

    final result = await importComicFromZip(
      importRoot,
      cleanupDir: cleanupDir,
      onConfirmOverwrite: (title) =>
          _confirmComicImportOverwrite(context, title),
    );

    if (!context.mounted) return;
    showSuccessToast(t.bookshelf.importCompleted(title: result.title));
    context.read<FolderShelfBloc>().add(const FolderShelfLoadRequested());
  } on ComicImportCancelledException catch (_) {
    if (!context.mounted) return;
    showErrorToast(t.common.cancelled);
  } catch (e) {
    if (!context.mounted) return;
    showErrorToast(t.error.importFailed(error: e.toString()));
  }
}

Future<bool> _confirmComicImportOverwrite(
  BuildContext context,
  String title,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(t.bookshelf.comicExists),
      content: Text(t.bookshelf.confirmOverwriteImport(title: title)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(t.common.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(t.common.overwrite),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<void> _batchExportSelected(
  BuildContext context,
  FolderShelfState state,
) async {
  final selectedComics = state.comics
      .where(
        (c) => state.selectedComicKeys.contains('${c.from.trim()}:${c.id}'),
      )
      .toList();

  if (selectedComics.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.bookshelf.noExportableComics)));
    return;
  }

  try {
    final success = await batchExportComics(
      context: context,
      comics: selectedComics,
    );
    if (!context.mounted) return;
    showSuccessToast(
      t.bookshelf.batchExportCompleted(
        success: success,
        total: selectedComics.length,
      ),
    );
    context.read<FolderShelfBloc>().add(const FolderShelfExitSelectionMode());
  } catch (e) {
    if (!context.mounted) return;
    showErrorToast(t.bookshelf.batchExportFailed(error: e.toString()));
  }
}

Future<void> _confirmDeleteSelected(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(t.bookshelf.confirmDeleteSelectedTitle),
        content: Text(t.bookshelf.confirmDeleteSelectedContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t.common.delete),
          ),
        ],
      );
    },
  );
  if (confirmed == true && context.mounted) {
    context.read<FolderShelfBloc>().add(const FolderShelfDeleteSelected());
  }
}
