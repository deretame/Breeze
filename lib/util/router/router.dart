import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:zephyr/util/router/router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => RouteType.material();

  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: NavigationBar.page, initial: true),
    AutoRoute(page: LoginRoute.page),
    AutoRoute(page: RankingListRoute.page),
    AutoRoute(page: RegisterRoute.page),
    AutoRoute(page: HomeRoute.page),
    AutoRoute(page: SearchResultRoute.page),
    AutoRoute(page: ComicInfoRoute.page),
    AutoRoute(page: DownloadRoute.page),
    AutoRoute(page: CommentsRoute.page),
    AutoRoute(page: CommentsChildrenRoute.page),
    AutoRoute(page: ComicReadRoute.page),
    AutoRoute(page: WebViewRoute.page),
    AutoRoute(page: UserCommentsRoute.page),
    AutoRoute(page: BikaSettingRoute.page),
    AutoRoute(page: GlobalSettingRoute.page),
    AutoRoute(page: ThemeColorRoute.page),
    AutoRoute(page: WebDavSyncRoute.page),
    AutoRoute(page: ShowColorRoute.page),
    AutoRoute(page: AboutRoute.page),
    AutoRoute(page: JmSearchResultRoute.page),
    AutoRoute(page: JmComicInfoRoute.page),
    AutoRoute(page: FullRouteImageRoute.page),
    AutoRoute(page: ImageCropRoute.page),
    AutoRoute(page: JmCommentsRoute.page),
    AutoRoute(page: JmDownloadRoute.page),
    AutoRoute(page: JMSettingRoute.page),
    AutoRoute(page: JmPromoteListRoute.page),
    AutoRoute(page: JmRankingRoute.page),
  ];

  @override
  List<AutoRouteGuard> get guards => [];
}

void popToRoot(BuildContext context) {
  context.router.popUntil((route) => route.settings.name == 'NavigationBar');
}
