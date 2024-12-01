// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i15;
import 'package:flutter/material.dart' as _i16;
import 'package:zephyr/page/comic_info/json/comic_info/comic_info.dart' as _i17;
import 'package:zephyr/page/comic_info/json/eps/eps.dart' as _i18;
import 'package:zephyr/page/comic_info/view/comic_info.dart' as _i1;
import 'package:zephyr/page/comic_read/view/comic_read.dart' as _i2;
import 'package:zephyr/page/favourite/view/favorite_page.dart' as _i3;
import 'package:zephyr/page/history/history.dart' as _i19;
import 'package:zephyr/page/history/view/history_page.dart' as _i4;
import 'package:zephyr/page/home/view/home.dart' as _i5;
import 'package:zephyr/page/login_page.dart' as _i6;
import 'package:zephyr/page/main.dart' as _i7;
import 'package:zephyr/page/ranking_list/view/ranking_list_page.dart' as _i8;
import 'package:zephyr/page/register_page.dart' as _i9;
import 'package:zephyr/page/search/view/search.dart' as _i10;
import 'package:zephyr/page/search_result/search_result.dart' as _i20;
import 'package:zephyr/page/search_result/view/search_result_page.dart' as _i11;
import 'package:zephyr/page/setting/view/setting.dart' as _i12;
import 'package:zephyr/page/shunt_page.dart' as _i13;
import 'package:zephyr/page/webview_page.dart' as _i14;

/// generated route for
/// [_i1.ComicInfoPage]
class ComicInfoRoute extends _i15.PageRouteInfo<ComicInfoRouteArgs> {
  ComicInfoRoute({
    _i16.Key? key,
    required String comicId,
    List<_i15.PageRouteInfo>? children,
  }) : super(
          ComicInfoRoute.name,
          args: ComicInfoRouteArgs(
            key: key,
            comicId: comicId,
          ),
          initialChildren: children,
        );

  static const String name = 'ComicInfoRoute';

  static _i15.PageInfo page = _i15.PageInfo(
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

  final _i16.Key? key;

  final String comicId;

  @override
  String toString() {
    return 'ComicInfoRouteArgs{key: $key, comicId: $comicId}';
  }
}

/// generated route for
/// [_i2.ComicReadPage]
class ComicReadRoute extends _i15.PageRouteInfo<ComicReadRouteArgs> {
  ComicReadRoute({
    _i16.Key? key,
    required _i17.Comic comicInfo,
    required List<_i18.Doc> epsInfo,
    required _i18.Doc doc,
    required String comicId,
    required bool? isHistory,
    List<_i15.PageRouteInfo>? children,
  }) : super(
          ComicReadRoute.name,
          args: ComicReadRouteArgs(
            key: key,
            comicInfo: comicInfo,
            epsInfo: epsInfo,
            doc: doc,
            comicId: comicId,
            isHistory: isHistory,
          ),
          initialChildren: children,
        );

  static const String name = 'ComicReadRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ComicReadRouteArgs>();
      return _i2.ComicReadPage(
        key: args.key,
        comicInfo: args.comicInfo,
        epsInfo: args.epsInfo,
        doc: args.doc,
        comicId: args.comicId,
        isHistory: args.isHistory,
      );
    },
  );
}

class ComicReadRouteArgs {
  const ComicReadRouteArgs({
    this.key,
    required this.comicInfo,
    required this.epsInfo,
    required this.doc,
    required this.comicId,
    required this.isHistory,
  });

  final _i16.Key? key;

  final _i17.Comic comicInfo;

  final List<_i18.Doc> epsInfo;

  final _i18.Doc doc;

  final String comicId;

  final bool? isHistory;

  @override
  String toString() {
    return 'ComicReadRouteArgs{key: $key, comicInfo: $comicInfo, epsInfo: $epsInfo, doc: $doc, comicId: $comicId, isHistory: $isHistory}';
  }
}

/// generated route for
/// [_i3.FavoritePage]
class FavoriteRoute extends _i15.PageRouteInfo<void> {
  const FavoriteRoute({List<_i15.PageRouteInfo>? children})
      : super(
          FavoriteRoute.name,
          initialChildren: children,
        );

  static const String name = 'FavoriteRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      return const _i3.FavoritePage();
    },
  );
}

/// generated route for
/// [_i4.HistoryPage]
class HistoryRoute extends _i15.PageRouteInfo<HistoryRouteArgs> {
  HistoryRoute({
    _i16.Key? key,
    required _i19.SearchEnterConst searchEnterConst,
    List<_i15.PageRouteInfo>? children,
  }) : super(
          HistoryRoute.name,
          args: HistoryRouteArgs(
            key: key,
            searchEnterConst: searchEnterConst,
          ),
          initialChildren: children,
        );

  static const String name = 'HistoryRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<HistoryRouteArgs>();
      return _i4.HistoryPage(
        key: args.key,
        searchEnterConst: args.searchEnterConst,
      );
    },
  );
}

class HistoryRouteArgs {
  const HistoryRouteArgs({
    this.key,
    required this.searchEnterConst,
  });

  final _i16.Key? key;

  final _i19.SearchEnterConst searchEnterConst;

  @override
  String toString() {
    return 'HistoryRouteArgs{key: $key, searchEnterConst: $searchEnterConst}';
  }
}

/// generated route for
/// [_i5.HomePage]
class HomeRoute extends _i15.PageRouteInfo<void> {
  const HomeRoute({List<_i15.PageRouteInfo>? children})
      : super(
          HomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      return const _i5.HomePage();
    },
  );
}

/// generated route for
/// [_i6.LoginPage]
class LoginRoute extends _i15.PageRouteInfo<void> {
  const LoginRoute({List<_i15.PageRouteInfo>? children})
      : super(
          LoginRoute.name,
          initialChildren: children,
        );

  static const String name = 'LoginRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      return const _i6.LoginPage();
    },
  );
}

/// generated route for
/// [_i7.MainPage]
class MainRoute extends _i15.PageRouteInfo<void> {
  const MainRoute({List<_i15.PageRouteInfo>? children})
      : super(
          MainRoute.name,
          initialChildren: children,
        );

  static const String name = 'MainRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      return const _i7.MainPage();
    },
  );
}

/// generated route for
/// [_i8.RankingListPage]
class RankingListRoute extends _i15.PageRouteInfo<void> {
  const RankingListRoute({List<_i15.PageRouteInfo>? children})
      : super(
          RankingListRoute.name,
          initialChildren: children,
        );

  static const String name = 'RankingListRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      return const _i8.RankingListPage();
    },
  );
}

/// generated route for
/// [_i9.RegisterPage]
class RegisterRoute extends _i15.PageRouteInfo<void> {
  const RegisterRoute({List<_i15.PageRouteInfo>? children})
      : super(
          RegisterRoute.name,
          initialChildren: children,
        );

  static const String name = 'RegisterRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      return const _i9.RegisterPage();
    },
  );
}

/// generated route for
/// [_i10.SearchPage]
class SearchRoute extends _i15.PageRouteInfo<void> {
  const SearchRoute({List<_i15.PageRouteInfo>? children})
      : super(
          SearchRoute.name,
          initialChildren: children,
        );

  static const String name = 'SearchRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      return const _i10.SearchPage();
    },
  );
}

/// generated route for
/// [_i11.SearchResultPage]
class SearchResultRoute extends _i15.PageRouteInfo<SearchResultRouteArgs> {
  SearchResultRoute({
    _i16.Key? key,
    required _i20.SearchEnterConst searchEnterConst,
    List<_i15.PageRouteInfo>? children,
  }) : super(
          SearchResultRoute.name,
          args: SearchResultRouteArgs(
            key: key,
            searchEnterConst: searchEnterConst,
          ),
          initialChildren: children,
        );

  static const String name = 'SearchResultRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SearchResultRouteArgs>();
      return _i11.SearchResultPage(
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

  final _i16.Key? key;

  final _i20.SearchEnterConst searchEnterConst;

  @override
  String toString() {
    return 'SearchResultRouteArgs{key: $key, searchEnterConst: $searchEnterConst}';
  }
}

/// generated route for
/// [_i12.SettingsPage]
class SettingsRoute extends _i15.PageRouteInfo<void> {
  const SettingsRoute({List<_i15.PageRouteInfo>? children})
      : super(
          SettingsRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      return const _i12.SettingsPage();
    },
  );
}

/// generated route for
/// [_i13.ShuntPage]
class ShuntRoute extends _i15.PageRouteInfo<void> {
  const ShuntRoute({List<_i15.PageRouteInfo>? children})
      : super(
          ShuntRoute.name,
          initialChildren: children,
        );

  static const String name = 'ShuntRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      return const _i13.ShuntPage();
    },
  );
}

/// generated route for
/// [_i14.WebViewPage]
class WebViewRoute extends _i15.PageRouteInfo<WebViewRouteArgs> {
  WebViewRoute({
    _i16.Key? key,
    required List<String> info,
    List<_i15.PageRouteInfo>? children,
  }) : super(
          WebViewRoute.name,
          args: WebViewRouteArgs(
            key: key,
            info: info,
          ),
          initialChildren: children,
        );

  static const String name = 'WebViewRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<WebViewRouteArgs>();
      return _i14.WebViewPage(
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

  final _i16.Key? key;

  final List<String> info;

  @override
  String toString() {
    return 'WebViewRouteArgs{key: $key, info: $info}';
  }
}
