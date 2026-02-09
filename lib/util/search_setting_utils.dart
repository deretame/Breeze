import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/bika/bika_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/bookshelf/models/events.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';

/// 处理高级搜索设置的更新逻辑
///
/// 检查并更新 brevity 和 shieldCategoryMap 设置，如果有变化则发送相应事件
/// 返回 true 表示有设置项发生变化
bool updateAdvancedSearchSettings(
  BuildContext context,
  SearchStates newStates,
) {
  final bikaSettingCubit = context.read<BikaSettingCubit>();
  final state = bikaSettingCubit.state;
  final brevityChanged = state.brevity != newStates.brevity;
  final categoryChanged = state.shieldCategoryMap != newStates.categoriesBlock;

  if (brevityChanged) bikaSettingCubit.updateBrevity(newStates.brevity);
  if (categoryChanged) {
    bikaSettingCubit.updateShieldCategoryMap(newStates.categoriesBlock);
  }

  if (brevityChanged || categoryChanged) {
    eventBus.fire(HistoryEvent(EventType.refresh, false));
    eventBus.fire(DownloadEvent(EventType.refresh, false));
    eventBus.fire(FavoriteEvent(EventType.refresh, SortType.dd, 1));
  }

  return brevityChanged || categoryChanged;
}
