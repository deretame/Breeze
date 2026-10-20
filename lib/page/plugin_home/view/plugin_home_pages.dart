import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zephyr/cubit/plugin_registry_cubit.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/page/plugin_home/cubit/plugin_home_cubit.dart';
import 'package:zephyr/page/plugin_home/plugin_home_memory.dart';
import 'package:zephyr/page/plugin_home/view/plugin_home_scaffold.dart';

/// 第一页：插件首页。调用 `getPluginHomePagesBundle`，记忆 key 为 `homePluginId`。
@RoutePage()
class PluginHomePage extends StatelessWidget {
  const PluginHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final registry = context.read<PluginRegistryCubit>();
    return PluginHomeScaffold(
      pageTitle: t.navigation.home,
      selectorTitle: t.navigation.home,
      createCubit: () => PluginHomeCubit(
        bundleFnPath: 'getPluginHomePagesBundle',
        capabilityFlag: 'haveHome',
        readMemory: PluginHomeMemory.readHomePluginId,
        writeMemory: PluginHomeMemory.writeHomePluginId,
        registry: registry,
      ),
    );
  }
}

/// 第二页：云端收藏。调用 `getPluginCloudFavoritePagesBundle`，
/// 记忆 key 为 `cloudFavoritePluginId`。
@RoutePage()
class PluginCloudFavoritePage extends StatelessWidget {
  const PluginCloudFavoritePage({super.key});

  @override
  Widget build(BuildContext context) {
    final registry = context.read<PluginRegistryCubit>();
    return PluginHomeScaffold(
      pageTitle: t.navigation.rank,
      selectorTitle: t.oldHome.cloudFavorite,
      createCubit: () => PluginHomeCubit(
        bundleFnPath: 'getPluginCloudFavoritePagesBundle',
        capabilityFlag: 'haveCloudFavorite',
        readMemory: PluginHomeMemory.readCloudFavoritePluginId,
        writeMemory: PluginHomeMemory.writeCloudFavoritePluginId,
        registry: registry,
      ),
    );
  }
}
