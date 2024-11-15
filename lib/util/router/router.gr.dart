// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i12;
import 'package:flutter/material.dart' as _i13;
import 'package:zephyr/page/comic_info/view/comic_info.dart' as _i1;
import 'package:zephyr/page/home/view/home.dart' as _i2;
import 'package:zephyr/page/login_page.dart' as _i3;
import 'package:zephyr/page/main.dart' as _i4;
import 'package:zephyr/page/mainPage/search_page/view.dart' as _i7;
import 'package:zephyr/page/mainPage/setting/setting_page.dart' as _i9;
import 'package:zephyr/page/ranking_list/view/ranking_list_page.dart' as _i5;
import 'package:zephyr/page/register_page.dart' as _i6;
import 'package:zephyr/page/search_result/search_result.dart' as _i14;
import 'package:zephyr/page/search_result/view/search_result_page.dart' as _i8;
import 'package:zephyr/page/shunt_page.dart' as _i10;
import 'package:zephyr/page/webview_page.dart' as _i11;

/// generated route for
/// [_i1.ComicInfoPage]
class ComicInfoRoute extends _i12.PageRouteInfo<ComicInfoRouteArgs> {
  ComicInfoRoute({
    _i13.Key? key,
    required String comicId,
    List<_i12.PageRouteInfo>? children,
  }) : super(
          ComicInfoRoute.name,
          args: ComicInfoRouteArgs(
            key: key,
            comicId: comicId,
          ),
          initialChildren: children,
        );

  static const String name = 'ComicInfoRoute';

  static _i12.PageInfo page = _i12.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ComicInfoRouteArgs>();
      return _i1.ComicInfoPage(
        key: args.key,
        comicId: args.comicId,
      );
    },
  );
}

class ComicInfoRouteArgs {
  const ComicInfoRouteArgs({
    this.key,
    required this.comicId,
  });

  final _i13.Key? key;

  final String comicId;

  @override
  String toString() {
    return 'ComicInfoRouteArgs{key: $key, comicId: $comicId}';
  }
}

/// generated route for
/// [_i2.HomePage]
class HomeRoute extends _i12.PageRouteInfo<void> {
  const HomeRoute({List<_i12.PageRouteInfo>? children})
      : super(
          HomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeRoute';

  static _i12.PageInfo page = _i12.PageInfo(
    name,
    builder: (data) {
      return const _i2.HomePage();
    },
  );
}

/// generated route for
/// [_i3.LoginPage]
class LoginRoute extends _i12.PageRouteInfo<void> {
  const LoginRoute({List<_i12.PageRouteInfo>? children})
      : super(
          LoginRoute.name,
          initialChildren: children,
        );

  static const String name = 'LoginRoute';

  static _i12.PageInfo page = _i12.PageInfo(
    name,
    builder: (data) {
      return const _i3.LoginPage();
    },
  );
}

/// generated route for
/// [_i4.MainPage]
class MainRoute extends _i12.PageRouteInfo<void> {
  const MainRoute({List<_i12.PageRouteInfo>? children})
      : super(
          MainRoute.name,
          initialChildren: children,
        );

  static const String name = 'MainRoute';

  static _i12.PageInfo page = _i12.PageInfo(
    name,
    builder: (data) {
      return const _i4.MainPage();
    },
  );
}

/// generated route for
/// [_i5.RankingListPage]
class RankingListRoute extends _i12.PageRouteInfo<void> {
  const RankingListRoute({List<_i12.PageRouteInfo>? children})
      : super(
          RankingListRoute.name,
          initialChildren: children,
        );

  static const String name = 'RankingListRoute';

  static _i12.PageInfo page = _i12.PageInfo(
    name,
    builder: (data) {
      return const _i5.RankingListPage();
    },
  );
}

/// generated route for
/// [_i6.RegisterPage]
class RegisterRoute extends _i12.PageRouteInfo<void> {
  const RegisterRoute({List<_i12.PageRouteInfo>? children})
      : super(
          RegisterRoute.name,
          initialChildren: children,
        );

  static const String name = 'RegisterRoute';

  static _i12.PageInfo page = _i12.PageInfo(
    name,
    builder: (data) {
      return const _i6.RegisterPage();
    },
  );
}

/// generated route for
/// [_i7.SearchPage]
class SearchRoute extends _i12.PageRouteInfo<void> {
  const SearchRoute({List<_i12.PageRouteInfo>? children})
      : super(
          SearchRoute.name,
          initialChildren: children,
        );

  static const String name = 'SearchRoute';

  static _i12.PageInfo page = _i12.PageInfo(
    name,
    builder: (data) {
      return const _i7.SearchPage();
    },
  );
}

/// generated route for
/// [_i8.SearchResultPage]
class SearchResultRoute extends _i12.PageRouteInfo<SearchResultRouteArgs> {
  SearchResultRoute({
    _i13.Key? key,
    required _i14.SearchEnterConst searchEnterConst,
    List<_i12.PageRouteInfo>? children,
  }) : super(
          SearchResultRoute.name,
          args: SearchResultRouteArgs(
            key: key,
            searchEnterConst: searchEnterConst,
          ),
          initialChildren: children,
        );

  static const String name = 'SearchResultRoute';

  static _i12.PageInfo page = _i12.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SearchResultRouteArgs>();
      return _i8.SearchResultPage(
        key: args.key,
        searchEnterConst: args.searchEnterConst,
      );
    },
  );
}

class SearchResultRouteArgs {
  const SearchResultRouteArgs({
    this.key,
    required this.searchEnterConst,
  });

  final _i13.Key? key;

  final _i14.SearchEnterConst searchEnterConst;

  @override
  String toString() {
    return 'SearchResultRouteArgs{key: $key, searchEnterConst: $searchEnterConst}';
  }
}

/// generated route for
/// [_i9.SettingsPage]
class SettingsRoute extends _i12.PageRouteInfo<void> {
  const SettingsRoute({List<_i12.PageRouteInfo>? children})
      : super(
          SettingsRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsRoute';

  static _i12.PageInfo page = _i12.PageInfo(
    name,
    builder: (data) {
      return const _i9.SettingsPage();
    },
  );
}

/// generated route for
/// [_i10.ShuntPage]
class ShuntRoute extends _i12.PageRouteInfo<void> {
  const ShuntRoute({List<_i12.PageRouteInfo>? children})
      : super(
          ShuntRoute.name,
          initialChildren: children,
        );

  static const String name = 'ShuntRoute';

  static _i12.PageInfo page = _i12.PageInfo(
    name,
    builder: (data) {
      return const _i10.ShuntPage();
    },
  );
}

/// generated route for
/// [_i11.WebViewPage]
class WebViewRoute extends _i12.PageRouteInfo<WebViewRouteArgs> {
  WebViewRoute({
    _i13.Key? key,
    required List<String> info,
    List<_i12.PageRouteInfo>? children,
  }) : super(
          WebViewRoute.name,
          args: WebViewRouteArgs(
            key: key,
            info: info,
          ),
          initialChildren: children,
        );

  static const String name = 'WebViewRoute';

  static _i12.PageInfo page = _i12.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<WebViewRouteArgs>();
      return _i11.WebViewPage(
        key: args.key,
        info: args.info,
      );
    },
  );
}

class WebViewRouteArgs {
  const WebViewRouteArgs({
    this.key,
    required this.info,
  });

  final _i13.Key? key;

  final List<String> info;

  @override
  String toString() {
    return 'WebViewRouteArgs{key: $key, info: $info}';
  }
}
