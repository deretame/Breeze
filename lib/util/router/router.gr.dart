// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i14;
import 'package:flutter/material.dart' as _i15;
import 'package:zephyr/page/comic_info/json/eps/eps.dart' as _i16;
import 'package:zephyr/page/comic_info/view/comic_info.dart' as _i1;
import 'package:zephyr/page/comic_read/view/comic_read.dart' as _i2;
import 'package:zephyr/page/favourite/view/favorite_page.dart' as _i3;
import 'package:zephyr/page/home/view/home.dart' as _i4;
import 'package:zephyr/page/login_page.dart' as _i5;
import 'package:zephyr/page/main.dart' as _i6;
import 'package:zephyr/page/mainPage/search_page/view.dart' as _i9;
import 'package:zephyr/page/mainPage/setting/setting_page.dart' as _i11;
import 'package:zephyr/page/ranking_list/view/ranking_list_page.dart' as _i7;
import 'package:zephyr/page/register_page.dart' as _i8;
import 'package:zephyr/page/search_result/search_result.dart' as _i17;
import 'package:zephyr/page/search_result/view/search_result_page.dart' as _i10;
import 'package:zephyr/page/shunt_page.dart' as _i12;
import 'package:zephyr/page/webview_page.dart' as _i13;

/// generated route for
/// [_i1.ComicInfoPage]
class ComicInfoRoute extends _i14.PageRouteInfo<ComicInfoRouteArgs> {
  ComicInfoRoute({
    _i15.Key? key,
    required String comicId,
    List<_i14.PageRouteInfo>? children,
  }) : super(
          ComicInfoRoute.name,
          args: ComicInfoRouteArgs(
            key: key,
            comicId: comicId,
          ),
          initialChildren: children,
        );

  static const String name = 'ComicInfoRoute';

  static _i14.PageInfo page = _i14.PageInfo(
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

  final _i15.Key? key;

  final String comicId;

  @override
  String toString() {
    return 'ComicInfoRouteArgs{key: $key, comicId: $comicId}';
  }
}

/// generated route for
/// [_i2.ComicReadPage]
class ComicReadRoute extends _i14.PageRouteInfo<ComicReadRouteArgs> {
  ComicReadRoute({
    _i15.Key? key,
    required List<_i16.Doc> epsInfo,
    required int epsId,
    required String comicId,
    List<_i14.PageRouteInfo>? children,
  }) : super(
          ComicReadRoute.name,
          args: ComicReadRouteArgs(
            key: key,
            epsInfo: epsInfo,
            epsId: epsId,
            comicId: comicId,
          ),
          initialChildren: children,
        );

  static const String name = 'ComicReadRoute';

  static _i14.PageInfo page = _i14.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ComicReadRouteArgs>();
      return _i2.ComicReadPage(
        key: args.key,
        epsInfo: args.epsInfo,
        epsId: args.epsId,
        comicId: args.comicId,
      );
    },
  );
}

class ComicReadRouteArgs {
  const ComicReadRouteArgs({
    this.key,
    required this.epsInfo,
    required this.epsId,
    required this.comicId,
  });

  final _i15.Key? key;

  final List<_i16.Doc> epsInfo;

  final int epsId;

  final String comicId;

  @override
  String toString() {
    return 'ComicReadRouteArgs{key: $key, epsInfo: $epsInfo, epsId: $epsId, comicId: $comicId}';
  }
}

/// generated route for
/// [_i3.FavoritePage]
class FavoriteRoute extends _i14.PageRouteInfo<void> {
  const FavoriteRoute({List<_i14.PageRouteInfo>? children})
      : super(
          FavoriteRoute.name,
          initialChildren: children,
        );

  static const String name = 'FavoriteRoute';

  static _i14.PageInfo page = _i14.PageInfo(
    name,
    builder: (data) {
      return const _i3.FavoritePage();
    },
  );
}

/// generated route for
/// [_i4.HomePage]
class HomeRoute extends _i14.PageRouteInfo<void> {
  const HomeRoute({List<_i14.PageRouteInfo>? children})
      : super(
          HomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeRoute';

  static _i14.PageInfo page = _i14.PageInfo(
    name,
    builder: (data) {
      return const _i4.HomePage();
    },
  );
}

/// generated route for
/// [_i5.LoginPage]
class LoginRoute extends _i14.PageRouteInfo<void> {
  const LoginRoute({List<_i14.PageRouteInfo>? children})
      : super(
          LoginRoute.name,
          initialChildren: children,
        );

  static const String name = 'LoginRoute';

  static _i14.PageInfo page = _i14.PageInfo(
    name,
    builder: (data) {
      return const _i5.LoginPage();
    },
  );
}

/// generated route for
/// [_i6.MainPage]
class MainRoute extends _i14.PageRouteInfo<void> {
  const MainRoute({List<_i14.PageRouteInfo>? children})
      : super(
          MainRoute.name,
          initialChildren: children,
        );

  static const String name = 'MainRoute';

  static _i14.PageInfo page = _i14.PageInfo(
    name,
    builder: (data) {
      return const _i6.MainPage();
    },
  );
}

/// generated route for
/// [_i7.RankingListPage]
class RankingListRoute extends _i14.PageRouteInfo<void> {
  const RankingListRoute({List<_i14.PageRouteInfo>? children})
      : super(
          RankingListRoute.name,
          initialChildren: children,
        );

  static const String name = 'RankingListRoute';

  static _i14.PageInfo page = _i14.PageInfo(
    name,
    builder: (data) {
      return const _i7.RankingListPage();
    },
  );
}

/// generated route for
/// [_i8.RegisterPage]
class RegisterRoute extends _i14.PageRouteInfo<void> {
  const RegisterRoute({List<_i14.PageRouteInfo>? children})
      : super(
          RegisterRoute.name,
          initialChildren: children,
        );

  static const String name = 'RegisterRoute';

  static _i14.PageInfo page = _i14.PageInfo(
    name,
    builder: (data) {
      return const _i8.RegisterPage();
    },
  );
}

/// generated route for
/// [_i9.SearchPage]
class SearchRoute extends _i14.PageRouteInfo<void> {
  const SearchRoute({List<_i14.PageRouteInfo>? children})
      : super(
          SearchRoute.name,
          initialChildren: children,
        );

  static const String name = 'SearchRoute';

  static _i14.PageInfo page = _i14.PageInfo(
    name,
    builder: (data) {
      return const _i9.SearchPage();
    },
  );
}

/// generated route for
/// [_i10.SearchResultPage]
class SearchResultRoute extends _i14.PageRouteInfo<SearchResultRouteArgs> {
  SearchResultRoute({
    _i15.Key? key,
    required _i17.SearchEnterConst searchEnterConst,
    List<_i14.PageRouteInfo>? children,
  }) : super(
          SearchResultRoute.name,
          args: SearchResultRouteArgs(
            key: key,
            searchEnterConst: searchEnterConst,
          ),
          initialChildren: children,
        );

  static const String name = 'SearchResultRoute';

  static _i14.PageInfo page = _i14.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SearchResultRouteArgs>();
      return _i10.SearchResultPage(
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

  final _i15.Key? key;

  final _i17.SearchEnterConst searchEnterConst;

  @override
  String toString() {
    return 'SearchResultRouteArgs{key: $key, searchEnterConst: $searchEnterConst}';
  }
}

/// generated route for
/// [_i11.SettingsPage]
class SettingsRoute extends _i14.PageRouteInfo<void> {
  const SettingsRoute({List<_i14.PageRouteInfo>? children})
      : super(
          SettingsRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsRoute';

  static _i14.PageInfo page = _i14.PageInfo(
    name,
    builder: (data) {
      return const _i11.SettingsPage();
    },
  );
}

/// generated route for
/// [_i12.ShuntPage]
class ShuntRoute extends _i14.PageRouteInfo<void> {
  const ShuntRoute({List<_i14.PageRouteInfo>? children})
      : super(
          ShuntRoute.name,
          initialChildren: children,
        );

  static const String name = 'ShuntRoute';

  static _i14.PageInfo page = _i14.PageInfo(
    name,
    builder: (data) {
      return const _i12.ShuntPage();
    },
  );
}

/// generated route for
/// [_i13.WebViewPage]
class WebViewRoute extends _i14.PageRouteInfo<WebViewRouteArgs> {
  WebViewRoute({
    _i15.Key? key,
    required List<String> info,
    List<_i14.PageRouteInfo>? children,
  }) : super(
          WebViewRoute.name,
          args: WebViewRouteArgs(
            key: key,
            info: info,
          ),
          initialChildren: children,
        );

  static const String name = 'WebViewRoute';

  static _i14.PageInfo page = _i14.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<WebViewRouteArgs>();
      return _i13.WebViewPage(
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

  final _i15.Key? key;

  final List<String> info;

  @override
  String toString() {
    return 'WebViewRouteArgs{key: $key, info: $info}';
  }
}
