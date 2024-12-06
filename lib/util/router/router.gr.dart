// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i17;
import 'package:flutter/material.dart' as _i18;
import 'package:zephyr/page/comic_info/json/comic_info/comic_info.dart' as _i19;
import 'package:zephyr/page/comic_info/json/eps/eps.dart' as _i20;
import 'package:zephyr/page/comic_info/view/comic_info.dart' as _i2;
import 'package:zephyr/page/comic_read/view/comic_read.dart' as _i3;
import 'package:zephyr/page/favourite/view/favorite_page.dart' as _i4;
import 'package:zephyr/page/history/history.dart' as _i21;
import 'package:zephyr/page/history/view/history_page.dart' as _i6;
import 'package:zephyr/page/home/view/home.dart' as _i7;
import 'package:zephyr/page/login_page.dart' as _i8;
import 'package:zephyr/page/main.dart' as _i9;
import 'package:zephyr/page/ranking_list/view/ranking_list_page.dart' as _i10;
import 'package:zephyr/page/register_page.dart' as _i11;
import 'package:zephyr/page/search/view/search.dart' as _i12;
import 'package:zephyr/page/search_result/search_result.dart' as _i22;
import 'package:zephyr/page/search_result/view/search_result_page.dart' as _i13;
import 'package:zephyr/page/setting/view/bika_setting.dart' as _i1;
import 'package:zephyr/page/setting/view/global_setting.dart' as _i5;
import 'package:zephyr/page/setting/view/setting.dart' as _i14;
import 'package:zephyr/page/shunt_page.dart' as _i15;
import 'package:zephyr/page/webview_page.dart' as _i16;

/// generated route for
/// [_i1.BikaSettingPage]
class BikaSettingRoute extends _i17.PageRouteInfo<void> {
  const BikaSettingRoute({List<_i17.PageRouteInfo>? children})
      : super(
          BikaSettingRoute.name,
          initialChildren: children,
        );

  static const String name = 'BikaSettingRoute';

  static _i17.PageInfo page = _i17.PageInfo(
    name,
    builder: (data) {
      return const _i1.BikaSettingPage();
    },
  );
}

/// generated route for
/// [_i2.ComicInfoPage]
class ComicInfoRoute extends _i17.PageRouteInfo<ComicInfoRouteArgs> {
  ComicInfoRoute({
    _i18.Key? key,
    required String comicId,
    List<_i17.PageRouteInfo>? children,
  }) : super(
          ComicInfoRoute.name,
          args: ComicInfoRouteArgs(
            key: key,
            comicId: comicId,
          ),
          initialChildren: children,
        );

  static const String name = 'ComicInfoRoute';

  static _i17.PageInfo page = _i17.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ComicInfoRouteArgs>();
      return _i2.ComicInfoPage(
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

  final _i18.Key? key;

  final String comicId;

  @override
  String toString() {
    return 'ComicInfoRouteArgs{key: $key, comicId: $comicId}';
  }
}

/// generated route for
/// [_i3.ComicReadPage]
class ComicReadRoute extends _i17.PageRouteInfo<ComicReadRouteArgs> {
  ComicReadRoute({
    _i18.Key? key,
    required _i19.Comic comicInfo,
    required List<_i20.Doc> epsInfo,
    required _i20.Doc doc,
    required String comicId,
    required bool? isHistory,
    List<_i17.PageRouteInfo>? children,
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

  static _i17.PageInfo page = _i17.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ComicReadRouteArgs>();
      return _i3.ComicReadPage(
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

  final _i18.Key? key;

  final _i19.Comic comicInfo;

  final List<_i20.Doc> epsInfo;

  final _i20.Doc doc;

  final String comicId;

  final bool? isHistory;

  @override
  String toString() {
    return 'ComicReadRouteArgs{key: $key, comicInfo: $comicInfo, epsInfo: $epsInfo, doc: $doc, comicId: $comicId, isHistory: $isHistory}';
  }
}

/// generated route for
/// [_i4.FavoritePage]
class FavoriteRoute extends _i17.PageRouteInfo<void> {
  const FavoriteRoute({List<_i17.PageRouteInfo>? children})
      : super(
          FavoriteRoute.name,
          initialChildren: children,
        );

  static const String name = 'FavoriteRoute';

  static _i17.PageInfo page = _i17.PageInfo(
    name,
    builder: (data) {
      return const _i4.FavoritePage();
    },
  );
}

/// generated route for
/// [_i5.GlobalSettingPage]
class GlobalSettingRoute extends _i17.PageRouteInfo<void> {
  const GlobalSettingRoute({List<_i17.PageRouteInfo>? children})
      : super(
          GlobalSettingRoute.name,
          initialChildren: children,
        );

  static const String name = 'GlobalSettingRoute';

  static _i17.PageInfo page = _i17.PageInfo(
    name,
    builder: (data) {
      return const _i5.GlobalSettingPage();
    },
  );
}

/// generated route for
/// [_i6.HistoryPage]
class HistoryRoute extends _i17.PageRouteInfo<HistoryRouteArgs> {
  HistoryRoute({
    _i18.Key? key,
    required _i21.SearchEnterConst searchEnterConst,
    List<_i17.PageRouteInfo>? children,
  }) : super(
          HistoryRoute.name,
          args: HistoryRouteArgs(
            key: key,
            searchEnterConst: searchEnterConst,
          ),
          initialChildren: children,
        );

  static const String name = 'HistoryRoute';

  static _i17.PageInfo page = _i17.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<HistoryRouteArgs>();
      return _i6.HistoryPage(
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

  final _i18.Key? key;

  final _i21.SearchEnterConst searchEnterConst;

  @override
  String toString() {
    return 'HistoryRouteArgs{key: $key, searchEnterConst: $searchEnterConst}';
  }
}

/// generated route for
/// [_i7.HomePage]
class HomeRoute extends _i17.PageRouteInfo<void> {
  const HomeRoute({List<_i17.PageRouteInfo>? children})
      : super(
          HomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeRoute';

  static _i17.PageInfo page = _i17.PageInfo(
    name,
    builder: (data) {
      return const _i7.HomePage();
    },
  );
}

/// generated route for
/// [_i8.LoginPage]
class LoginRoute extends _i17.PageRouteInfo<void> {
  const LoginRoute({List<_i17.PageRouteInfo>? children})
      : super(
          LoginRoute.name,
          initialChildren: children,
        );

  static const String name = 'LoginRoute';

  static _i17.PageInfo page = _i17.PageInfo(
    name,
    builder: (data) {
      return const _i8.LoginPage();
    },
  );
}

/// generated route for
/// [_i9.MainPage]
class MainRoute extends _i17.PageRouteInfo<void> {
  const MainRoute({List<_i17.PageRouteInfo>? children})
      : super(
          MainRoute.name,
          initialChildren: children,
        );

  static const String name = 'MainRoute';

  static _i17.PageInfo page = _i17.PageInfo(
    name,
    builder: (data) {
      return const _i9.MainPage();
    },
  );
}

/// generated route for
/// [_i10.RankingListPage]
class RankingListRoute extends _i17.PageRouteInfo<void> {
  const RankingListRoute({List<_i17.PageRouteInfo>? children})
      : super(
          RankingListRoute.name,
          initialChildren: children,
        );

  static const String name = 'RankingListRoute';

  static _i17.PageInfo page = _i17.PageInfo(
    name,
    builder: (data) {
      return const _i10.RankingListPage();
    },
  );
}

/// generated route for
/// [_i11.RegisterPage]
class RegisterRoute extends _i17.PageRouteInfo<void> {
  const RegisterRoute({List<_i17.PageRouteInfo>? children})
      : super(
          RegisterRoute.name,
          initialChildren: children,
        );

  static const String name = 'RegisterRoute';

  static _i17.PageInfo page = _i17.PageInfo(
    name,
    builder: (data) {
      return const _i11.RegisterPage();
    },
  );
}

/// generated route for
/// [_i12.SearchPage]
class SearchRoute extends _i17.PageRouteInfo<void> {
  const SearchRoute({List<_i17.PageRouteInfo>? children})
      : super(
          SearchRoute.name,
          initialChildren: children,
        );

  static const String name = 'SearchRoute';

  static _i17.PageInfo page = _i17.PageInfo(
    name,
    builder: (data) {
      return const _i12.SearchPage();
    },
  );
}

/// generated route for
/// [_i13.SearchResultPage]
class SearchResultRoute extends _i17.PageRouteInfo<SearchResultRouteArgs> {
  SearchResultRoute({
    _i18.Key? key,
    required _i22.SearchEnterConst searchEnterConst,
    List<_i17.PageRouteInfo>? children,
  }) : super(
          SearchResultRoute.name,
          args: SearchResultRouteArgs(
            key: key,
            searchEnterConst: searchEnterConst,
          ),
          initialChildren: children,
        );

  static const String name = 'SearchResultRoute';

  static _i17.PageInfo page = _i17.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SearchResultRouteArgs>();
      return _i13.SearchResultPage(
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

  final _i18.Key? key;

  final _i22.SearchEnterConst searchEnterConst;

  @override
  String toString() {
    return 'SearchResultRouteArgs{key: $key, searchEnterConst: $searchEnterConst}';
  }
}

/// generated route for
/// [_i14.SettingsPage]
class SettingsRoute extends _i17.PageRouteInfo<void> {
  const SettingsRoute({List<_i17.PageRouteInfo>? children})
      : super(
          SettingsRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsRoute';

  static _i17.PageInfo page = _i17.PageInfo(
    name,
    builder: (data) {
      return const _i14.SettingsPage();
    },
  );
}

/// generated route for
/// [_i15.ShuntPage]
class ShuntRoute extends _i17.PageRouteInfo<void> {
  const ShuntRoute({List<_i17.PageRouteInfo>? children})
      : super(
          ShuntRoute.name,
          initialChildren: children,
        );

  static const String name = 'ShuntRoute';

  static _i17.PageInfo page = _i17.PageInfo(
    name,
    builder: (data) {
      return const _i15.ShuntPage();
    },
  );
}

/// generated route for
/// [_i16.WebViewPage]
class WebViewRoute extends _i17.PageRouteInfo<WebViewRouteArgs> {
  WebViewRoute({
    _i18.Key? key,
    required List<String> info,
    List<_i17.PageRouteInfo>? children,
  }) : super(
          WebViewRoute.name,
          args: WebViewRouteArgs(
            key: key,
            info: info,
          ),
          initialChildren: children,
        );

  static const String name = 'WebViewRoute';

  static _i17.PageInfo page = _i17.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<WebViewRouteArgs>();
      return _i16.WebViewPage(
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

  final _i18.Key? key;

  final List<String> info;

  @override
  String toString() {
    return 'WebViewRouteArgs{key: $key, info: $info}';
  }
}
