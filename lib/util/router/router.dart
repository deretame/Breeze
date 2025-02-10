import 'package:auto_route/auto_route.dart';
import 'package:zephyr/util/router/router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => RouteType.material();

  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: MainRoute.page, initial: true),
        AutoRoute(page: HomeRoute.page),
        AutoRoute(page: LoginRoute.page),
        AutoRoute(page: RankingListRoute.page),
        AutoRoute(page: RegisterRoute.page),
        AutoRoute(page: SearchRoute.page),
        AutoRoute(page: CategoryRoute.page),
        AutoRoute(page: SearchResultRoute.page),
        AutoRoute(page: SettingsRoute.page),
        AutoRoute(page: ComicInfoRoute.page),
        AutoRoute(page: DownloadRoute.page),
        AutoRoute(page: CommentsRoute.page),
        AutoRoute(page: CommentsChildrenRoute.page),
        AutoRoute(page: ComicReadRoute.page),
        AutoRoute(page: WebViewRoute.page),
        AutoRoute(page: UserFavoriteRoute.page),
        AutoRoute(page: UserHistoryRoute.page),
        AutoRoute(page: UserDownloadRoute.page),
        AutoRoute(page: UserCommentsRoute.page),
        AutoRoute(page: BikaSettingRoute.page),
        AutoRoute(page: GlobalSettingRoute.page),
        AutoRoute(page: ThemeColorRoute.page),
        AutoRoute(page: WebDavSyncRoute.page),
        AutoRoute(page: ShowColorRoute.page),
        AutoRoute(page: AboutRoute.page),
      ];

  @override
  List<AutoRouteGuard> get guards => [];
}
