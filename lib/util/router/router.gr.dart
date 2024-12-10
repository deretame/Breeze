// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i18;
import 'package:flutter/material.dart' as _i19;
import 'package:zephyr/page/comic_info/json/comic_info/comic_info.dart' as _i20;
import 'package:zephyr/page/comic_info/json/eps/eps.dart' as _i21;
import 'package:zephyr/page/comic_info/view/comic_info.dart' as _i2;
import 'package:zephyr/page/comic_read/view/comic_read.dart' as _i3;
import 'package:zephyr/page/comments/view/comments.dart' as _i4;
import 'package:zephyr/page/favourite/view/favorite_page.dart' as _i5;
import 'package:zephyr/page/history/history.dart' as _i22;
import 'package:zephyr/page/history/view/history_page.dart' as _i7;
import 'package:zephyr/page/home/view/home.dart' as _i8;
import 'package:zephyr/page/login_page.dart' as _i9;
import 'package:zephyr/page/main.dart' as _i10;
import 'package:zephyr/page/ranking_list/view/ranking_list_page.dart' as _i11;
import 'package:zephyr/page/register_page.dart' as _i12;
import 'package:zephyr/page/search/view/search.dart' as _i13;
import 'package:zephyr/page/search_result/search_result.dart' as _i23;
import 'package:zephyr/page/search_result/view/search_result_page.dart' as _i14;
import 'package:zephyr/page/setting/view/bika_setting.dart' as _i1;
import 'package:zephyr/page/setting/view/global_setting.dart' as _i6;
import 'package:zephyr/page/setting/view/setting.dart' as _i15;
import 'package:zephyr/page/shunt_page.dart' as _i16;
import 'package:zephyr/page/webview_page.dart' as _i17;

/// generated route for
/// [_i1.BikaSettingPage]
class BikaSettingRoute extends _i18.PageRouteInfo<void> {
  const BikaSettingRoute({List<_i18.PageRouteInfo>? children})
      : super(
          BikaSettingRoute.name,
          initialChildren: children,
        );

  static const String name = 'BikaSettingRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      return const _i1.BikaSettingPage();
    },
  );
}

/// generated route for
/// [_i2.ComicInfoPage]
class ComicInfoRoute extends _i18.PageRouteInfo<ComicInfoRouteArgs> {
  ComicInfoRoute({
    _i19.Key? key,
    required String comicId,
    List<_i18.PageRouteInfo>? children,
  }) : super(
          ComicInfoRoute.name,
          args: ComicInfoRouteArgs(
            key: key,
            comicId: comicId,
          ),
          initialChildren: children,
        );

  static const String name = 'ComicInfoRoute';

  static _i18.PageInfo page = _i18.PageInfo(
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

  final _i19.Key? key;

  final String comicId;

  @override
  String toString() {
    return 'ComicInfoRouteArgs{key: $key, comicId: $comicId}';
  }
}

/// generated route for
/// [_i3.ComicReadPage]
class ComicReadRoute extends _i18.PageRouteInfo<ComicReadRouteArgs> {
  ComicReadRoute({
    _i19.Key? key,
    required _i20.Comic comicInfo,
    required List<_i21.Doc> epsInfo,
    required _i21.Doc doc,
    required String comicId,
    required bool? isHistory,
    List<_i18.PageRouteInfo>? children,
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

  static _i18.PageInfo page = _i18.PageInfo(
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

  final _i19.Key? key;

  final _i20.Comic comicInfo;

  final List<_i21.Doc> epsInfo;

  final _i21.Doc doc;

  final String comicId;

  final bool? isHistory;

  @override
  String toString() {
    return 'ComicReadRouteArgs{key: $key, comicInfo: $comicInfo, epsInfo: $epsInfo, doc: $doc, comicId: $comicId, isHistory: $isHistory}';
  }
}

/// generated route for
/// [_i4.CommentsPage]
class CommentsRoute extends _i18.PageRouteInfo<CommentsRouteArgs> {
  CommentsRoute({
    _i19.Key? key,
    required String comicId,
    required String comicTitle,
    List<_i18.PageRouteInfo>? children,
  }) : super(
          CommentsRoute.name,
          args: CommentsRouteArgs(
            key: key,
            comicId: comicId,
            comicTitle: comicTitle,
          ),
          initialChildren: children,
        );

  static const String name = 'CommentsRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<CommentsRouteArgs>();
      return _i4.CommentsPage(
        key: args.key,
        comicId: args.comicId,
        comicTitle: args.comicTitle,
      );
    },
  );
}

class CommentsRouteArgs {
  const CommentsRouteArgs({
    this.key,
    required this.comicId,
    required this.comicTitle,
  });

  final _i19.Key? key;

  final String comicId;

  final String comicTitle;

  @override
  String toString() {
    return 'CommentsRouteArgs{key: $key, comicId: $comicId, comicTitle: $comicTitle}';
  }
}

/// generated route for
/// [_i5.FavoritePage]
class FavoriteRoute extends _i18.PageRouteInfo<void> {
  const FavoriteRoute({List<_i18.PageRouteInfo>? children})
      : super(
          FavoriteRoute.name,
          initialChildren: children,
        );

  static const String name = 'FavoriteRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      return const _i5.FavoritePage();
    },
  );
}

/// generated route for
/// [_i6.GlobalSettingPage]
class GlobalSettingRoute extends _i18.PageRouteInfo<void> {
  const GlobalSettingRoute({List<_i18.PageRouteInfo>? children})
      : super(
          GlobalSettingRoute.name,
          initialChildren: children,
        );

  static const String name = 'GlobalSettingRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      return const _i6.GlobalSettingPage();
    },
  );
}

/// generated route for
/// [_i7.HistoryPage]
class HistoryRoute extends _i18.PageRouteInfo<HistoryRouteArgs> {
  HistoryRoute({
    _i19.Key? key,
    required _i22.SearchEnterConst searchEnterConst,
    List<_i18.PageRouteInfo>? children,
  }) : super(
          HistoryRoute.name,
          args: HistoryRouteArgs(
            key: key,
            searchEnterConst: searchEnterConst,
          ),
          initialChildren: children,
        );

  static const String name = 'HistoryRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<HistoryRouteArgs>();
      return _i7.HistoryPage(
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

  final _i19.Key? key;

  final _i22.SearchEnterConst searchEnterConst;

  @override
  String toString() {
    return 'HistoryRouteArgs{key: $key, searchEnterConst: $searchEnterConst}';
  }
}

/// generated route for
/// [_i8.HomePage]
class HomeRoute extends _i18.PageRouteInfo<void> {
  const HomeRoute({List<_i18.PageRouteInfo>? children})
      : super(
          HomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      return const _i8.HomePage();
    },
  );
}

/// generated route for
/// [_i9.LoginPage]
class LoginRoute extends _i18.PageRouteInfo<void> {
  const LoginRoute({List<_i18.PageRouteInfo>? children})
      : super(
          LoginRoute.name,
          initialChildren: children,
        );

  static const String name = 'LoginRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      return const _i9.LoginPage();
    },
  );
}

/// generated route for
/// [_i10.MainPage]
class MainRoute extends _i18.PageRouteInfo<void> {
  const MainRoute({List<_i18.PageRouteInfo>? children})
      : super(
          MainRoute.name,
          initialChildren: children,
        );

  static const String name = 'MainRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      return const _i10.MainPage();
    },
  );
}

/// generated route for
/// [_i11.RankingListPage]
class RankingListRoute extends _i18.PageRouteInfo<void> {
  const RankingListRoute({List<_i18.PageRouteInfo>? children})
      : super(
          RankingListRoute.name,
          initialChildren: children,
        );

  static const String name = 'RankingListRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      return const _i11.RankingListPage();
    },
  );
}

/// generated route for
/// [_i12.RegisterPage]
class RegisterRoute extends _i18.PageRouteInfo<void> {
  const RegisterRoute({List<_i18.PageRouteInfo>? children})
      : super(
          RegisterRoute.name,
          initialChildren: children,
        );

  static const String name = 'RegisterRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      return const _i12.RegisterPage();
    },
  );
}

/// generated route for
/// [_i13.SearchPage]
class SearchRoute extends _i18.PageRouteInfo<void> {
  const SearchRoute({List<_i18.PageRouteInfo>? children})
      : super(
          SearchRoute.name,
          initialChildren: children,
        );

  static const String name = 'SearchRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      return const _i13.SearchPage();
    },
  );
}

/// generated route for
/// [_i14.SearchResultPage]
class SearchResultRoute extends _i18.PageRouteInfo<SearchResultRouteArgs> {
  SearchResultRoute({
    _i19.Key? key,
    required _i23.SearchEnterConst searchEnterConst,
    List<_i18.PageRouteInfo>? children,
  }) : super(
          SearchResultRoute.name,
          args: SearchResultRouteArgs(
            key: key,
            searchEnterConst: searchEnterConst,
          ),
          initialChildren: children,
        );

  static const String name = 'SearchResultRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SearchResultRouteArgs>();
      return _i14.SearchResultPage(
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

  final _i19.Key? key;

  final _i23.SearchEnterConst searchEnterConst;

  @override
  String toString() {
    return 'SearchResultRouteArgs{key: $key, searchEnterConst: $searchEnterConst}';
  }
}

/// generated route for
/// [_i15.SettingsPage]
class SettingsRoute extends _i18.PageRouteInfo<void> {
  const SettingsRoute({List<_i18.PageRouteInfo>? children})
      : super(
          SettingsRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      return const _i15.SettingsPage();
    },
  );
}

/// generated route for
/// [_i16.ShuntPage]
class ShuntRoute extends _i18.PageRouteInfo<void> {
  const ShuntRoute({List<_i18.PageRouteInfo>? children})
      : super(
          ShuntRoute.name,
          initialChildren: children,
        );

  static const String name = 'ShuntRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      return const _i16.ShuntPage();
    },
  );
}

/// generated route for
/// [_i17.WebViewPage]
class WebViewRoute extends _i18.PageRouteInfo<WebViewRouteArgs> {
  WebViewRoute({
    _i19.Key? key,
    required List<String> info,
    List<_i18.PageRouteInfo>? children,
  }) : super(
          WebViewRoute.name,
          args: WebViewRouteArgs(
            key: key,
            info: info,
          ),
          initialChildren: children,
        );

  static const String name = 'WebViewRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<WebViewRouteArgs>();
      return _i17.WebViewPage(
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

  final _i19.Key? key;

  final List<String> info;

  @override
  String toString() {
    return 'WebViewRouteArgs{key: $key, info: $info}';
  }
}
