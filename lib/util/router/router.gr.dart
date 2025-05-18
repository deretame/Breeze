// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i35;

import 'package:auto_route/auto_route.dart' as _i27;
import 'package:flutter/material.dart' as _i28;
import 'package:zephyr/debug/show_color.dart' as _i22;
import 'package:zephyr/mobx/bool_select.dart' as _i31;
import 'package:zephyr/mobx/int_select.dart' as _i32;
import 'package:zephyr/page/about/view/about_page.dart' as _i1;
import 'package:zephyr/page/bookshelf/view/bookshelf_page.dart' as _i3;
import 'package:zephyr/page/category/view/category.dart' as _i4;
import 'package:zephyr/page/comic_info/json/bika/comic_info/comic_info.dart'
    as _i33;
import 'package:zephyr/page/comic_info/json/bika/eps/eps.dart' as _i34;
import 'package:zephyr/page/comic_info/view/comic_info.dart' as _i5;
import 'package:zephyr/page/comic_read/view/comic_read.dart' as _i6;
import 'package:zephyr/page/comments/json/comments_json/comments_json.dart'
    as _i30;
import 'package:zephyr/page/comments/view/comments.dart' as _i8;
import 'package:zephyr/page/comments_children/view/comments_children_page.dart'
    as _i7;
import 'package:zephyr/page/download/view/download.dart' as _i9;
import 'package:zephyr/page/image_crop.dart' as _i12;
import 'package:zephyr/page/jm/jm_comic_info/view/view.dart' as _i13;
import 'package:zephyr/page/jm/jm_comments/view/jm_comments.dart' as _i14;
import 'package:zephyr/page/jm/jm_search_result/jm_search_result.dart' as _i36;
import 'package:zephyr/page/jm/jm_search_result/view/view.dart' as _i16;
import 'package:zephyr/page/login_page.dart' as _i17;
import 'package:zephyr/page/navigation_bar.dart' as _i18;
import 'package:zephyr/page/ranking_list/view/ranking_list_page.dart' as _i19;
import 'package:zephyr/page/register/bika/register_page.dart' as _i20;
import 'package:zephyr/page/register/jm/jm_register_page.dart' as _i15;
import 'package:zephyr/page/search_result/search_result.dart' as _i37;
import 'package:zephyr/page/search_result/view/search_result_page.dart' as _i21;
import 'package:zephyr/page/setting/view/bika_setting.dart' as _i2;
import 'package:zephyr/page/setting/view/global_setting.dart' as _i11;
import 'package:zephyr/page/theme_color/view/theme_color_page.dart' as _i23;
import 'package:zephyr/page/user_comments/view/user_comments_page.dart' as _i24;
import 'package:zephyr/page/webdav_sync/view/webdav_sync_page.dart' as _i25;
import 'package:zephyr/page/webview_page.dart' as _i26;
import 'package:zephyr/type/enum.dart' as _i29;
import 'package:zephyr/widgets/full_screen_image_view.dart' as _i10;

/// generated route for
/// [_i1.AboutPage]
class AboutRoute extends _i27.PageRouteInfo<void> {
  const AboutRoute({List<_i27.PageRouteInfo>? children})
    : super(AboutRoute.name, initialChildren: children);

  static const String name = 'AboutRoute';

  static _i27.PageInfo page = _i27.PageInfo(
    name,
    builder: (data) {
      return const _i1.AboutPage();
    },
  );
}

/// generated route for
/// [_i2.BikaSettingPage]
class BikaSettingRoute extends _i27.PageRouteInfo<void> {
  const BikaSettingRoute({List<_i27.PageRouteInfo>? children})
    : super(BikaSettingRoute.name, initialChildren: children);

  static const String name = 'BikaSettingRoute';

  static _i27.PageInfo page = _i27.PageInfo(
    name,
    builder: (data) {
      return const _i2.BikaSettingPage();
    },
  );
}

/// generated route for
/// [_i3.BookshelfPage]
class BookshelfRoute extends _i27.PageRouteInfo<void> {
  const BookshelfRoute({List<_i27.PageRouteInfo>? children})
    : super(BookshelfRoute.name, initialChildren: children);

  static const String name = 'BookshelfRoute';

  static _i27.PageInfo page = _i27.PageInfo(
    name,
    builder: (data) {
      return const _i3.BookshelfPage();
    },
  );
}

/// generated route for
/// [_i4.CategoryPage]
class CategoryRoute extends _i27.PageRouteInfo<void> {
  const CategoryRoute({List<_i27.PageRouteInfo>? children})
    : super(CategoryRoute.name, initialChildren: children);

  static const String name = 'CategoryRoute';

  static _i27.PageInfo page = _i27.PageInfo(
    name,
    builder: (data) {
      return const _i4.CategoryPage();
    },
  );
}

/// generated route for
/// [_i5.ComicInfoPage]
class ComicInfoRoute extends _i27.PageRouteInfo<ComicInfoRouteArgs> {
  ComicInfoRoute({
    _i28.Key? key,
    required String comicId,
    required _i29.ComicEntryType type,
    List<_i27.PageRouteInfo>? children,
  }) : super(
         ComicInfoRoute.name,
         args: ComicInfoRouteArgs(key: key, comicId: comicId, type: type),
         initialChildren: children,
       );

  static const String name = 'ComicInfoRoute';

  static _i27.PageInfo page = _i27.PageInfo(
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

  final _i28.Key? key;

  final String comicId;

  final _i29.ComicEntryType type;

  @override
  String toString() {
    return 'ComicInfoRouteArgs{key: $key, comicId: $comicId, type: $type}';
  }
}

/// generated route for
/// [_i6.ComicReadPage]
class ComicReadRoute extends _i27.PageRouteInfo<ComicReadRouteArgs> {
  ComicReadRoute({
    _i28.Key? key,
    required String comicId,
    required int order,
    required int epsNumber,
    required _i29.From from,
    required _i29.ComicEntryType type,
    required dynamic comicInfo,
    List<_i27.PageRouteInfo>? children,
  }) : super(
         ComicReadRoute.name,
         args: ComicReadRouteArgs(
           key: key,
           comicId: comicId,
           order: order,
           epsNumber: epsNumber,
           from: from,
           type: type,
           comicInfo: comicInfo,
         ),
         initialChildren: children,
       );

  static const String name = 'ComicReadRoute';

  static _i27.PageInfo page = _i27.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ComicReadRouteArgs>();
      return _i6.ComicReadPage(
        key: args.key,
        comicId: args.comicId,
        order: args.order,
        epsNumber: args.epsNumber,
        from: args.from,
        type: args.type,
        comicInfo: args.comicInfo,
      );
    },
  );
}

class ComicReadRouteArgs {
  const ComicReadRouteArgs({
    this.key,
    required this.comicId,
    required this.order,
    required this.epsNumber,
    required this.from,
    required this.type,
    required this.comicInfo,
  });

  final _i28.Key? key;

  final String comicId;

  final int order;

  final int epsNumber;

  final _i29.From from;

  final _i29.ComicEntryType type;

  final dynamic comicInfo;

  @override
  String toString() {
    return 'ComicReadRouteArgs{key: $key, comicId: $comicId, order: $order, epsNumber: $epsNumber, from: $from, type: $type, comicInfo: $comicInfo}';
  }
}

/// generated route for
/// [_i7.CommentsChildrenPage]
class CommentsChildrenRoute
    extends _i27.PageRouteInfo<CommentsChildrenRouteArgs> {
  CommentsChildrenRoute({
    _i28.Key? key,
    required _i30.Doc fatherDoc,
    required _i31.BoolSelectStore store,
    required _i32.IntSelectStore likeCountStore,
    List<_i27.PageRouteInfo>? children,
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

  static _i27.PageInfo page = _i27.PageInfo(
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

  final _i28.Key? key;

  final _i30.Doc fatherDoc;

  final _i31.BoolSelectStore store;

  final _i32.IntSelectStore likeCountStore;

  @override
  String toString() {
    return 'CommentsChildrenRouteArgs{key: $key, fatherDoc: $fatherDoc, store: $store, likeCountStore: $likeCountStore}';
  }
}

/// generated route for
/// [_i8.CommentsPage]
class CommentsRoute extends _i27.PageRouteInfo<CommentsRouteArgs> {
  CommentsRoute({
    _i28.Key? key,
    required String comicId,
    required String comicTitle,
    List<_i27.PageRouteInfo>? children,
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

  static _i27.PageInfo page = _i27.PageInfo(
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

  final _i28.Key? key;

  final String comicId;

  final String comicTitle;

  @override
  String toString() {
    return 'CommentsRouteArgs{key: $key, comicId: $comicId, comicTitle: $comicTitle}';
  }
}

/// generated route for
/// [_i9.DownloadPage]
class DownloadRoute extends _i27.PageRouteInfo<DownloadRouteArgs> {
  DownloadRoute({
    _i28.Key? key,
    required _i33.Comic comicInfo,
    required List<_i34.Doc> epsInfo,
    List<_i27.PageRouteInfo>? children,
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

  static _i27.PageInfo page = _i27.PageInfo(
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

  final _i28.Key? key;

  final _i33.Comic comicInfo;

  final List<_i34.Doc> epsInfo;

  @override
  String toString() {
    return 'DownloadRouteArgs{key: $key, comicInfo: $comicInfo, epsInfo: $epsInfo}';
  }
}

/// generated route for
/// [_i10.FullScreenImagePage]
class FullRouteImageRoute extends _i27.PageRouteInfo<FullRouteImageRouteArgs> {
  FullRouteImageRoute({
    _i28.Key? key,
    required String imagePath,
    List<_i27.PageRouteInfo>? children,
  }) : super(
         FullRouteImageRoute.name,
         args: FullRouteImageRouteArgs(key: key, imagePath: imagePath),
         initialChildren: children,
       );

  static const String name = 'FullRouteImageRoute';

  static _i27.PageInfo page = _i27.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<FullRouteImageRouteArgs>();
      return _i10.FullScreenImagePage(key: args.key, imagePath: args.imagePath);
    },
  );
}

class FullRouteImageRouteArgs {
  const FullRouteImageRouteArgs({this.key, required this.imagePath});

  final _i28.Key? key;

  final String imagePath;

  @override
  String toString() {
    return 'FullRouteImageRouteArgs{key: $key, imagePath: $imagePath}';
  }
}

/// generated route for
/// [_i11.GlobalSettingPage]
class GlobalSettingRoute extends _i27.PageRouteInfo<void> {
  const GlobalSettingRoute({List<_i27.PageRouteInfo>? children})
    : super(GlobalSettingRoute.name, initialChildren: children);

  static const String name = 'GlobalSettingRoute';

  static _i27.PageInfo page = _i27.PageInfo(
    name,
    builder: (data) {
      return const _i11.GlobalSettingPage();
    },
  );
}

/// generated route for
/// [_i12.ImageCropPage]
class ImageCropRoute extends _i27.PageRouteInfo<ImageCropRouteArgs> {
  ImageCropRoute({
    _i28.Key? key,
    required _i35.Uint8List imageData,
    List<_i27.PageRouteInfo>? children,
  }) : super(
         ImageCropRoute.name,
         args: ImageCropRouteArgs(key: key, imageData: imageData),
         initialChildren: children,
       );

  static const String name = 'ImageCropRoute';

  static _i27.PageInfo page = _i27.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ImageCropRouteArgs>();
      return _i12.ImageCropPage(key: args.key, imageData: args.imageData);
    },
  );
}

class ImageCropRouteArgs {
  const ImageCropRouteArgs({this.key, required this.imageData});

  final _i28.Key? key;

  final _i35.Uint8List imageData;

  @override
  String toString() {
    return 'ImageCropRouteArgs{key: $key, imageData: $imageData}';
  }
}

/// generated route for
/// [_i13.JmComicInfoPage]
class JmComicInfoRoute extends _i27.PageRouteInfo<JmComicInfoRouteArgs> {
  JmComicInfoRoute({
    _i28.Key? key,
    required String comicId,
    required _i29.ComicEntryType type,
    List<_i27.PageRouteInfo>? children,
  }) : super(
         JmComicInfoRoute.name,
         args: JmComicInfoRouteArgs(key: key, comicId: comicId, type: type),
         initialChildren: children,
       );

  static const String name = 'JmComicInfoRoute';

  static _i27.PageInfo page = _i27.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<JmComicInfoRouteArgs>();
      return _i13.JmComicInfoPage(
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

  final _i28.Key? key;

  final String comicId;

  final _i29.ComicEntryType type;

  @override
  String toString() {
    return 'JmComicInfoRouteArgs{key: $key, comicId: $comicId, type: $type}';
  }
}

/// generated route for
/// [_i14.JmCommentsPage]
class JmCommentsRoute extends _i27.PageRouteInfo<JmCommentsRouteArgs> {
  JmCommentsRoute({
    _i28.Key? key,
    required String comicId,
    required String comicTitle,
    List<_i27.PageRouteInfo>? children,
  }) : super(
         JmCommentsRoute.name,
         args: JmCommentsRouteArgs(
           key: key,
           comicId: comicId,
           comicTitle: comicTitle,
         ),
         initialChildren: children,
       );

  static const String name = 'JmCommentsRoute';

  static _i27.PageInfo page = _i27.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<JmCommentsRouteArgs>();
      return _i14.JmCommentsPage(
        key: args.key,
        comicId: args.comicId,
        comicTitle: args.comicTitle,
      );
    },
  );
}

class JmCommentsRouteArgs {
  const JmCommentsRouteArgs({
    this.key,
    required this.comicId,
    required this.comicTitle,
  });

  final _i28.Key? key;

  final String comicId;

  final String comicTitle;

  @override
  String toString() {
    return 'JmCommentsRouteArgs{key: $key, comicId: $comicId, comicTitle: $comicTitle}';
  }
}

/// generated route for
/// [_i15.JmRegisterPage]
class JmRegisterRoute extends _i27.PageRouteInfo<void> {
  const JmRegisterRoute({List<_i27.PageRouteInfo>? children})
    : super(JmRegisterRoute.name, initialChildren: children);

  static const String name = 'JmRegisterRoute';

  static _i27.PageInfo page = _i27.PageInfo(
    name,
    builder: (data) {
      return const _i15.JmRegisterPage();
    },
  );
}

/// generated route for
/// [_i16.JmSearchResultPage]
class JmSearchResultRoute extends _i27.PageRouteInfo<JmSearchResultRouteArgs> {
  JmSearchResultRoute({
    _i28.Key? key,
    required _i36.JmSearchResultEvent event,
    List<_i27.PageRouteInfo>? children,
  }) : super(
         JmSearchResultRoute.name,
         args: JmSearchResultRouteArgs(key: key, event: event),
         initialChildren: children,
       );

  static const String name = 'JmSearchResultRoute';

  static _i27.PageInfo page = _i27.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<JmSearchResultRouteArgs>();
      return _i16.JmSearchResultPage(key: args.key, event: args.event);
    },
  );
}

class JmSearchResultRouteArgs {
  const JmSearchResultRouteArgs({this.key, required this.event});

  final _i28.Key? key;

  final _i36.JmSearchResultEvent event;

  @override
  String toString() {
    return 'JmSearchResultRouteArgs{key: $key, event: $event}';
  }
}

/// generated route for
/// [_i17.LoginPage]
class LoginRoute extends _i27.PageRouteInfo<LoginRouteArgs> {
  LoginRoute({
    _i28.Key? key,
    _i29.From? from,
    List<_i27.PageRouteInfo>? children,
  }) : super(
         LoginRoute.name,
         args: LoginRouteArgs(key: key, from: from),
         initialChildren: children,
       );

  static const String name = 'LoginRoute';

  static _i27.PageInfo page = _i27.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<LoginRouteArgs>(
        orElse: () => const LoginRouteArgs(),
      );
      return _i17.LoginPage(key: args.key, from: args.from);
    },
  );
}

class LoginRouteArgs {
  const LoginRouteArgs({this.key, this.from});

  final _i28.Key? key;

  final _i29.From? from;

  @override
  String toString() {
    return 'LoginRouteArgs{key: $key, from: $from}';
  }
}

/// generated route for
/// [_i18.NavigationBar]
class NavigationBar extends _i27.PageRouteInfo<void> {
  const NavigationBar({List<_i27.PageRouteInfo>? children})
    : super(NavigationBar.name, initialChildren: children);

  static const String name = 'NavigationBar';

  static _i27.PageInfo page = _i27.PageInfo(
    name,
    builder: (data) {
      return const _i18.NavigationBar();
    },
  );
}

/// generated route for
/// [_i19.RankingListPage]
class RankingListRoute extends _i27.PageRouteInfo<void> {
  const RankingListRoute({List<_i27.PageRouteInfo>? children})
    : super(RankingListRoute.name, initialChildren: children);

  static const String name = 'RankingListRoute';

  static _i27.PageInfo page = _i27.PageInfo(
    name,
    builder: (data) {
      return const _i19.RankingListPage();
    },
  );
}

/// generated route for
/// [_i20.RegisterPage]
class RegisterRoute extends _i27.PageRouteInfo<void> {
  const RegisterRoute({List<_i27.PageRouteInfo>? children})
    : super(RegisterRoute.name, initialChildren: children);

  static const String name = 'RegisterRoute';

  static _i27.PageInfo page = _i27.PageInfo(
    name,
    builder: (data) {
      return const _i20.RegisterPage();
    },
  );
}

/// generated route for
/// [_i21.SearchResultPage]
class SearchResultRoute extends _i27.PageRouteInfo<SearchResultRouteArgs> {
  SearchResultRoute({
    _i28.Key? key,
    required _i37.SearchEnter searchEnter,
    List<_i27.PageRouteInfo>? children,
  }) : super(
         SearchResultRoute.name,
         args: SearchResultRouteArgs(key: key, searchEnter: searchEnter),
         initialChildren: children,
       );

  static const String name = 'SearchResultRoute';

  static _i27.PageInfo page = _i27.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SearchResultRouteArgs>();
      return _i21.SearchResultPage(
        key: args.key,
        searchEnter: args.searchEnter,
      );
    },
  );
}

class SearchResultRouteArgs {
  const SearchResultRouteArgs({this.key, required this.searchEnter});

  final _i28.Key? key;

  final _i37.SearchEnter searchEnter;

  @override
  String toString() {
    return 'SearchResultRouteArgs{key: $key, searchEnter: $searchEnter}';
  }
}

/// generated route for
/// [_i22.ShowColorPage]
class ShowColorRoute extends _i27.PageRouteInfo<void> {
  const ShowColorRoute({List<_i27.PageRouteInfo>? children})
    : super(ShowColorRoute.name, initialChildren: children);

  static const String name = 'ShowColorRoute';

  static _i27.PageInfo page = _i27.PageInfo(
    name,
    builder: (data) {
      return const _i22.ShowColorPage();
    },
  );
}

/// generated route for
/// [_i23.ThemeColorPage]
class ThemeColorRoute extends _i27.PageRouteInfo<void> {
  const ThemeColorRoute({List<_i27.PageRouteInfo>? children})
    : super(ThemeColorRoute.name, initialChildren: children);

  static const String name = 'ThemeColorRoute';

  static _i27.PageInfo page = _i27.PageInfo(
    name,
    builder: (data) {
      return const _i23.ThemeColorPage();
    },
  );
}

/// generated route for
/// [_i24.UserCommentsPage]
class UserCommentsRoute extends _i27.PageRouteInfo<void> {
  const UserCommentsRoute({List<_i27.PageRouteInfo>? children})
    : super(UserCommentsRoute.name, initialChildren: children);

  static const String name = 'UserCommentsRoute';

  static _i27.PageInfo page = _i27.PageInfo(
    name,
    builder: (data) {
      return const _i24.UserCommentsPage();
    },
  );
}

/// generated route for
/// [_i25.WebDavSyncPage]
class WebDavSyncRoute extends _i27.PageRouteInfo<void> {
  const WebDavSyncRoute({List<_i27.PageRouteInfo>? children})
    : super(WebDavSyncRoute.name, initialChildren: children);

  static const String name = 'WebDavSyncRoute';

  static _i27.PageInfo page = _i27.PageInfo(
    name,
    builder: (data) {
      return const _i25.WebDavSyncPage();
    },
  );
}

/// generated route for
/// [_i26.WebViewPage]
class WebViewRoute extends _i27.PageRouteInfo<WebViewRouteArgs> {
  WebViewRoute({
    _i28.Key? key,
    required List<String> info,
    List<_i27.PageRouteInfo>? children,
  }) : super(
         WebViewRoute.name,
         args: WebViewRouteArgs(key: key, info: info),
         initialChildren: children,
       );

  static const String name = 'WebViewRoute';

  static _i27.PageInfo page = _i27.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<WebViewRouteArgs>();
      return _i26.WebViewPage(key: args.key, info: args.info);
    },
  );
}

class WebViewRouteArgs {
  const WebViewRouteArgs({this.key, required this.info});

  final _i28.Key? key;

  final List<String> info;

  @override
  String toString() {
    return 'WebViewRouteArgs{key: $key, info: $info}';
  }
}
