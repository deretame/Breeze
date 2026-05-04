import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/cubit/plugin_registry_cubit.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart' hide SearchEnter;
import 'package:zephyr/page/bookshelf/service/favorite_folder_service.dart';
import 'package:zephyr/plugin/plugin_registry_service.dart';
import 'package:zephyr/util/context/context_extensions.dart';

@RoutePage()
class BookshelfPage extends StatelessWidget {
  const BookshelfPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<BookshelfSearchCubit>(
          create: (context) => BookshelfSearchCubit(),
        ),
      ],
      child: const _BookshelfPageContent(),
    );
  }
}

class _BookshelfPageContent extends StatefulWidget {
  const _BookshelfPageContent();

  @override
  State<_BookshelfPageContent> createState() => _BookshelfPageContentState();
}

class _BookshelfPageContentState extends State<_BookshelfPageContent>
    with SingleTickerProviderStateMixin {
  static const List<String> _labels = ['收藏', '历史', '下载'];

  int _currentIndex = 0;
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final List<int> _refreshSignals = [0, 0, 0];
  List<String> _lastAvailableSources = const <String>[];
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _labels.length, vsync: this)
      ..addListener(_handleTabControllerChanged);
    _syncSourcesFromRegistry(context.read<PluginRegistryCubit>().state);
    _syncSearchFieldWithCurrentMode();
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_handleTabControllerChanged)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    return BlocListener<PluginRegistryCubit, Map<String, PluginRuntimeState>>(
      listenWhen: (previous, current) =>
          _pluginAvailabilityRevision(previous) !=
          _pluginAvailabilityRevision(current),
      listener: (context, pluginStates) {
        _syncSourcesFromRegistry(pluginStates);
        _triggerRefreshAll();
      },
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: isDesktop ? 16 : 8,
          title: isDesktop ? _buildDesktopHeader() : _buildMobileHeader(),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            LocalShelfPage(
              mode: ShelfPageMode.favorite,
              refreshSignal: _refreshSignals[0],
            ),
            LocalShelfPage(
              mode: ShelfPageMode.history,
              refreshSignal: _refreshSignals[1],
            ),
            LocalShelfPage(
              mode: ShelfPageMode.download,
              refreshSignal: _refreshSignals[2],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopHeader() {
    return Row(
      children: [
        _buildSleekTabs(),
        const SizedBox(width: 24),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: _buildMinimalistSearchField(false),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: '筛选',
                icon: const Icon(Icons.tune),
                onPressed: _openFilter,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileHeader() {
    if (_isSearchExpanded) {
      return Row(
        children: [
          Expanded(child: _buildMinimalistSearchField(true)),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() => _isSearchExpanded = false);
            },
          ),
        ],
      );
    }

    return Row(
      children: [
        _buildSleekTabs(),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => setState(() => _isSearchExpanded = true),
        ),
        IconButton(
          tooltip: '筛选',
          icon: const Icon(Icons.tune),
          onPressed: _openFilter,
        ),
      ],
    );
  }

  Widget _buildSleekTabs() {
    return Container(
      decoration: BoxDecoration(
        color: context.theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.5,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_labels.length, (index) {
          final isSelected = _currentIndex == index;
          return GestureDetector(
            onTap: () => _onTabChanged(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? context.theme.colorScheme.surface
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                _labels[index],
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 14,
                  color: isSelected
                      ? context.textColor
                      : context.textColor.withValues(alpha: 0.6),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMinimalistSearchField(bool isMobile) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: context.theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.4,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: '搜索列表',
          hintStyle: TextStyle(color: context.textColor.withValues(alpha: 0.5)),
          isCollapsed: true,
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.search,
            size: 18,
            color: context.textColor.withValues(alpha: 0.6),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 0,
          ),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    _setKeyword('');
                    _triggerRefresh(goTop: true);
                    setState(() {});
                  },
                ),
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: (value) {
          _setKeyword(value.trim());
          _triggerRefresh(goTop: true);
        },
      ),
    );
  }

  void _onTabChanged(int index) {
    if (index == _currentIndex) return;
    _tabController.animateTo(index);
  }

  void _handleTabControllerChanged() {
    if (!mounted || _currentIndex == _tabController.index) {
      return;
    }
    setState(() {
      _currentIndex = _tabController.index;
      _syncSearchFieldWithCurrentMode();
    });
  }

  void _syncSearchFieldWithCurrentMode() {
    final keyword = _currentSearchState().keyword;
    _searchController.value = TextEditingValue(
      text: keyword,
      selection: TextSelection.collapsed(offset: keyword.length),
    );
  }

  ShelfPageMode _currentMode() {
    return switch (_currentIndex) {
      0 => ShelfPageMode.favorite,
      1 => ShelfPageMode.history,
      2 => ShelfPageMode.download,
      _ => ShelfPageMode.favorite,
    };
  }

  SearchStatusState _currentSearchState() {
    final cubit = context.read<BookshelfSearchCubit>();
    return cubit.state.stateOf(_currentMode());
  }

  void _setKeyword(String keyword) {
    context.read<BookshelfSearchCubit>().setKeyword(_currentMode(), keyword);
  }

  void _triggerRefresh({bool goTop = false}) {
    setState(() {
      _refreshSignals[_currentIndex] = _refreshSignals[_currentIndex] + 1;
    });
  }

  void _triggerRefreshAll() {
    if (!mounted) {
      return;
    }
    setState(() {
      for (var i = 0; i < _refreshSignals.length; i++) {
        _refreshSignals[i] = _refreshSignals[i] + 1;
      }
    });
  }

  Future<void> _openFilter() async {
    final searchCubit = context.read<BookshelfSearchCubit>();
    final currentMode = _currentMode();
    final current = searchCubit.state.stateOf(currentMode);
    final pluginStates = context.read<PluginRegistryCubit>().state;
    final sourceOptions =
        pluginStates.values
            .where((plugin) => plugin.isEnabled && !plugin.isDeleted)
            .toList()
          ..sort((a, b) => a.insertedAt.compareTo(b.insertedAt));
    final availableSources = sourceOptions
        .map((plugin) => plugin.uuid)
        .toList();
    String sourceTitle(String pluginId) {
      final info = PluginRegistryService.I.getCachedPluginInfo(pluginId);
      final name = info?['name']?.toString().trim() ?? '';
      return name.isNotEmpty ? name : pluginId;
    }

    if (availableSources.isEmpty && currentMode != ShelfPageMode.favorite) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('暂无可筛选的插件来源')));
      return;
    }

    var selectedSort = current.sort == 'da' ? 'da' : 'dd';
    final currentFolderKey =
        FavoriteFolderService.parseFolderKeyFromSources(current.sources) ??
        kFavoriteFolderAllKey;
    var selectedFolderKey = currentFolderKey;
    var selectedSources = FavoriteFolderService.stripFolderSourceTokens(
      current.sources,
    ).where(availableSources.contains).toSet();
    if (selectedSources.isEmpty) {
      selectedSources = availableSources.toSet();
    }

    final applied = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('筛选'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('排序', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        showCheckmark: false,
                        label: const Text('时间(晚→早)'),
                        selected: selectedSort == 'dd',
                        onSelected: (_) =>
                            setModalState(() => selectedSort = 'dd'),
                      ),
                      ChoiceChip(
                        showCheckmark: false,
                        label: const Text('时间(早→晚)'),
                        selected: selectedSort == 'da',
                        onSelected: (_) =>
                            setModalState(() => selectedSort = 'da'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (currentMode == ShelfPageMode.favorite) ...[
                    Row(
                      children: [
                        Text(
                          '收藏夹',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () async {
                            final created = await _showCreateFolderDialog(
                              context,
                            );
                            if (created == null || created.trim().isEmpty) {
                              return;
                            }
                            try {
                              final folder = FavoriteFolderService.createFolder(
                                created,
                              );
                              setModalState(
                                () => selectedFolderKey = folder.key,
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          },
                          child: const Text('新建'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final folder
                            in FavoriteFolderService.listFolders())
                          GestureDetector(
                            onLongPress: folder.isAll
                                ? null
                                : () async {
                                    if (!mounted) return;
                                    final rootContext = this.context;
                                    final action =
                                        await _showFolderActionDialog(
                                          rootContext,
                                          folder.name,
                                        );
                                    if (action == null) return;
                                    if (action == _FolderAction.delete) {
                                      if (!rootContext.mounted) return;
                                      final ok = await _confirmDeleteFolder(
                                        rootContext,
                                        folder.name,
                                      );
                                      if (ok != true) return;
                                      if (!mounted) return;
                                      FavoriteFolderService.deleteFolder(
                                        folder.key,
                                      );
                                      setModalState(() {
                                        selectedFolderKey =
                                            kFavoriteFolderAllKey;
                                      });
                                      return;
                                    }
                                    if (!rootContext.mounted) return;
                                    final renamed =
                                        await _showRenameFolderDialog(
                                          rootContext,
                                          initialName: folder.name,
                                        );
                                    if (renamed == null ||
                                        renamed.trim().isEmpty) {
                                      return;
                                    }
                                    if (!mounted) return;
                                    try {
                                      FavoriteFolderService.renameFolder(
                                        folder.key,
                                        renamed.trim(),
                                      );
                                      setModalState(() {});
                                    } catch (e) {
                                      if (!rootContext.mounted) return;
                                      ScaffoldMessenger.of(
                                        rootContext,
                                      ).showSnackBar(
                                        SnackBar(content: Text(e.toString())),
                                      );
                                    }
                                  },
                            child: ChoiceChip(
                              showCheckmark: false,
                              label: Text(folder.name),
                              selected: selectedFolderKey == folder.key,
                              onSelected: (_) => setModalState(
                                () => selectedFolderKey = folder.key,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Text(
                        '漫画源',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => setModalState(() {
                          if (selectedSources.length ==
                              availableSources.length) {
                            selectedSources.clear();
                          } else {
                            selectedSources = availableSources.toSet();
                          }
                        }),
                        child: Text(
                          selectedSources.length == availableSources.length
                              ? '取消全选'
                              : '全选',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final source in sourceOptions)
                        FilterChip(
                          showCheckmark: false,
                          label: Text(sourceTitle(source.uuid)),
                          selected: selectedSources.contains(source.uuid),
                          onSelected: (selected) => setModalState(() {
                            if (selected) {
                              selectedSources.add(source.uuid);
                            } else {
                              selectedSources.remove(source.uuid);
                            }
                          }),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('应用'),
              ),
            ],
          );
        },
      ),
    );

    if (applied != true) return;

    searchCubit.setSort(currentMode, selectedSort);
    final nextSources = selectedSources.toList();
    if (currentMode == ShelfPageMode.favorite) {
      nextSources.add(FavoriteFolderService.sourceToken(selectedFolderKey));
    }
    searchCubit.setSources(currentMode, nextSources);
    _triggerRefresh(goTop: true);
  }

  Future<bool?> _confirmDeleteFolder(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除收藏夹'),
        content: Text('是否删除当前文件夹「$name」？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<_FolderAction?> _showFolderActionDialog(
    BuildContext context,
    String name,
  ) {
    return showDialog<_FolderAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(name),
        content: const Text('请选择操作'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_FolderAction.rename),
            child: const Text('重命名'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_FolderAction.delete),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showRenameFolderDialog(
    BuildContext context, {
    required String initialName,
  }) async {
    final controller = TextEditingController(text: initialName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名收藏夹'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '输入新的收藏夹名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<String?> _showCreateFolderDialog(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建收藏夹'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '输入收藏夹名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('创建'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  void _syncSourcesFromRegistry(Map<String, PluginRuntimeState> pluginStates) {
    final available =
        pluginStates.values
            .where((plugin) => plugin.isEnabled && !plugin.isDeleted)
            .map((plugin) => plugin.uuid)
            .toList()
          ..sort();

    if (listEquals(_lastAvailableSources, available)) {
      return;
    }
    final addedSources = available
        .where((item) => !_lastAvailableSources.contains(item))
        .toList();
    _lastAvailableSources = List<String>.from(available);

    context.read<BookshelfSearchCubit>().syncSources(
      available,
      autoSelect: addedSources,
    );
  }

  String _pluginAvailabilityRevision(
    Map<String, PluginRuntimeState> pluginStates,
  ) {
    final entries =
        pluginStates.entries
            .map(
              (entry) =>
                  '${entry.key}:${entry.value.isEnabled ? 1 : 0}:${entry.value.isDeleted ? 1 : 0}',
            )
            .toList()
          ..sort();
    return entries.join('|');
  }
}

enum _FolderAction { rename, delete }
