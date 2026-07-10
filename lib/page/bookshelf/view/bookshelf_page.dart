import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/cubit/plugin_registry_cubit.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart' hide SearchEnter;
import 'package:zephyr/page/bookshelf/service/download_folder_service.dart';
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
  late final List<String> _labels = [
    t.bookshelf.favorite,
    t.bookshelf.history,
    t.bookshelf.download,
  ];

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
            FolderShelfPage(
              mode: ShelfPageMode.favorite,
              refreshSignal: _refreshSignals[0],
              isActive: _currentIndex == 0,
            ),
            LocalShelfPage(
              mode: ShelfPageMode.history,
              refreshSignal: _refreshSignals[1],
            ),
            FolderShelfPage(
              mode: ShelfPageMode.download,
              refreshSignal: _refreshSignals[2],
              isActive: _currentIndex == 2,
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
                tooltip: t.bookshelf.filter,
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
          tooltip: t.bookshelf.filter,
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
          hintText: t.bookshelf.searchList,
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
    final sourceOptions = _buildFilterSourceOptions();
    final availableSources = sourceOptions
        .map((source) => source.pluginId)
        .toList();

    if (availableSources.isEmpty && currentMode != ShelfPageMode.favorite) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.bookshelf.noFilterSource)));
      return;
    }

    final currentFolderKey = switch (currentMode) {
      ShelfPageMode.favorite =>
        FavoriteFolderService.parseFolderKeyFromSources(current.sources) ??
            kFavoriteFolderAllKey,
      ShelfPageMode.download =>
        DownloadFolderService.parseFolderKeyFromSources(current.sources) ??
            kDownloadFolderAllKey,
      _ => kFavoriteFolderAllKey,
    };
    final stripFolderTokens = switch (currentMode) {
      ShelfPageMode.favorite => FavoriteFolderService.stripFolderSourceTokens,
      ShelfPageMode.download => DownloadFolderService.stripFolderSourceTokens,
      _ => FavoriteFolderService.stripFolderSourceTokens,
    };
    var selectedSources = stripFolderTokens(
      current.sources,
    ).where(availableSources.contains).toSet();
    if (selectedSources.isEmpty) {
      selectedSources = availableSources.toSet();
    }

    final result = await showDialog<_BookshelfFilterResult>(
      context: context,
      builder: (dialogContext) => _BookshelfFilterDialog(
        mode: currentMode,
        initialSort: current.sort == 'da' ? 'da' : 'dd',
        initialFolderKey: currentFolderKey,
        initialSources: selectedSources,
        availableSources: availableSources,
        sourceOptions: sourceOptions,
        onCreateFolder: () => _showCreateFolderDialog(dialogContext),
        onRequestFolderAction: (folder) =>
            _handleFolderAction(dialogContext, folder),
      ),
    );

    if (result == null) return;

    searchCubit.setSort(currentMode, result.sort);

    var nextSources = result.sources.toList();
    if (currentMode == ShelfPageMode.favorite &&
        result.folderKey != kFavoriteFolderAllKey) {
      nextSources.add(FavoriteFolderService.sourceToken(result.folderKey));
    } else if (currentMode == ShelfPageMode.download &&
        result.folderKey != kDownloadFolderAllKey) {
      nextSources.add(DownloadFolderService.sourceToken(result.folderKey));
    }
    searchCubit.setSources(currentMode, nextSources);
    _triggerRefresh(goTop: true);
  }

  List<_FilterSourceOption> _buildFilterSourceOptions() {
    final pluginStates = context.read<PluginRegistryCubit>().state;
    final sourceOptions =
        pluginStates.values
            .where((plugin) => plugin.isEnabled && !plugin.isDeleted)
            .toList()
          ..sort((a, b) => a.insertedAt.compareTo(b.insertedAt));
    return sourceOptions
        .map(
          (plugin) => _FilterSourceOption(
            pluginId: plugin.uuid,
            title: _sourceTitle(plugin.uuid),
          ),
        )
        .toList();
  }

  String _sourceTitle(String pluginId) {
    final info = PluginRegistryService.I.getCachedPluginInfo(pluginId);
    final name = info?['name']?.toString().trim() ?? '';
    return name.isNotEmpty ? name : pluginId;
  }

  Future<_FolderDialogOutcome?> _handleFolderAction(
    BuildContext dialogContext,
    dynamic folder,
  ) async {
    final String folderKey = folder.key as String;
    final String folderName = folder.name as String;

    if (!mounted) {
      return null;
    }

    final action = await _showFolderActionDialog(context, folderName);
    if (!mounted) {
      return null;
    }
    if (action == null) {
      return null;
    }

    final isFavoriteMode = _currentIndex == 0;
    final allKey = isFavoriteMode
        ? kFavoriteFolderAllKey
        : kDownloadFolderAllKey;

    if (action == _FolderAction.delete) {
      final ok = await _confirmDeleteFolder(context, folderName);
      if (!mounted) {
        return null;
      }
      if (ok != true) {
        return null;
      }
      if (isFavoriteMode) {
        FavoriteFolderService.deleteFolder(folderKey);
      } else {
        DownloadFolderService.deleteFolder(folderKey);
      }
      return _FolderDialogOutcome(
        shouldRefreshFolders: true,
        selectedFolderKey: allKey,
      );
    }

    final renamed = await _showRenameFolderDialog(
      context,
      initialName: folderName,
    );
    if (!mounted) {
      return null;
    }
    if (renamed == null || renamed.trim().isEmpty) {
      return null;
    }
    try {
      if (isFavoriteMode) {
        FavoriteFolderService.renameFolder(folderKey, renamed.trim());
      } else {
        DownloadFolderService.renameFolder(folderKey, renamed.trim());
      }
      return _FolderDialogOutcome(
        shouldRefreshFolders: true,
        selectedFolderKey: folderKey,
      );
    } catch (e) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(
          dialogContext,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
      return null;
    }
  }

  Future<bool?> _confirmDeleteFolder(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.bookshelf.deleteFolder),
        content: Text(t.bookshelf.confirmDeleteFolder(name: name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.common.ok),
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
        content: Text(t.bookshelf.folderAction),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_FolderAction.rename),
            child: Text(t.common.rename),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_FolderAction.delete),
            child: Text(t.common.delete),
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
        title: Text(t.bookshelf.renameFolder),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: t.bookshelf.folderNameHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(t.common.ok),
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
        title: Text(t.bookshelf.createFolder),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: t.bookshelf.createFolderHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(t.common.create),
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

class _BookshelfFilterDialog extends StatefulWidget {
  const _BookshelfFilterDialog({
    required this.mode,
    required this.initialSort,
    required this.initialFolderKey,
    required this.initialSources,
    required this.availableSources,
    required this.sourceOptions,
    required this.onCreateFolder,
    required this.onRequestFolderAction,
  });

  final ShelfPageMode mode;
  final String initialSort;
  final String initialFolderKey;
  final Set<String> initialSources;
  final List<String> availableSources;
  final List<_FilterSourceOption> sourceOptions;
  final Future<String?> Function() onCreateFolder;
  final Future<_FolderDialogOutcome?> Function(dynamic folder)
  onRequestFolderAction;

  @override
  State<_BookshelfFilterDialog> createState() => _BookshelfFilterDialogState();
}

class _BookshelfFilterDialogState extends State<_BookshelfFilterDialog> {
  late String _selectedSort;
  late String _selectedFolderKey;
  late Set<String> _selectedSources;

  bool get _isFavoriteMode => widget.mode == ShelfPageMode.favorite;
  bool get _isDownloadMode => widget.mode == ShelfPageMode.download;
  bool get _showFolderSection => _isFavoriteMode || _isDownloadMode;

  @override
  void initState() {
    super.initState();
    _selectedSort = widget.initialSort;
    _selectedFolderKey = widget.initialFolderKey;
    _selectedSources = Set<String>.from(widget.initialSources);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(t.bookshelf.filter),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSortSection(context),
              const SizedBox(height: 16),
              if (_showFolderSection) ...[
                _buildFolderSection(context),
                const SizedBox(height: 16),
              ],
              _buildSourceSection(context),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.common.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            _BookshelfFilterResult(
              sort: _selectedSort,
              folderKey: _selectedFolderKey,
              sources: _selectedSources,
            ),
          ),
          child: Text(t.common.apply),
        ),
      ],
    );
  }

  Widget _buildSortSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.bookshelf.sort, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              showCheckmark: false,
              label: Text(t.bookshelf.sortDesc),
              selected: _selectedSort == 'dd',
              onSelected: (_) => setState(() => _selectedSort = 'dd'),
            ),
            ChoiceChip(
              showCheckmark: false,
              label: Text(t.bookshelf.sortAsc),
              selected: _selectedSort == 'da',
              onSelected: (_) => setState(() => _selectedSort = 'da'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFolderSection(BuildContext context) {
    final List<dynamic> folderViews;
    if (_isFavoriteMode) {
      folderViews = FavoriteFolderService.listFolders();
    } else {
      folderViews = DownloadFolderService.listFolders();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              t.bookshelf.folderDeprecated,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Spacer(),
            // TextButton(onPressed: _createFolder, child: const Text('新建')),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final folder in folderViews)
              GestureDetector(
                onLongPress: folder.isAll
                    ? null
                    : () => _handleFolderLongPress(folder),
                child: ChoiceChip(
                  showCheckmark: false,
                  label: Text(folder.name),
                  selected: _selectedFolderKey == folder.key,
                  onSelected: (_) =>
                      setState(() => _selectedFolderKey = folder.key),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleFolderLongPress(dynamic folder) async {
    final outcome = await widget.onRequestFolderAction(folder);
    if (!mounted || outcome == null) {
      return;
    }
    setState(() {
      if (outcome.selectedFolderKey != null) {
        _selectedFolderKey = outcome.selectedFolderKey!;
      }
    });
  }

  Widget _buildSourceSection(BuildContext context) {
    final isAllSelected =
        _selectedSources.length == widget.availableSources.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              t.bookshelf.source,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => setState(() {
                if (isAllSelected) {
                  _selectedSources.clear();
                } else {
                  _selectedSources = widget.availableSources.toSet();
                }
              }),
              child: Text(
                isAllSelected ? t.bookshelf.deselectAll : t.common.selectAll,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final source in widget.sourceOptions)
              FilterChip(
                showCheckmark: false,
                label: Text(source.title),
                selected: _selectedSources.contains(source.pluginId),
                onSelected: (selected) => setState(() {
                  if (selected) {
                    _selectedSources.add(source.pluginId);
                  } else {
                    _selectedSources.remove(source.pluginId);
                  }
                }),
              ),
          ],
        ),
      ],
    );
  }
}

class _BookshelfFilterResult {
  _BookshelfFilterResult({
    required this.sort,
    required this.folderKey,
    required Set<String> sources,
  }) : sources = Set<String>.from(sources);

  final String sort;
  final String folderKey;
  final Set<String> sources;
}

class _FilterSourceOption {
  const _FilterSourceOption({required this.pluginId, required this.title});

  final String pluginId;
  final String title;
}

class _FolderDialogOutcome {
  const _FolderDialogOutcome({
    required this.shouldRefreshFolders,
    this.selectedFolderKey,
  });

  final bool shouldRefreshFolders;
  final String? selectedFolderKey;
}

enum _FolderAction { rename, delete }
