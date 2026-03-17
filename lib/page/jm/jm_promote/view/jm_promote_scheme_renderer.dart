import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:zephyr/page/jm/jm_promote/bloc/promote_bloc.dart';
import 'package:zephyr/page/jm/jm_promote/view/jm_promote_scheme_json.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_grid.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_info.dart';
import 'package:zephyr/widgets/error_view.dart';

class JmPromoteSchemeRenderer {
  JmPromoteSchemeRenderer()
    : _schema = jsonDecode(jmPromotePageSchemeJson) as Map<String, dynamic>;

  final Map<String, dynamic> _schema;

  Widget build(
    BuildContext context, {
    required PromoteState state,
    required ScrollController scrollController,
    required Widget Function(Map<String, dynamic> item) promoteItemBuilder,
    required List<ComicSimplifyEntryInfo> suggestionEntries,
    required VoidCallback onRetryInitial,
    required VoidCallback onRetryLoadMore,
  }) {
    final statusView = _findStatusView(state.status.name);
    final widgetType = statusView['widget'] as String? ?? 'contentScrollView';

    switch (widgetType) {
      case 'centerLoading':
        return const Center(child: CircularProgressIndicator());
      case 'errorView':
        final template = statusView['errorTemplate'] as String? ?? '{error}';
        final errorMessage = template.replaceAll('{error}', state.result);
        return ErrorView(errorMessage: errorMessage, onRetry: onRetryInitial);
      case 'contentScrollView':
      default:
        return _buildContentScrollView(
          context,
          state: state,
          scrollController: scrollController,
          promoteItemBuilder: promoteItemBuilder,
          suggestionEntries: suggestionEntries,
          onRetryLoadMore: onRetryLoadMore,
        );
    }
  }

  Widget _buildContentScrollView(
    BuildContext context, {
    required PromoteState state,
    required ScrollController scrollController,
    required Widget Function(Map<String, dynamic> item) promoteItemBuilder,
    required List<ComicSimplifyEntryInfo> suggestionEntries,
    required VoidCallback onRetryLoadMore,
  }) {
    final slivers = <Widget>[];
    final config = _schema['contentScrollView'] as Map<String, dynamic>?;
    final sliverConfigs = (config?['slivers'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();

    for (final sliverConfig in sliverConfigs) {
      if (!_isVisible(sliverConfig, state, suggestionEntries)) {
        continue;
      }

      final sliver = _buildSliver(
        context,
        sliverConfig,
        state: state,
        promoteItemBuilder: promoteItemBuilder,
        suggestionEntries: suggestionEntries,
        onRetryLoadMore: onRetryLoadMore,
      );

      if (sliver != null) {
        slivers.add(sliver);
      }
    }

    return CustomScrollView(controller: scrollController, slivers: slivers);
  }

  Widget? _buildSliver(
    BuildContext context,
    Map<String, dynamic> sliverConfig, {
    required PromoteState state,
    required Widget Function(Map<String, dynamic> item) promoteItemBuilder,
    required List<ComicSimplifyEntryInfo> suggestionEntries,
    required VoidCallback onRetryLoadMore,
  }) {
    final type = sliverConfig['type'] as String?;
    if (type == null) {
      return null;
    }

    switch (type) {
      case 'promoteList':
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => promoteItemBuilder(state.sections[index]),
            childCount: state.sections.length,
          ),
        );
      case 'suggestionHeader':
        return _buildSuggestionHeader(context, sliverConfig);
      case 'suggestionGrid':
        return ComicSimplifyEntrySliverGrid(
          entries: suggestionEntries,
          type: ComicEntryType.normal,
          refresh: () {},
        );
      case 'loadingMoreIndicator':
        return const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      case 'loadingMoreRetry':
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: onRetryLoadMore,
            ),
          ),
        );
      default:
        return null;
    }
  }

  Widget _buildSuggestionHeader(
    BuildContext context,
    Map<String, dynamic> sliverConfig,
  ) {
    final title = sliverConfig['title'] as String? ?? '';
    final colorScheme = context.theme.colorScheme;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.secondaryFixed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          width: double.infinity,
          child: Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  bool _isVisible(
    Map<String, dynamic> sliverConfig,
    PromoteState state,
    List<ComicSimplifyEntryInfo> suggestionEntries,
  ) {
    final condition = sliverConfig['visibleWhen'] as String?;
    if (condition == null || condition.isEmpty) {
      return true;
    }

    switch (condition) {
      case 'hasSuggestions':
        return suggestionEntries.isNotEmpty;
      case 'isLoadingMore':
        return state.status == PromoteStatus.loadingMore;
      case 'isLoadingMoreFailure':
        return state.status == PromoteStatus.loadingMoreFailure;
      default:
        return true;
    }
  }

  Map<String, dynamic> _findStatusView(String statusName) {
    final statusViews =
        (_schema['statusViews'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map>()
            .map((item) => item.cast<String, dynamic>())
            .toList();

    for (final item in statusViews) {
      final status = item['status'] as String?;
      if (status == statusName) {
        return item;
      }

      final statuses = (item['statuses'] as List<dynamic>? ?? <dynamic>[])
          .whereType<String>()
          .toList();
      if (statuses.contains(statusName)) {
        return item;
      }
    }

    return <String, dynamic>{'widget': 'contentScrollView'};
  }
}
