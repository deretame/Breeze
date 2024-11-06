import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zephyr/page/mainPage/search/page/comic_page.dart';
import 'package:zephyr/page/ranking_list/ranking_list.dart';
import 'package:zephyr/page/shunt_page.dart';

import '../page/login_page.dart';
import '../page/main.dart';
import '../page/mainPage/search/page/comic_info_page.dart';
import '../page/mainPage/search/page/comic_search_page.dart';
import '../page/register_page.dart';
import '../page/webview_page.dart';
import '../type/comic_ep_info.dart';
import '../type/search_enter.dart';

final goRouter = GoRouter(
  initialLocation: '/main',
  routes: [
    // GoRoute(
    //   path: '/init',
    //   builder: (context, state) => const InitPage(),
    // ),
    GoRoute(
      path: '/shunt',
      builder: (context, state) => const ShuntPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/main',
      builder: (context, state) => const MainPage(),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => ComicSearchPage(
        enter: state.extra! as SearchEnter,
      ),
    ),
    GoRoute(
      path: '/rankingList',
      builder: (context, state) => RankingListPage(),
    ),
    GoRoute(
      path: '/webview',
      builder: (context, state) => WebViewPage(
        info: state.extra! as List<String>,
      ),
    ),
    GoRoute(
      path: '/comicInfo',
      builder: (context, state) => ComicInfoPage(
        comicId: state.extra! as String,
      ),
    ),
    GoRoute(
      path: '/comic',
      builder: (context, state) =>
          ComicPage(comicEpInfo: state.extra! as ComicEpInfo),
    ),
  ],
  errorBuilder: (context, state) => ErrorPage(error: state.error),
);

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key, required this.error});

  final GoException? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Text('Error: ${error?.message ?? "Unknown error"}'),
      ),
    );
  }
}

// 导航到命名路由
void navigateTo(BuildContext context, String path, {Object? extra}) {
  context.push(path, extra: extra);
}

// 导航到命名路由
// 不显示返回按钮
// 并移除之前的所有路由
void navigateToNoReturn(BuildContext context, String path, {Object? extra}) {
  context.go(path, extra: extra);
}

// 导航到命名路由
// 但是是替换当前路由
void navigateReplace(BuildContext context, String path, {Object? extra}) {
  context.replace(path, extra: extra);
}

void navigateToLogin(BuildContext context) {
  navigateToNoReturn(context, '/login');
}

void navigatePop(BuildContext context) {
  context.pop();
}
