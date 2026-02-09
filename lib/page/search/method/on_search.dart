import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/page/search_result/bloc/search_bloc.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/router/router.gr.dart';

void onSearch(BuildContext context, String keyword, {String url = ""}) async {
  final searchCubit = context.read<SearchCubit>();
  searchCubit.update(searchCubit.state.copyWith(searchKeyword: keyword));
  if (searchCubit.state.from == From.jm) {
    if (keyword.let(toInt) >= 100) {
      context.pushRoute(
        ComicInfoRoute(
          comicId: keyword,
          type: ComicEntryType.normal,
          from: From.jm,
        ),
      );

      final settingCubit = context.read<GlobalSettingCubit>();
      final history = settingCubit.state.searchHistory.toList();
      history
        ..remove(keyword)
        ..insert(0, keyword);
      await Future.delayed(const Duration(milliseconds: 200));
      settingCubit.updateSearchHistory(history.take(200).toList());
      return;
    }
  }

  if (url == keyword) {
    url = "";
  }

  context.pushRoute(
    SearchResultRoute(
      searchEvent: SearchEvent().copyWith(
        searchStates: searchCubit.state,
        url: url,
      ),
      searchCubit: searchCubit,
    ),
  );
}
