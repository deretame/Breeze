import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart' hide SearchEnter;

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

  @override
  void initState() {
    super.initState();
    _searchController.text = _currentSearchCubit().state.keyword;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: Row(
          children: [
            _buildTabSelector(),
            const SizedBox(width: 8),
            Expanded(child: _buildSearchField()),
            IconButton(
              tooltip: '筛选',
              icon: const Icon(Icons.tune),
              onPressed: _openFilter,
            ),
          ],
        ),
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

  Widget _buildTabSelector() {
    const labels = ['收藏', '历史', '下载'];
    return DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        value: _currentIndex,
        borderRadius: BorderRadius.circular(12),
        onChanged: (value) {
          if (value == null) return;
          _onTabChanged(value);
        },
        items: List.generate(
          labels.length,
          (index) =>
              DropdownMenuItem<int>(value: index, child: Text(labels[index])),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: '搜索当前列表',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 18),
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
    final disableBika = context.read<GlobalSettingCubit>().state.disableBika;
    final availableSources = [if (!disableBika) 'bika', 'jm'];

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
        builder: (context, setState) {
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
                        label: const Text('时间(晚→早)'),
                        selected: selectedSort == 'dd',
                        onSelected: (_) => setState(() => selectedSort = 'dd'),
                      ),
                      ChoiceChip(
                        label: const Text('时间(早→晚)'),
                        selected: selectedSort == 'da',
                        onSelected: (_) => setState(() => selectedSort = 'da'),
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
                        onPressed: () => setState(() {
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
                      if (!disableBika)
                        FilterChip(
                          showCheckmark: false,
                          label: const Text('哔咔'),
                          selected: selectedSources.contains('bika'),
                          onSelected: (selected) => setState(() {
                            if (selected) {
                              selectedSources.add('bika');
                            } else {
                              selectedSources.remove('bika');
                            }
                          }),
                        ),
                      FilterChip(
                        showCheckmark: false,
                        label: const Text('禁漫'),
                        selected: selectedSources.contains('jm'),
                        onSelected: (selected) => setState(() {
                          if (selected) {
                            selectedSources.add('jm');
                          } else {
                            selectedSources.remove('jm');
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
}
