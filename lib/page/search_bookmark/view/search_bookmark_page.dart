import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:zephyr/config/router/router.gr.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/cubit/plugin_registry_cubit.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/page/search_bookmark/cubit/search_bookmark_cubit.dart';
import 'package:zephyr/page/search_result/bloc/search_bloc.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/widgets/comic_entry/models/models.dart';
import 'package:zephyr/widgets/comic_simplify_entry/cover.dart';
import 'package:zephyr/widgets/error_view.dart';
import 'package:zephyr/widgets/toast.dart';

/// 书签锚点封面：与追更页同一尺寸/同一组件。
const double _bookmarkCoverWidth = 84;
const double _bookmarkCoverHeight = 112;

/// 解析锚点封面，脏数据回退为空占位（用 anchorComicId 兜底）。
UnifiedComicCover _resolveBookmarkCover(SearchBookmark item) {
  try {
    final raw = item.anchorCover.trim();
    if (raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      final map = decoded is Map<String, dynamic>
          ? decoded
          : decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : const <String, dynamic>{};
      if (map.isNotEmpty) return UnifiedComicCover.fromJson(map);
    }
  } catch (_) {}
  return UnifiedComicCover(
    id: item.anchorComicId,
    url: '',
    path: '',
    extern: const <String, dynamic>{},
  );
}

/// 搜索书签管理页：列出全部插件的书签，支持按插件筛选、按时间排序。
/// 点一条即参数重放跳转结果页。
@RoutePage()
class SearchBookmarkPage extends StatelessWidget {
  const SearchBookmarkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SearchBookmarkCubit()..loadAll(),
      child: const _SearchBookmarkView(),
    );
  }
}

class _SearchBookmarkView extends StatelessWidget {
  const _SearchBookmarkView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t.searchBookmark.title),
        actions: [
          IconButton(
            tooltip: t.searchBookmark.filter,
            icon: const Icon(Icons.tune),
            onPressed: () => _openFilter(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 768),
          child: const _BookmarkList(),
        ),
      ),
    );
  }

  Future<void> _openFilter(BuildContext context) async {
    final cubit = context.read<SearchBookmarkCubit>();
    final names = {
      for (final s in cubit.state.availableSources)
        s: context.read<PluginRegistryCubit>().state.pluginName(s),
    };
    final result = await showDialog<_BookmarkFilterResult>(
      context: context,
      builder: (_) => _BookmarkFilterDialog(
        initialAscending: cubit.state.sortAscending,
        initialSources: cubit.state.selectedSources,
        availableSources: cubit.state.availableSources,
        sourceNames: names,
        initialProbePages: context
            .read<GlobalSettingCubit>()
            .state
            .searchBookmarkProbePages,
      ),
    );
    if (result == null || !context.mounted) return;
    cubit.applyFilter(sources: result.sources, ascending: result.ascending);
    context.read<GlobalSettingCubit>().updateState(
      (current) =>
          current.copyWith(searchBookmarkProbePages: result.probePages),
    );
  }
}

/// 书架式筛选对话框：排序 ChoiceChip + 图源 FilterChip 多选。
class _BookmarkFilterDialog extends StatefulWidget {
  const _BookmarkFilterDialog({
    required this.initialAscending,
    required this.initialSources,
    required this.availableSources,
    required this.sourceNames,
    required this.initialProbePages,
  });

  final bool initialAscending;
  final Set<String> initialSources;
  final List<String> availableSources;
  final Map<String, String> sourceNames;
  final int initialProbePages;

  @override
  State<_BookmarkFilterDialog> createState() => _BookmarkFilterDialogState();
}

class _BookmarkFilterDialogState extends State<_BookmarkFilterDialog> {
  late bool _ascending;
  late Set<String> _selectedSources;
  late int _probePages;

  @override
  void initState() {
    super.initState();
    _ascending = widget.initialAscending;
    _selectedSources = Set<String>.from(widget.initialSources);
    _probePages = widget.initialProbePages;
  }

  String _nameOf(String source) {
    final name = widget.sourceNames[source]?.trim() ?? '';
    return name.isNotEmpty ? name : source;
  }

  @override
  Widget build(BuildContext context) {
    final sortedSources = widget.availableSources.toList()
      ..sort((a, b) => _nameOf(a).compareTo(_nameOf(b)));
    final isAllSelected =
        _selectedSources.length == widget.availableSources.length;
    return AlertDialog(
      title: Text(t.searchBookmark.filter),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.searchBookmark.sort,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    showCheckmark: false,
                    label: Text(t.searchBookmark.sortNewest),
                    selected: !_ascending,
                    onSelected: (_) => setState(() => _ascending = false),
                  ),
                  ChoiceChip(
                    showCheckmark: false,
                    label: Text(t.searchBookmark.sortOldest),
                    selected: _ascending,
                    onSelected: (_) => setState(() => _ascending = true),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    t.searchBookmark.source,
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
                      isAllSelected
                          ? t.searchBookmark.deselectAll
                          : t.common.selectAll,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final source in sortedSources)
                    FilterChip(
                      showCheckmark: false,
                      label: Text(_nameOf(source)),
                      selected: _selectedSources.contains(source),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _selectedSources.add(source);
                        } else {
                          _selectedSources.remove(source);
                        }
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                t.searchBookmark.probePages,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final v in const [0, 1, 2, 3, 5])
                    ChoiceChip(
                      showCheckmark: false,
                      label: Text('$v'),
                      selected: _probePages == v,
                      onSelected: (_) => setState(() => _probePages = v),
                    ),
                ],
              ),
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
            _BookmarkFilterResult(
              sources: _selectedSources,
              ascending: _ascending,
              probePages: _probePages,
            ),
          ),
          child: Text(t.common.apply),
        ),
      ],
    );
  }
}

class _BookmarkFilterResult {
  _BookmarkFilterResult({
    required Set<String> sources,
    required this.ascending,
    required this.probePages,
  }) : sources = Set<String>.from(sources);

  final Set<String> sources;
  final bool ascending;
  final int probePages;
}

class _BookmarkList extends StatelessWidget {
  const _BookmarkList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchBookmarkCubit, SearchBookmarkState>(
      builder: (context, state) {
        switch (state.status) {
          case SearchBookmarkStatus.initial:
          case SearchBookmarkStatus.loading:
          case SearchBookmarkStatus.failure:
            return ErrorView(
              errorMessage: state.result,
              onRetry: () => context.read<SearchBookmarkCubit>().loadAll(),
            );
          case SearchBookmarkStatus.success:
            final visible = state.visibleItems;
            if (visible.isEmpty) {
              return _BookmarkEmptyView(filtered: state.items.isNotEmpty);
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              itemCount: visible.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = visible[index];
                return _BookmarkRow(key: ValueKey(item.uniqueKey), item: item);
              },
            );
        }
      },
    );
  }
}

/// 空态：无书签 vs 筛选无结果两种文案。
class _BookmarkEmptyView extends StatelessWidget {
  const _BookmarkEmptyView({required this.filtered});

  final bool filtered;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                filtered
                    ? Icons.filter_alt_off_outlined
                    : Icons.bookmark_border,
                size: 44,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              filtered
                  ? t.searchBookmark.filteredEmpty
                  : t.searchBookmark.empty,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              filtered
                  ? t.searchBookmark.filteredEmptyHint
                  : t.searchBookmark.emptyHint,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// 行首插件名：独立订阅避免整表重建（行在 ListView builder 里）。
class _BookmarkSourceLine extends StatelessWidget {
  const _BookmarkSourceLine({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<PluginRegistryCubit, PluginRegistryState, String>(
      selector: (registry) => registry.pluginName(source),
      builder: (context, pluginLabel) {
        final label = pluginLabel.trim().isNotEmpty ? pluginLabel : source;
        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            children: [
              Icon(
                Icons.source_outlined,
                size: 13,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BookmarkRow extends StatelessWidget {
  const _BookmarkRow({super.key, required this.item});

  final SearchBookmark item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cover = _resolveBookmarkCover(item);
    final timeText = DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).format(item.createdAt.toLocal());
    final anchorTitle = item.anchorTitle.trim();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _jump(context),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CoverWidget(
                  fileServer: cover.url,
                  path: cover.cachePath,
                  id: item.anchorComicId,
                  pictureType: PictureType.cover,
                  from: item.source,
                  roundedCorner: false,
                  width: _bookmarkCoverWidth,
                  height: _bookmarkCoverHeight,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BookmarkSourceLine(source: item.source),
                    Text(
                      item.keyword,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      anchorTitle.isEmpty ? item.anchorComicId : anchorTitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      timeText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                await context.read<SearchBookmarkCubit>().remove(item);
                if (context.mounted) {
                  showSuccessToast(t.searchBookmark.deleted);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _jump(BuildContext context) {
    // 书签跳转回放：这一次请求带 isSearchAggregate=true，插件直抓
    // extern 里记下的 currentUrl；成功后 bloc 复位，后续翻页走正常逻辑。
    final newStates = SearchStates.initial().copyWith(
      from: item.source,
      searchKeyword: item.keyword,
      pluginExtern: Map<String, dynamic>.from(item.extern),
      isSearchAggregate: true,
    );
    final page = item.anchorPage < 1 ? 1 : item.anchorPage;
    SearchBookmarkReveal.request(item);
    showSuccessToast(t.searchBookmark.jumped(page: page));
    context.pushRoute(
      SearchResultRoute(
        searchEvent: SearchEvent().copyWith(
          searchStates: newStates,
          page: page,
        ),
      ),
    );
  }
}
