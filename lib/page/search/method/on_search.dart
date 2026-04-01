import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/plugin/plugin_constants.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/page/search_result/bloc/search_bloc.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/type/enum.dart';

const String _jmKeywordPrefix = 'jm';

void onSearch(
  BuildContext context,
  String keyword, {
  Map<String, dynamic> pluginExtern = const <String, dynamic>{},
  bool aggregateMode = true,
  Map<String, bool>? aggregateSources,
}) async {
  final searchCubit = context.read<SearchCubit>();
  final resolvedPluginId = sanitizePluginId(
    pluginExtern['_pluginId']?.toString().trim().isNotEmpty == true
        ? pluginExtern['_pluginId'].toString().trim()
        : sanitizePluginId(searchCubit.state.from),
  );
  searchCubit.update(
    searchCubit.state.copyWith(
      searchKeyword: keyword,
      pluginExtern: {
        ...Map<String, dynamic>.from(pluginExtern),
        '_pluginId': resolvedPluginId,
      },
    ),
  );
  if (searchCubit.state.from == kJmPluginUuid) {
    if (keyword.let(toInt) >= 100 || keyword.startsWith(_jmKeywordPrefix)) {
      if (!keyword.startsWith(_jmKeywordPrefix)) {
        keyword = '$_jmKeywordPrefix$keyword';
      }

      var comicId = keyword;
      if (keyword.startsWith(_jmKeywordPrefix)) {
        comicId = keyword.substring(_jmKeywordPrefix.length);
      }

      context.pushRoute(
        ComicInfoRoute(
          comicId: comicId,
          type: ComicEntryType.normal,
          from: kJmPluginUuid,
          pluginId: kJmPluginUuid,
        ),
      );

      final settingCubit = context.read<GlobalSettingCubit>();
      final history = settingCubit.state.searchHistory.toList();
      history
        ..remove(keyword)
        ..insert(0, keyword);
      await Future.delayed(const Duration(milliseconds: 200));
      settingCubit.updateState(
        (current) =>
            current.copyWith(searchHistory: history.take(200).toList()),
      );
      return;
    }
  }

  final event = SearchEvent().copyWith(searchStates: searchCubit.state);

  if (aggregateMode) {
    final selected =
        aggregateSources ??
        const <String, bool>{kJmPluginUuid: true, kBikaPluginUuid: true};
    context.pushRoute(
      SearchAggregateResultRoute(
        searchEvent: event,
        searchCubit: searchCubit,
        selectedSources: {
          kJmPluginUuid: selected[kJmPluginUuid] ?? true,
          kBikaPluginUuid: selected[kBikaPluginUuid] ?? true,
        },
      ),
    );
    return;
  }

  context.pushRoute(
    SearchResultRoute(searchEvent: event, searchCubit: searchCubit),
  );
}
