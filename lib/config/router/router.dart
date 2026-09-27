import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/config/router/router.gr.dart';

/// 无动画路由过渡：直接返回页面本身，不消费动画值。
Widget instantRouteTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return child;
}

@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType {
    // 墨水屏：路由直接出图，不留 300ms 的滑动/淡入中间帧。
    if (eInkInstantRoutes) {
      return RouteType.custom(
        opaque: true,
        transitionsBuilder: instantRouteTransition,
        duration: Duration.zero,
        reverseDuration: Duration.zero,
      );
    }
    return RouteType.material(enablePredictiveBackGesture: false);
  }

  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: AppBootstrapRoute.page, initial: true),
    AutoRoute(page: CoreMLUpscaleDebugRoute.page),
    AutoRoute(page: NavigationBar.page),
    AutoRoute(page: LoginRoute.page),
    AutoRoute(page: ComicListRoute.page),
    AutoRoute(page: DiscoverRoute.page),
    AutoRoute(page: SearchResultRoute.page),
    AutoRoute(page: SearchAggregateResultRoute.page),
    AutoRoute(page: ComicInfoRoute.page),
    AutoRoute(page: CommentsRoute.page),
    AutoRoute(page: PluginCommentsScaffoldRoute.page),
    AutoRoute(page: ComicReadRoute.page),
    AutoRoute(page: WebViewRoute.page),
    AutoRoute(page: GlobalSettingRoute.page),
    AutoRoute(page: AppearanceSettingRoute.page),
    AutoRoute(page: ContentNetworkSettingRoute.page),
    AutoRoute(page: SyncSettingRoute.page),
    AutoRoute(page: AppBehaviorSettingRoute.page),
    AutoRoute(page: EInkSettingRoute.page),
    AutoRoute(page: StorageSettingRoute.page),
    AutoRoute(page: DebugSettingRoute.page),
    AutoRoute(page: ThemeColorRoute.page),
    AutoRoute(page: WebDavSyncRoute.page),
    AutoRoute(page: ShowColorRoute.page),
    AutoRoute(page: AboutRoute.page),
    AutoRoute(page: FullRouteImageRoute.page),
    AutoRoute(page: ChangelogRoute.page),
    AutoRoute(page: SearchRoute.page),
    AutoRoute(page: DownloadTaskRoute.page),
    AutoRoute(page: PluginStoreRoute.page),
    AutoRoute(page: PluginSettingsRoute.page),
    AutoRoute(page: PluginFunctionRoute.page),
    AutoRoute(page: OldHomeRoute.page),
    AutoRoute(page: OldRankingRoute.page),
    AutoRoute(page: MoreRoute.page),
    AutoRoute(page: QjsRuntimeDebugRoute.page),
    AutoRoute(page: CacheSettingRoute.page),
    AutoRoute(page: RealSrSettingRoute.page),
    AutoRoute(page: BookshelfSettingRoute.page),
    AutoRoute(page: DataBackupRoute.page),
    AutoRoute(page: ComicFollowRoute.page),
  ];

  @override
  List<AutoRouteGuard> get guards => [];
}

void popToRoot(BuildContext context) {
  context.router.popUntil((route) => route.settings.name == 'NavigationBar');
}
