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
        AutoRoute(page: SearchResultRoute.page),
        AutoRoute(page: SettingsRoute.page),
        AutoRoute(page: ShuntRoute.page),
        AutoRoute(page: ComicInfoRoute.page),
        AutoRoute(page: ComicReadRoute.page),
        AutoRoute(page: WebViewRoute.page),
        AutoRoute(page: FavoriteRoute.page),
      ];

  @override
  List<AutoRouteGuard> get guards => [];
}
