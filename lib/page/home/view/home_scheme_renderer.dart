import 'package:flutter/material.dart';
import 'package:zephyr/plugin/plugin_constants.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/debouncer.dart';
import 'package:zephyr/util/json/json_value.dart';
import 'package:zephyr/util/sundry.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_grid.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_mapper.dart';
import 'package:zephyr/widgets/comic_simplify_entry/cover.dart';
import 'package:zephyr/widgets/section_header.dart';
import 'package:zephyr/type/enum.dart';

class HomeSchemeRenderer {
  const HomeSchemeRenderer();

  String title(Map<String, dynamic> scheme, String fallback) {
    return scheme['title']?.toString() ?? fallback;
  }

  Widget buildPage(
    BuildContext context, {
    required String from,
    required Map<String, dynamic> scheme,
    required Map<String, dynamic> data,
    required Future<void> Function() onReachBottom,
    required Future<void> Function(Map<String, dynamic> action) onAction,
    required bool isLoadingMore,
    required bool showLoadMoreRetry,
    required VoidCallback onRetryLoadMore,
  }) {
    final body = asJsonMap(scheme['body']);
    final content = _buildNode(
      context,
      node: body,
      data: data,
      from: from,
      onAction: onAction,
    );

    final children = <Widget>[content];
    if (isLoadingMore) {
      children.add(
        const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    } else if (showLoadMoreRetry) {
      children.add(
        Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ElevatedButton(
              onPressed: onRetryLoadMore,
              child: const Text('点击重试'),
            ),
          ),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.maxScrollExtent <= 0) {
          return false;
        }
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent * 0.9) {
          onReachBottom();
        }
        return false;
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: children,
      ),
    );
  }

  Widget _buildNode(
    BuildContext context, {
    required Map<String, dynamic> node,
    required Map<String, dynamic> data,
    required String from,
    required Future<void> Function(Map<String, dynamic> action) onAction,
  }) {
    final type = node['type']?.toString() ?? '';
    switch (type) {
      case 'list':
        final children = asJsonList(node['children'])
            .map(
              (item) => _buildNode(
                context,
                node: asJsonMap(item),
                data: data,
                from: from,
                onAction: onAction,
              ),
            )
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
      case 'chip-list':
        return _buildChipList(context, _resolveItems(node, data), onAction);
      case 'action-grid':
        return _buildActionGrid(
          context,
          _filterActionItems(from, node, _resolveItems(node, data)),
          from,
          onAction,
        );
      case 'comic-section-list':
        return _buildComicSectionList(
          context,
          _resolveItems(node, data),
          from,
          onAction,
        );
      case 'comic-grid':
        return _buildComicGrid(
          _resolveItems(node, data),
          title: node['title']?.toString() ?? '',
          action: asJsonMap(node['action']),
          onAction: onAction,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildChipList(
    BuildContext context,
    List<Map<String, dynamic>> items,
    Future<void> Function(Map<String, dynamic> action) onAction,
  ) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Wrap(
        spacing: 10,
        runSpacing: 5,
        children: items.map((item) {
          final label = item['label']?.toString() ?? '';
          return GestureDetector(
            onTap: () => onAction(asJsonMap(item['action'])),
            child: Chip(
              backgroundColor: context.backgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              label: Text(
                label.let(t2s),
                style: TextStyle(
                  fontSize: 12,
                  color: context.theme.colorScheme.primary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionGrid(
    BuildContext context,
    List<Map<String, dynamic>> items,
    String from,
    Future<void> Function(Map<String, dynamic> action) onAction,
  ) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    const spacing = 12.0;

    return GridView.builder(
      padding: const EdgeInsets.all(spacing),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: 0.8,
      ),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final title = item['title']?.toString() ?? '';
        final cover = asJsonMap(item['cover']);
        final extern = asJsonMap(cover['extern']);
        final assetPath = extern['asset']?.toString().trim() ?? '';
        final coverUrl = cover['url']?.toString().trim() ?? '';
        final coverPath = extern['path']?.toString().trim() ?? '';

        return GestureDetector(
          onTap: () => onAction(asJsonMap(item['action'])),
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: assetPath.isNotEmpty && coverUrl.isEmpty
                      ? Image.asset(
                          assetPath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const ColoredBox(color: Color(0xFFE0E0E0)),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) => CoverWidget(
                            fileServer: coverUrl,
                            path: coverPath.isNotEmpty ? coverPath : title,
                            id: title,
                            pictureType: PictureType.category,
                            from: from,
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title.let(t2s),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textColor, fontSize: 14),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComicSectionList(
    BuildContext context,
    List<Map<String, dynamic>> sections,
    String from,
    Future<void> Function(Map<String, dynamic> action) onAction,
  ) {
    if (sections.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: sections.map((section) {
        final title = section['title']?.toString() ?? '';
        final subtitle = section['subtitle']?.toString() ?? '';
        final items = asJsonList(
          section['items'],
        ).map((item) => asJsonMap(item)).toList();
        final entries = mapToUnifiedComicSimplifyEntryInfoList(items);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: title.let(t2s),
                subtitle: subtitle.let(t2s),
                onTap: _isActionable(section['action'])
                    ? () => onAction(asJsonMap(section['action']))
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: ComicFixedSizeHorizontalList(
                  entries: entries,
                  spacing: 10,
                  itemWidth: (isTabletWithOutContext() ? 200 : 150) * 0.75,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildComicGrid(
    List<Map<String, dynamic>> items, {
    required String title,
    required Map<String, dynamic> action,
    required Future<void> Function(Map<String, dynamic> action) onAction,
  }) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final entries = mapToUnifiedComicSimplifyEntryInfoList(items);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.trim().isNotEmpty)
          SectionHeader(
            title: title.let(t2s),
            onTap: _isActionable(action) ? () => onAction(action) : null,
          ),
        ComicSimplifyEntryGridView(
          entries: entries,
          type: ComicEntryType.normal,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(10),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _resolveItems(
    Map<String, dynamic> node,
    Map<String, dynamic> data,
  ) {
    final key = node['key']?.toString() ?? '';
    if (key.isEmpty) {
      return const <Map<String, dynamic>>[];
    }
    return asJsonList(data[key]).map((item) => asJsonMap(item)).toList();
  }

  List<Map<String, dynamic>> _filterActionItems(
    String from,
    Map<String, dynamic> node,
    List<Map<String, dynamic>> items,
  ) {
    if (from != kBikaPluginUuid || node['key']?.toString() != 'navItems') {
      return items;
    }

    final shieldedMap = objectbox.userSettingBox
        .get(1)!
        .bikaSetting
        .shieldHomePageCategoriesMap;
    return items.where((item) {
      final title = item['title']?.toString() ?? '';
      return !(shieldedMap[title] ?? false);
    }).toList();
  }

  bool _isActionable(dynamic value) {
    final action = asJsonMap(value);
    final type = action['type']?.toString().trim() ?? '';
    return type.isNotEmpty && type != 'none';
  }
}
