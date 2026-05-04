import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/cubit/plugin_registry_cubit.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/page/search_result/bloc/search_bloc.dart';
import 'package:zephyr/util/router/router.gr.dart';

void onSearch(
  BuildContext context,
  String keyword, {
  Map<String, dynamic>? pluginExtern,
  bool aggregateMode = true,
  Map<String, bool>? aggregateSources,
}) async {
  final searchCubit = context.read<SearchCubit>();
  final nextExtern =
      pluginExtern == null
          ? Map<String, dynamic>.from(searchCubit.state.pluginExtern)
          : Map<String, dynamic>.from(pluginExtern);
  searchCubit.update(
    searchCubit.state.copyWith(
      searchKeyword: keyword,
      pluginExtern: nextExtern,
    ),
  );

  final event = SearchEvent().copyWith(searchStates: searchCubit.state);

  if (aggregateMode) {
    final pluginStates = context.read<PluginRegistryCubit>().state;
    final availableSources = pluginStates.values
        .where((plugin) => plugin.isEnabled && !plugin.isDeleted)
        .map((plugin) => plugin.uuid)
        .toList();
    final selected =
        aggregateSources ??
        {for (final source in availableSources) source: true};
    context.pushRoute(
      SearchAggregateResultRoute(
        searchEvent: event,
        searchCubit: searchCubit,
        selectedSources: selected,
      ),
    );
    return;
  }

  context.pushRoute(
    SearchResultRoute(searchEvent: event, searchCubit: searchCubit),
  );
}
