import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zephyr/page/mainPage/search/page/comic_page.dart';
import 'package:zephyr/page/shunt_page.dart';

import '../page/init_page.dart';
import '../page/login_page.dart';
import '../page/mainPage/main.dart';
import '../page/mainPage/search/page/comic_info_page.dart';
import '../page/mainPage/search/page/comic_search_page.dart';
import '../type/comic_ep_info.dart';

final goRouter = GoRouter(
  initialLocation: '/shunt',
  routes: [
    GoRoute(
      path: '/init',
      builder: (context, state) => const InitPage(),
    ),
    GoRoute(
      path: '/shunt',
      builder: (context, state) => const ShuntPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/main',
      builder: (context, state) => const MainPage(),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const ComicSearchPage(),
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
  GoRouter.of(context).push(path, extra: extra);
}

// 导航到命名路由
// 不显示返回按钮
// 并移除之前的所有路由
void navigateToNoReturn(BuildContext context, String path, {Object? extra}) {
  GoRouter.of(context).go(path, extra: extra);
}

void navigateToLogin(BuildContext context) {
  navigateToNoReturn(context, '/login');
}

void navigatePop(BuildContext context) {
  GoRouter.of(context).pop();
}
