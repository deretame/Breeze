import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/cubit/plugin_registry_cubit.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart' hide SearchEnter;
import 'package:zephyr/plugin/plugin_registry_service.dart';
import 'package:zephyr/util/context/context_extensions.dart';

@RoutePage()
class BookshelfPage extends StatelessWidget {
  const BookshelfPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LocalFavoriteCubit>(
          create: (context) => LocalFavoriteCubit(),
        ),
        BlocProvider<HistoryCubit>(create: (context) => HistoryCubit()),
        BlocProvider<DownloadCubit>(create: (context) => DownloadCubit()),
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

class _BookshelfPageContentState extends State<_BookshelfPageContent> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final List<int> _refreshSignals = [0, 0, 0];
  List<String> _lastAvailableSources = const <String>[];
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    _syncSourcesFromRegistry();
    _searchController.text = _currentSearchCubit().state.keyword;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _syncSourcesFromRegistry();
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: isDesktop ? 16 : 8,
        title: isDesktop ? _buildDesktopHeader() : _buildMobileHeader(),
      ),
      body: IndexedStack(
        index: _currentIndex,
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
    const labels = ['收藏', '历史', '下载'];
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
        children: List.generate(labels.length, (index) {
          final isSelected = _currentIndex == index;
          return GestureDetector(
            onTap: () => _onTabChanged(index),
            child: Container(
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
                labels[index],
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
                    _currentSearchCubit().setKeyword('');
                    _triggerRefresh(goTop: true);
                    setState(() {});
                  },
                ),
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: (value) {
          _currentSearchCubit().setKeyword(value.trim());
          _triggerRefresh(goTop: true);
        },
      ),
    );
  }

  void _onTabChanged(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
      _searchController.text = _currentSearchCubit().state.keyword;
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: _searchController.text.length),
      );
    });
  }

  SearchStatusCubit _currentSearchCubit() {
    switch (_currentIndex) {
      case 0:
        return context.read<LocalFavoriteCubit>();
      case 1:
        return context.read<HistoryCubit>();
      case 2:
        return context.read<DownloadCubit>();
      default:
        return context.read<LocalFavoriteCubit>();
    }
  }

  void _triggerRefresh({bool goTop = false}) {
    setState(() {
      _refreshSignals[_currentIndex] = _refreshSignals[_currentIndex] + 1;
    });
  }

  Future<void> _openFilter() async {
    final searchCubit = _currentSearchCubit();
    final current = searchCubit.state;
    final pluginStates = context.read<PluginRegistryCubit>().state;
    final sourceOptions =
        pluginStates.values.where((plugin) => !plugin.isDeleted).toList()
          ..sort((a, b) => a.insertedAt.compareTo(b.insertedAt));
    final availableSources = sourceOptions
        .map((plugin) => plugin.uuid)
        .toList();
    String sourceTitle(String pluginId) {
      final info = PluginRegistryService.I.getCachedPluginInfo(pluginId);
      final name = info?['name']?.toString().trim() ?? '';
      return name.isNotEmpty ? name : pluginId;
    }

    if (availableSources.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('暂无可筛选的插件来源')));
      return;
    }

    var selectedSort = current.sort == 'da' ? 'da' : 'dd';
    var selectedSources = current.sources
        .where(availableSources.contains)
        .toSet();
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

    searchCubit.setSort(selectedSort);
    searchCubit.setSources(selectedSources.toList());
    _triggerRefresh(goTop: true);
  }

  void _syncSourcesFromRegistry() {
    final pluginStates = context.read<PluginRegistryCubit>().state;
    final available =
        pluginStates.values
            .where((plugin) => plugin.isEnabled && !plugin.isDeleted)
            .map((plugin) => plugin.uuid)
            .toList()
          ..sort();

    if (listEquals(_lastAvailableSources, available)) {
      return;
    }
    _lastAvailableSources = List<String>.from(available);

    void syncCubit(SearchStatusCubit cubit) {
      final current = cubit.state.sources.where(
        (item) => item.trim().isNotEmpty,
      );
      final filtered = current.where(available.contains).toList();
      final next = filtered.isEmpty ? available : filtered;
      if (!listEquals(cubit.state.sources, next)) {
        cubit.setSources(next);
      }
    }

    syncCubit(context.read<LocalFavoriteCubit>());
    syncCubit(context.read<HistoryCubit>());
    syncCubit(context.read<DownloadCubit>());
  }
}
