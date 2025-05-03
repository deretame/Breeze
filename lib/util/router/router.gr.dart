// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i24;
import 'package:flutter/material.dart' as _i25;
import 'package:zephyr/debug/show_color.dart' as _i19;
import 'package:zephyr/mobx/bool_select.dart' as _i30;
import 'package:zephyr/mobx/int_select.dart' as _i31;
import 'package:zephyr/page/about/view/about_page.dart' as _i1;
import 'package:zephyr/page/bookshelf/view/bookshelf_page.dart' as _i3;
import 'package:zephyr/page/category/view/category.dart' as _i4;
import 'package:zephyr/page/comic_info/json/bika/comic_info/comic_info.dart'
    as _i27;
import 'package:zephyr/page/comic_info/json/bika/eps/eps.dart' as _i28;
import 'package:zephyr/page/comic_info/view/comic_info.dart' as _i5;
import 'package:zephyr/page/comic_read/view/comic_read.dart' as _i6;
import 'package:zephyr/page/comments/json/comments_json/comments_json.dart'
    as _i29;
import 'package:zephyr/page/comments/view/comments.dart' as _i8;
import 'package:zephyr/page/comments_children/view/comments_children_page.dart'
    as _i7;
import 'package:zephyr/page/download/view/download.dart' as _i9;
import 'package:zephyr/page/jm/jm_comic_info/view/view.dart' as _i12;
import 'package:zephyr/page/jm/jm_search_result/jm_search_result.dart' as _i32;
import 'package:zephyr/page/jm/jm_search_result/view/view.dart' as _i13;
import 'package:zephyr/page/login_page.dart' as _i14;
import 'package:zephyr/page/navigation_bar.dart' as _i15;
import 'package:zephyr/page/ranking_list/view/ranking_list_page.dart' as _i16;
import 'package:zephyr/page/register_page.dart' as _i17;
import 'package:zephyr/page/search_result/search_result.dart' as _i33;
import 'package:zephyr/page/search_result/view/search_result_page.dart' as _i18;
import 'package:zephyr/page/setting/view/bika_setting.dart' as _i2;
import 'package:zephyr/page/setting/view/global_setting.dart' as _i11;
import 'package:zephyr/page/theme_color/view/theme_color_page.dart' as _i20;
import 'package:zephyr/page/user_comments/view/user_comments_page.dart' as _i21;
import 'package:zephyr/page/webdav_sync/view/webdav_sync_page.dart' as _i22;
import 'package:zephyr/page/webview_page.dart' as _i23;
import 'package:zephyr/type/enum.dart' as _i26;
import 'package:zephyr/widgets/full_screen_image_view.dart' as _i10;

/// generated route for
/// [_i1.AboutPage]
class AboutRoute extends _i24.PageRouteInfo<void> {
  const AboutRoute({List<_i24.PageRouteInfo>? children})
    : super(AboutRoute.name, initialChildren: children);

  static const String name = 'AboutRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i1.AboutPage();
    },
  );
}

/// generated route for
/// [_i2.BikaSettingPage]
class BikaSettingRoute extends _i24.PageRouteInfo<void> {
  const BikaSettingRoute({List<_i24.PageRouteInfo>? children})
    : super(BikaSettingRoute.name, initialChildren: children);

  static const String name = 'BikaSettingRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i2.BikaSettingPage();
    },
  );
}

/// generated route for
/// [_i3.BookshelfPage]
class BookshelfRoute extends _i24.PageRouteInfo<void> {
  const BookshelfRoute({List<_i24.PageRouteInfo>? children})
    : super(BookshelfRoute.name, initialChildren: children);

  static const String name = 'BookshelfRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i3.BookshelfPage();
    },
  );
}

/// generated route for
/// [_i4.CategoryPage]
class CategoryRoute extends _i24.PageRouteInfo<void> {
  const CategoryRoute({List<_i24.PageRouteInfo>? children})
    : super(CategoryRoute.name, initialChildren: children);

  static const String name = 'CategoryRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i4.CategoryPage();
    },
  );
}

/// generated route for
/// [_i5.ComicInfoPage]
class ComicInfoRoute extends _i24.PageRouteInfo<ComicInfoRouteArgs> {
  ComicInfoRoute({
    _i25.Key? key,
    required String comicId,
    required _i26.ComicEntryType type,
    List<_i24.PageRouteInfo>? children,
  }) : super(
         ComicInfoRoute.name,
         args: ComicInfoRouteArgs(key: key, comicId: comicId, type: type),
         initialChildren: children,
       );

  static const String name = 'ComicInfoRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ComicInfoRouteArgs>();
      return _i5.ComicInfoPage(
        key: args.key,
        comicId: args.comicId,
        type: args.type,
      );
    },
  );
}

class ComicInfoRouteArgs {
  const ComicInfoRouteArgs({
    this.key,
    required this.comicId,
    required this.type,
  });

  final _i25.Key? key;

  final String comicId;

  final _i26.ComicEntryType type;

  @override
  String toString() {
    return 'ComicInfoRouteArgs{key: $key, comicId: $comicId, type: $type}';
  }
}

/// generated route for
/// [_i6.ComicReadPage]
class ComicReadRoute extends _i24.PageRouteInfo<ComicReadRouteArgs> {
  ComicReadRoute({
    _i25.Key? key,
    required _i27.Comic comicInfo,
    required List<_i28.Doc> epsInfo,
    required _i28.Doc doc,
    required String comicId,
    _i26.ComicEntryType? type,
    List<_i24.PageRouteInfo>? children,
  }) : super(
         ComicReadRoute.name,
         args: ComicReadRouteArgs(
           key: key,
           comicInfo: comicInfo,
           epsInfo: epsInfo,
           doc: doc,
           comicId: comicId,
           type: type,
         ),
         initialChildren: children,
       );

  static const String name = 'ComicReadRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ComicReadRouteArgs>();
      return _i6.ComicReadPage(
        key: args.key,
        comicInfo: args.comicInfo,
        epsInfo: args.epsInfo,
        doc: args.doc,
        comicId: args.comicId,
        type: args.type,
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
    this.type,
  });

  final _i25.Key? key;

  final _i27.Comic comicInfo;

  final List<_i28.Doc> epsInfo;

  final _i28.Doc doc;

  final String comicId;

  final _i26.ComicEntryType? type;

  @override
  String toString() {
    return 'ComicReadRouteArgs{key: $key, comicInfo: $comicInfo, epsInfo: $epsInfo, doc: $doc, comicId: $comicId, type: $type}';
  }
}

/// generated route for
/// [_i7.CommentsChildrenPage]
class CommentsChildrenRoute
    extends _i24.PageRouteInfo<CommentsChildrenRouteArgs> {
  CommentsChildrenRoute({
    _i25.Key? key,
    required _i29.Doc fatherDoc,
    required _i30.BoolSelectStore store,
    required _i31.IntSelectStore likeCountStore,
    List<_i24.PageRouteInfo>? children,
  }) : super(
         CommentsChildrenRoute.name,
         args: CommentsChildrenRouteArgs(
           key: key,
           fatherDoc: fatherDoc,
           store: store,
           likeCountStore: likeCountStore,
         ),
         initialChildren: children,
       );

  static const String name = 'CommentsChildrenRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<CommentsChildrenRouteArgs>();
      return _i7.CommentsChildrenPage(
        key: args.key,
        fatherDoc: args.fatherDoc,
        store: args.store,
        likeCountStore: args.likeCountStore,
      );
    },
  );
}

class CommentsChildrenRouteArgs {
  const CommentsChildrenRouteArgs({
    this.key,
    required this.fatherDoc,
    required this.store,
    required this.likeCountStore,
  });

  final _i25.Key? key;

  final _i29.Doc fatherDoc;

  final _i30.BoolSelectStore store;

  final _i31.IntSelectStore likeCountStore;

  @override
  String toString() {
    return 'CommentsChildrenRouteArgs{key: $key, fatherDoc: $fatherDoc, store: $store, likeCountStore: $likeCountStore}';
  }
}

/// generated route for
/// [_i8.CommentsPage]
class CommentsRoute extends _i24.PageRouteInfo<CommentsRouteArgs> {
  CommentsRoute({
    _i25.Key? key,
    required String comicId,
    required String comicTitle,
    List<_i24.PageRouteInfo>? children,
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

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<CommentsRouteArgs>();
      return _i8.CommentsPage(
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

  final _i25.Key? key;

  final String comicId;

  final String comicTitle;

  @override
  String toString() {
    return 'CommentsRouteArgs{key: $key, comicId: $comicId, comicTitle: $comicTitle}';
  }
}

/// generated route for
/// [_i9.DownloadPage]
class DownloadRoute extends _i24.PageRouteInfo<DownloadRouteArgs> {
  DownloadRoute({
    _i25.Key? key,
    required _i27.Comic comicInfo,
    required List<_i28.Doc> epsInfo,
    List<_i24.PageRouteInfo>? children,
  }) : super(
         DownloadRoute.name,
         args: DownloadRouteArgs(
           key: key,
           comicInfo: comicInfo,
           epsInfo: epsInfo,
         ),
         initialChildren: children,
       );

  static const String name = 'DownloadRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<DownloadRouteArgs>();
      return _i9.DownloadPage(
        key: args.key,
        comicInfo: args.comicInfo,
        epsInfo: args.epsInfo,
      );
    },
  );
}

class DownloadRouteArgs {
  const DownloadRouteArgs({
    this.key,
    required this.comicInfo,
    required this.epsInfo,
  });

  final _i25.Key? key;

  final _i27.Comic comicInfo;

  final List<_i28.Doc> epsInfo;

  @override
  String toString() {
    return 'DownloadRouteArgs{key: $key, comicInfo: $comicInfo, epsInfo: $epsInfo}';
  }
}

/// generated route for
/// [_i10.FullScreenImagePage]
class FullRouteImageRoute extends _i24.PageRouteInfo<FullRouteImageRouteArgs> {
  FullRouteImageRoute({
    _i25.Key? key,
    required String imagePath,
    String? uuid,
    bool? showShade,
    List<_i24.PageRouteInfo>? children,
  }) : super(
         FullRouteImageRoute.name,
         args: FullRouteImageRouteArgs(
           key: key,
           imagePath: imagePath,
           uuid: uuid,
           showShade: showShade,
         ),
         initialChildren: children,
       );

  static const String name = 'FullRouteImageRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<FullRouteImageRouteArgs>();
      return _i10.FullScreenImagePage(
        key: args.key,
        imagePath: args.imagePath,
        uuid: args.uuid,
        showShade: args.showShade,
      );
    },
  );
}

class FullRouteImageRouteArgs {
  const FullRouteImageRouteArgs({
    this.key,
    required this.imagePath,
    this.uuid,
    this.showShade,
  });

  final _i25.Key? key;

  final String imagePath;

  final String? uuid;

  final bool? showShade;

  @override
  String toString() {
    return 'FullRouteImageRouteArgs{key: $key, imagePath: $imagePath, uuid: $uuid, showShade: $showShade}';
  }
}

/// generated route for
/// [_i11.GlobalSettingPage]
class GlobalSettingRoute extends _i24.PageRouteInfo<void> {
  const GlobalSettingRoute({List<_i24.PageRouteInfo>? children})
    : super(GlobalSettingRoute.name, initialChildren: children);

  static const String name = 'GlobalSettingRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i11.GlobalSettingPage();
    },
  );
}

/// generated route for
/// [_i12.JmComicInfoPage]
class JmComicInfoRoute extends _i24.PageRouteInfo<JmComicInfoRouteArgs> {
  JmComicInfoRoute({
    _i25.Key? key,
    required String comicId,
    required _i26.ComicEntryType type,
    List<_i24.PageRouteInfo>? children,
  }) : super(
         JmComicInfoRoute.name,
         args: JmComicInfoRouteArgs(key: key, comicId: comicId, type: type),
         initialChildren: children,
       );

  static const String name = 'JmComicInfoRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<JmComicInfoRouteArgs>();
      return _i12.JmComicInfoPage(
        key: args.key,
        comicId: args.comicId,
        type: args.type,
      );
    },
  );
}

class JmComicInfoRouteArgs {
  const JmComicInfoRouteArgs({
    this.key,
    required this.comicId,
    required this.type,
  });

  final _i25.Key? key;

  final String comicId;

  final _i26.ComicEntryType type;

  @override
  String toString() {
    return 'JmComicInfoRouteArgs{key: $key, comicId: $comicId, type: $type}';
  }
}

/// generated route for
/// [_i13.JmSearchResultPage]
class JmSearchResultRoute extends _i24.PageRouteInfo<JmSearchResultRouteArgs> {
  JmSearchResultRoute({
    _i25.Key? key,
    required _i32.JmSearchResultEvent event,
    List<_i24.PageRouteInfo>? children,
  }) : super(
         JmSearchResultRoute.name,
         args: JmSearchResultRouteArgs(key: key, event: event),
         initialChildren: children,
       );

  static const String name = 'JmSearchResultRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<JmSearchResultRouteArgs>();
      return _i13.JmSearchResultPage(key: args.key, event: args.event);
    },
  );
}

class JmSearchResultRouteArgs {
  const JmSearchResultRouteArgs({this.key, required this.event});

  final _i25.Key? key;

  final _i32.JmSearchResultEvent event;

  @override
  String toString() {
    return 'JmSearchResultRouteArgs{key: $key, event: $event}';
  }
}

/// generated route for
/// [_i14.LoginPage]
class LoginRoute extends _i24.PageRouteInfo<void> {
  const LoginRoute({List<_i24.PageRouteInfo>? children})
    : super(LoginRoute.name, initialChildren: children);

  static const String name = 'LoginRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i14.LoginPage();
    },
  );
}

/// generated route for
/// [_i15.NavigationBar]
class NavigationBar extends _i24.PageRouteInfo<void> {
  const NavigationBar({List<_i24.PageRouteInfo>? children})
    : super(NavigationBar.name, initialChildren: children);

  static const String name = 'NavigationBar';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i15.NavigationBar();
    },
  );
}

/// generated route for
/// [_i16.RankingListPage]
class RankingListRoute extends _i24.PageRouteInfo<void> {
  const RankingListRoute({List<_i24.PageRouteInfo>? children})
    : super(RankingListRoute.name, initialChildren: children);

  static const String name = 'RankingListRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i16.RankingListPage();
    },
  );
}

/// generated route for
/// [_i17.RegisterPage]
class RegisterRoute extends _i24.PageRouteInfo<void> {
  const RegisterRoute({List<_i24.PageRouteInfo>? children})
    : super(RegisterRoute.name, initialChildren: children);

  static const String name = 'RegisterRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i17.RegisterPage();
    },
  );
}

/// generated route for
/// [_i18.SearchResultPage]
class SearchResultRoute extends _i24.PageRouteInfo<SearchResultRouteArgs> {
  SearchResultRoute({
    _i25.Key? key,
    required _i33.SearchEnterConst searchEnterConst,
    List<_i24.PageRouteInfo>? children,
  }) : super(
         SearchResultRoute.name,
         args: SearchResultRouteArgs(
           key: key,
           searchEnterConst: searchEnterConst,
         ),
         initialChildren: children,
       );

  static const String name = 'SearchResultRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SearchResultRouteArgs>();
      return _i18.SearchResultPage(
        key: args.key,
        searchEnterConst: args.searchEnterConst,
      );
    },
  );
}

class SearchResultRouteArgs {
  const SearchResultRouteArgs({this.key, required this.searchEnterConst});

  final _i25.Key? key;

  final _i33.SearchEnterConst searchEnterConst;

  @override
  String toString() {
    return 'SearchResultRouteArgs{key: $key, searchEnterConst: $searchEnterConst}';
  }
}

/// generated route for
/// [_i19.ShowColorPage]
class ShowColorRoute extends _i24.PageRouteInfo<void> {
  const ShowColorRoute({List<_i24.PageRouteInfo>? children})
    : super(ShowColorRoute.name, initialChildren: children);

  static const String name = 'ShowColorRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i19.ShowColorPage();
    },
  );
}

/// generated route for
/// [_i20.ThemeColorPage]
class ThemeColorRoute extends _i24.PageRouteInfo<void> {
  const ThemeColorRoute({List<_i24.PageRouteInfo>? children})
    : super(ThemeColorRoute.name, initialChildren: children);

  static const String name = 'ThemeColorRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i20.ThemeColorPage();
    },
  );
}

/// generated route for
/// [_i21.UserCommentsPage]
class UserCommentsRoute extends _i24.PageRouteInfo<void> {
  const UserCommentsRoute({List<_i24.PageRouteInfo>? children})
    : super(UserCommentsRoute.name, initialChildren: children);

  static const String name = 'UserCommentsRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i21.UserCommentsPage();
    },
  );
}

/// generated route for
/// [_i22.WebDavSyncPage]
class WebDavSyncRoute extends _i24.PageRouteInfo<void> {
  const WebDavSyncRoute({List<_i24.PageRouteInfo>? children})
    : super(WebDavSyncRoute.name, initialChildren: children);

  static const String name = 'WebDavSyncRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i22.WebDavSyncPage();
    },
  );
}

/// generated route for
/// [_i23.WebViewPage]
class WebViewRoute extends _i24.PageRouteInfo<WebViewRouteArgs> {
  WebViewRoute({
    _i25.Key? key,
    required List<String> info,
    List<_i24.PageRouteInfo>? children,
  }) : super(
         WebViewRoute.name,
         args: WebViewRouteArgs(key: key, info: info),
         initialChildren: children,
       );

  static const String name = 'WebViewRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<WebViewRouteArgs>();
      return _i23.WebViewPage(key: args.key, info: args.info);
    },
  );
}

class WebViewRouteArgs {
  const WebViewRouteArgs({this.key, required this.info});

  final _i25.Key? key;

  final List<String> info;

  @override
  String toString() {
    return 'WebViewRouteArgs{key: $key, info: $info}';
  }
}
