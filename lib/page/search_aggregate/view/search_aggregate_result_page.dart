import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/page/search/widget/source_select_dialog.dart';
import 'package:zephyr/page/search_result/bloc/search_bloc.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_info.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_mapper.dart';
import 'package:zephyr/widgets/section_header.dart';

import '../cubit/search_aggregate_cubit.dart';

@RoutePage()
class SearchAggregateResultPage extends StatelessWidget
    implements AutoRouteWrapper {
  const SearchAggregateResultPage({
    super.key,
    required this.searchEvent,
    this.searchCubit,
    this.selectedSources = const <String, bool>{'jm': true, 'bika': true},
  });

  final SearchEvent searchEvent;
  final SearchCubit? searchCubit;
  final Map<String, bool> selectedSources;

  @override
  Widget wrappedRoute(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        searchCubit != null
            ? BlocProvider.value(value: searchCubit!)
            : BlocProvider(
                create: (_) => SearchCubit(searchEvent.searchStates),
              ),
        BlocProvider(
          create: (_) => AggregateSearchCubit(
            searchEvent,
            initialSelectedSources: selectedSources,
          )..search(),
        ),
      ],
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SearchAggregateResultPage(searchEvent: searchEvent);
  }
}

class _SearchAggregateResultPage extends StatelessWidget {
  const _SearchAggregateResultPage({required this.searchEvent});

  final SearchEvent searchEvent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: _SearchBarTrigger(searchEvent: searchEvent),
      ),
      body: Column(
        children: [
          const _FilterChipsRow(),
          Expanded(
            child: BlocBuilder<AggregateSearchCubit, AggregateSearchState>(
              builder: (context, state) {
                if (state.status == AggregateSearchStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _ResultList(searchEvent: searchEvent, state: state);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBarTrigger extends StatelessWidget {
  const _SearchBarTrigger({required this.searchEvent});

  final SearchEvent searchEvent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                final stack = context.router.stack;
                if (stack.length > 1 &&
                    stack[stack.length - 2].name == SearchRoute.name) {
                  context.maybePop();
                  return;
                }

                context.replaceRoute(
                  SearchRoute(
                    key: ValueKey(const Uuid().v4()),
                    searchState: context.read<SearchCubit>().state,
                    aggregateMode: true,
                  ),
                );
              },
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(21),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.search, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        searchEvent.searchStates.searchKeyword,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: '选择漫画源',
            onPressed: () => _showSourceDialog(context),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
    );
  }

  Future<void> _showSourceDialog(BuildContext context) async {
    final cubit = context.read<AggregateSearchCubit>();
    final selected = await showSourceSelectDialog(
      context,
      initial: cubit.state.selectedSources,
    );
    if (selected != null) {
      await cubit.applySelectedSources(selected);
    }
  }
}

class _FilterChipsRow extends StatelessWidget {
  const _FilterChipsRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AggregateSearchCubit, AggregateSearchState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              alignment: WrapAlignment.start,
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  showCheckmark: false,
                  label: const Text('有结果'),
                  selected: state.showHasResults,
                  onSelected: (value) => context
                      .read<AggregateSearchCubit>()
                      .toggleHasResults(value),
                ),
                FilterChip(
                  showCheckmark: false,
                  label: const Text('显示错误'),
                  selected: state.showErrors,
                  onSelected: (value) => context
                      .read<AggregateSearchCubit>()
                      .toggleShowErrors(value),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ResultList extends StatelessWidget {
  const _ResultList({required this.searchEvent, required this.state});

  final SearchEvent searchEvent;
  final AggregateSearchState state;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (final from in const [From.jm, From.bika]) {
      final selected = state.selectedSources[from] ?? false;
      if (!selected) {
        continue;
      }

      final items = state.results[from] ?? const <dynamic>[];
      final error = state.errors[from] ?? '';

      final shouldShowResultSection = items.isNotEmpty || !state.showHasResults;
      if (shouldShowResultSection) {
        final List<ComicSimplifyEntryInfo> entries = items.isNotEmpty
            ? mapToUnifiedComicSimplifyEntryInfoList(items)
            : const <ComicSimplifyEntryInfo>[];
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: _sourceTitle(from),
                  subtitle: '${items.length} 条',
                  onTap: () => _openSourceSearch(context, from),
                ),
                if (entries.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: ComicFixedSizeHorizontalList(
                      entries: entries,
                      spacing: 10,
                      itemWidth: 112,
                    ),
                  ),
                if (entries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(14, 2, 14, 8),
                    child: Text('无结果'),
                  ),
              ],
            ),
          ),
        );
      }

      if (state.showErrors && error.isNotEmpty) {
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.error_outline),
                title: Text('${_sourceTitle(from)} 加载失败'),
                subtitle: Text(
                  error,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        );
      }
    }

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView(children: children);
  }

  String _sourceTitle(From from) {
    return from == From.jm ? '禁漫' : '哔咔';
  }

  void _openSourceSearch(BuildContext context, From from) {
    context.pushRoute(
      SearchResultRoute(
        key: ValueKey(const Uuid().v4()),
        searchEvent: searchEvent.copyWith(
          searchStates: searchEvent.searchStates.copyWith(from: from),
          page: 1,
        ),
        searchCubit: context.read<SearchCubit>(),
      ),
    );
  }
}
