// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i40;

import 'package:auto_route/auto_route.dart' as _i30;
import 'package:collection/collection.dart' as _i39;
import 'package:flutter/material.dart' as _i31;
import 'package:zephyr/debug/show_color.dart' as _i25;
import 'package:zephyr/mobx/bool_select.dart' as _i35;
import 'package:zephyr/mobx/int_select.dart' as _i36;
import 'package:zephyr/mobx/string_select.dart' as _i33;
import 'package:zephyr/page/about/view/about_page.dart' as _i1;
import 'package:zephyr/page/bookshelf/view/bookshelf_page.dart' as _i3;
import 'package:zephyr/page/comic_info/json/bika/comic_info/comic_info.dart'
    as _i37;
import 'package:zephyr/page/comic_info/json/bika/eps/eps.dart' as _i38;
import 'package:zephyr/page/comic_info/view/comic_info.dart' as _i4;
import 'package:zephyr/page/comic_read/view/comic_read.dart' as _i5;
import 'package:zephyr/page/comments/json/comments_json/comments_json.dart'
    as _i34;
import 'package:zephyr/page/comments/view/comments.dart' as _i7;
import 'package:zephyr/page/comments_children/view/comments_children_page.dart'
    as _i6;
import 'package:zephyr/page/download/view/download.dart' as _i8;
import 'package:zephyr/page/home/view/home.dart' as _i11;
import 'package:zephyr/page/image_crop.dart' as _i12;
import 'package:zephyr/page/jm/jm_comic_info/json/jm_comic_info_json.dart'
    as _i41;
import 'package:zephyr/page/jm/jm_comic_info/view/view.dart' as _i14;
import 'package:zephyr/page/jm/jm_comments/view/jm_comments.dart' as _i15;
import 'package:zephyr/page/jm/jm_download/view/view.dart' as _i16;
import 'package:zephyr/page/jm/jm_promote/view/jm_promote.dart' as _i17;
import 'package:zephyr/page/jm/jm_search_result/jm_search_result.dart' as _i42;
import 'package:zephyr/page/jm/jm_search_result/view/view.dart' as _i19;
import 'package:zephyr/page/login_page.dart' as _i20;
import 'package:zephyr/page/navigation_bar.dart' as _i21;
import 'package:zephyr/page/ranking_list/view/ranking_list_page.dart' as _i22;
import 'package:zephyr/page/register/bika/register_page.dart' as _i23;
import 'package:zephyr/page/register/jm/jm_register_page.dart' as _i18;
import 'package:zephyr/page/search_result/search_result.dart' as _i43;
import 'package:zephyr/page/search_result/view/search_result_page.dart' as _i24;
import 'package:zephyr/page/setting/bika/bika_setting.dart' as _i2;
import 'package:zephyr/page/setting/global/global_setting.dart' as _i10;
import 'package:zephyr/page/setting/jm/jm_setting.dart' as _i13;
import 'package:zephyr/page/theme_color/view/theme_color_page.dart' as _i26;
import 'package:zephyr/page/user_comments/view/user_comments_page.dart' as _i27;
import 'package:zephyr/page/webdav_sync/view/webdav_sync_page.dart' as _i28;
import 'package:zephyr/page/webview_page.dart' as _i29;
import 'package:zephyr/type/enum.dart' as _i32;
import 'package:zephyr/widgets/full_screen_image_view.dart' as _i9;

/// generated route for
/// [_i1.AboutPage]
class AboutRoute extends _i30.PageRouteInfo<void> {
  const AboutRoute({List<_i30.PageRouteInfo>? children})
    : super(AboutRoute.name, initialChildren: children);

  static const String name = 'AboutRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i1.AboutPage();
    },
  );
}

/// generated route for
/// [_i2.BikaSettingPage]
class BikaSettingRoute extends _i30.PageRouteInfo<void> {
  const BikaSettingRoute({List<_i30.PageRouteInfo>? children})
    : super(BikaSettingRoute.name, initialChildren: children);

  static const String name = 'BikaSettingRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i2.BikaSettingPage();
    },
  );
}

/// generated route for
/// [_i3.BookshelfPage]
class BookshelfRoute extends _i30.PageRouteInfo<void> {
  const BookshelfRoute({List<_i30.PageRouteInfo>? children})
    : super(BookshelfRoute.name, initialChildren: children);

  static const String name = 'BookshelfRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i3.BookshelfPage();
    },
  );
}

/// generated route for
/// [_i4.ComicInfoPage]
class ComicInfoRoute extends _i30.PageRouteInfo<ComicInfoRouteArgs> {
  ComicInfoRoute({
    _i31.Key? key,
    required String comicId,
    required _i32.ComicEntryType type,
    List<_i30.PageRouteInfo>? children,
  }) : super(
         ComicInfoRoute.name,
         args: ComicInfoRouteArgs(key: key, comicId: comicId, type: type),
         initialChildren: children,
       );

  static const String name = 'ComicInfoRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ComicInfoRouteArgs>();
      return _i4.ComicInfoPage(
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

  final _i31.Key? key;

  final String comicId;

  final _i32.ComicEntryType type;

  @override
  String toString() {
    return 'ComicInfoRouteArgs{key: $key, comicId: $comicId, type: $type}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ComicInfoRouteArgs) return false;
    return key == other.key && comicId == other.comicId && type == other.type;
  }

  @override
  int get hashCode => key.hashCode ^ comicId.hashCode ^ type.hashCode;
}

/// generated route for
/// [_i5.ComicReadPage]
class ComicReadRoute extends _i30.PageRouteInfo<ComicReadRouteArgs> {
  ComicReadRoute({
    _i31.Key? key,
    required String comicId,
    required int order,
    required int epsNumber,
    required _i32.From from,
    required _i32.ComicEntryType type,
    required dynamic comicInfo,
    required _i33.StringSelectStore store,
    List<_i30.PageRouteInfo>? children,
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
           store: store,
         ),
         initialChildren: children,
       );

  static const String name = 'ComicReadRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ComicReadRouteArgs>();
      return _i5.ComicReadPage(
        key: args.key,
        comicId: args.comicId,
        order: args.order,
        epsNumber: args.epsNumber,
        from: args.from,
        type: args.type,
        comicInfo: args.comicInfo,
        store: args.store,
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
    required this.store,
  });

  final _i31.Key? key;

  final String comicId;

  final int order;

  final int epsNumber;

  final _i32.From from;

  final _i32.ComicEntryType type;

  final dynamic comicInfo;

  final _i33.StringSelectStore store;

  @override
  String toString() {
    return 'ComicReadRouteArgs{key: $key, comicId: $comicId, order: $order, epsNumber: $epsNumber, from: $from, type: $type, comicInfo: $comicInfo, store: $store}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ComicReadRouteArgs) return false;
    return key == other.key &&
        comicId == other.comicId &&
        order == other.order &&
        epsNumber == other.epsNumber &&
        from == other.from &&
        type == other.type &&
        comicInfo == other.comicInfo &&
        store == other.store;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      comicId.hashCode ^
      order.hashCode ^
      epsNumber.hashCode ^
      from.hashCode ^
      type.hashCode ^
      comicInfo.hashCode ^
      store.hashCode;
}

/// generated route for
/// [_i6.CommentsChildrenPage]
class CommentsChildrenRoute
    extends _i30.PageRouteInfo<CommentsChildrenRouteArgs> {
  CommentsChildrenRoute({
    _i31.Key? key,
    required _i34.Doc fatherDoc,
    required _i35.BoolSelectStore store,
    required _i36.IntSelectStore likeCountStore,
    List<_i30.PageRouteInfo>? children,
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

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<CommentsChildrenRouteArgs>();
      return _i6.CommentsChildrenPage(
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

  final _i31.Key? key;

  final _i34.Doc fatherDoc;

  final _i35.BoolSelectStore store;

  final _i36.IntSelectStore likeCountStore;

  @override
  String toString() {
    return 'CommentsChildrenRouteArgs{key: $key, fatherDoc: $fatherDoc, store: $store, likeCountStore: $likeCountStore}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CommentsChildrenRouteArgs) return false;
    return key == other.key &&
        fatherDoc == other.fatherDoc &&
        store == other.store &&
        likeCountStore == other.likeCountStore;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      fatherDoc.hashCode ^
      store.hashCode ^
      likeCountStore.hashCode;
}

/// generated route for
/// [_i7.CommentsPage]
class CommentsRoute extends _i30.PageRouteInfo<CommentsRouteArgs> {
  CommentsRoute({
    _i31.Key? key,
    required String comicId,
    required String comicTitle,
    List<_i30.PageRouteInfo>? children,
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

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<CommentsRouteArgs>();
      return _i7.CommentsPage(
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

  final _i31.Key? key;

  final String comicId;

  final String comicTitle;

  @override
  String toString() {
    return 'CommentsRouteArgs{key: $key, comicId: $comicId, comicTitle: $comicTitle}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CommentsRouteArgs) return false;
    return key == other.key &&
        comicId == other.comicId &&
        comicTitle == other.comicTitle;
  }

  @override
  int get hashCode => key.hashCode ^ comicId.hashCode ^ comicTitle.hashCode;
}

/// generated route for
/// [_i8.DownloadPage]
class DownloadRoute extends _i30.PageRouteInfo<DownloadRouteArgs> {
  DownloadRoute({
    _i31.Key? key,
    required _i37.Comic comicInfo,
    required List<_i38.Doc> epsInfo,
    List<_i30.PageRouteInfo>? children,
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

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<DownloadRouteArgs>();
      return _i8.DownloadPage(
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

  final _i31.Key? key;

  final _i37.Comic comicInfo;

  final List<_i38.Doc> epsInfo;

  @override
  String toString() {
    return 'DownloadRouteArgs{key: $key, comicInfo: $comicInfo, epsInfo: $epsInfo}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DownloadRouteArgs) return false;
    return key == other.key &&
        comicInfo == other.comicInfo &&
        const _i39.ListEquality().equals(epsInfo, other.epsInfo);
  }

  @override
  int get hashCode =>
      key.hashCode ^
      comicInfo.hashCode ^
      const _i39.ListEquality().hash(epsInfo);
}

/// generated route for
/// [_i9.FullScreenImagePage]
class FullRouteImageRoute extends _i30.PageRouteInfo<FullRouteImageRouteArgs> {
  FullRouteImageRoute({
    _i31.Key? key,
    required String imagePath,
    List<_i30.PageRouteInfo>? children,
  }) : super(
         FullRouteImageRoute.name,
         args: FullRouteImageRouteArgs(key: key, imagePath: imagePath),
         initialChildren: children,
       );

  static const String name = 'FullRouteImageRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<FullRouteImageRouteArgs>();
      return _i9.FullScreenImagePage(key: args.key, imagePath: args.imagePath);
    },
  );
}

class FullRouteImageRouteArgs {
  const FullRouteImageRouteArgs({this.key, required this.imagePath});

  final _i31.Key? key;

  final String imagePath;

  @override
  String toString() {
    return 'FullRouteImageRouteArgs{key: $key, imagePath: $imagePath}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FullRouteImageRouteArgs) return false;
    return key == other.key && imagePath == other.imagePath;
  }

  @override
  int get hashCode => key.hashCode ^ imagePath.hashCode;
}

/// generated route for
/// [_i10.GlobalSettingPage]
class GlobalSettingRoute extends _i30.PageRouteInfo<void> {
  const GlobalSettingRoute({List<_i30.PageRouteInfo>? children})
    : super(GlobalSettingRoute.name, initialChildren: children);

  static const String name = 'GlobalSettingRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i10.GlobalSettingPage();
    },
  );
}

/// generated route for
/// [_i11.HomePage]
class HomeRoute extends _i30.PageRouteInfo<void> {
  const HomeRoute({List<_i30.PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i11.HomePage();
    },
  );
}

/// generated route for
/// [_i12.ImageCropPage]
class ImageCropRoute extends _i30.PageRouteInfo<ImageCropRouteArgs> {
  ImageCropRoute({
    _i31.Key? key,
    required _i40.Uint8List imageData,
    List<_i30.PageRouteInfo>? children,
  }) : super(
         ImageCropRoute.name,
         args: ImageCropRouteArgs(key: key, imageData: imageData),
         initialChildren: children,
       );

  static const String name = 'ImageCropRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ImageCropRouteArgs>();
      return _i12.ImageCropPage(key: args.key, imageData: args.imageData);
    },
  );
}

class ImageCropRouteArgs {
  const ImageCropRouteArgs({this.key, required this.imageData});

  final _i31.Key? key;

  final _i40.Uint8List imageData;

  @override
  String toString() {
    return 'ImageCropRouteArgs{key: $key, imageData: $imageData}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ImageCropRouteArgs) return false;
    return key == other.key && imageData == other.imageData;
  }

  @override
  int get hashCode => key.hashCode ^ imageData.hashCode;
}

/// generated route for
/// [_i13.JMSettingPage]
class JMSettingRoute extends _i30.PageRouteInfo<void> {
  const JMSettingRoute({List<_i30.PageRouteInfo>? children})
    : super(JMSettingRoute.name, initialChildren: children);

  static const String name = 'JMSettingRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i13.JMSettingPage();
    },
  );
}

/// generated route for
/// [_i14.JmComicInfoPage]
class JmComicInfoRoute extends _i30.PageRouteInfo<JmComicInfoRouteArgs> {
  JmComicInfoRoute({
    _i31.Key? key,
    required String comicId,
    required _i32.ComicEntryType type,
    List<_i30.PageRouteInfo>? children,
  }) : super(
         JmComicInfoRoute.name,
         args: JmComicInfoRouteArgs(key: key, comicId: comicId, type: type),
         initialChildren: children,
       );

  static const String name = 'JmComicInfoRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<JmComicInfoRouteArgs>();
      return _i14.JmComicInfoPage(
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

  final _i31.Key? key;

  final String comicId;

  final _i32.ComicEntryType type;

  @override
  String toString() {
    return 'JmComicInfoRouteArgs{key: $key, comicId: $comicId, type: $type}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! JmComicInfoRouteArgs) return false;
    return key == other.key && comicId == other.comicId && type == other.type;
  }

  @override
  int get hashCode => key.hashCode ^ comicId.hashCode ^ type.hashCode;
}

/// generated route for
/// [_i15.JmCommentsPage]
class JmCommentsRoute extends _i30.PageRouteInfo<JmCommentsRouteArgs> {
  JmCommentsRoute({
    _i31.Key? key,
    required String comicId,
    required String comicTitle,
    List<_i30.PageRouteInfo>? children,
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

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<JmCommentsRouteArgs>();
      return _i15.JmCommentsPage(
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

  final _i31.Key? key;

  final String comicId;

  final String comicTitle;

  @override
  String toString() {
    return 'JmCommentsRouteArgs{key: $key, comicId: $comicId, comicTitle: $comicTitle}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! JmCommentsRouteArgs) return false;
    return key == other.key &&
        comicId == other.comicId &&
        comicTitle == other.comicTitle;
  }

  @override
  int get hashCode => key.hashCode ^ comicId.hashCode ^ comicTitle.hashCode;
}

/// generated route for
/// [_i16.JmDownloadPage]
class JmDownloadRoute extends _i30.PageRouteInfo<JmDownloadRouteArgs> {
  JmDownloadRoute({
    _i31.Key? key,
    required _i41.JmComicInfoJson jmComicInfoJson,
    List<_i30.PageRouteInfo>? children,
  }) : super(
         JmDownloadRoute.name,
         args: JmDownloadRouteArgs(key: key, jmComicInfoJson: jmComicInfoJson),
         initialChildren: children,
       );

  static const String name = 'JmDownloadRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<JmDownloadRouteArgs>();
      return _i16.JmDownloadPage(
        key: args.key,
        jmComicInfoJson: args.jmComicInfoJson,
      );
    },
  );
}

class JmDownloadRouteArgs {
  const JmDownloadRouteArgs({this.key, required this.jmComicInfoJson});

  final _i31.Key? key;

  final _i41.JmComicInfoJson jmComicInfoJson;

  @override
  String toString() {
    return 'JmDownloadRouteArgs{key: $key, jmComicInfoJson: $jmComicInfoJson}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! JmDownloadRouteArgs) return false;
    return key == other.key && jmComicInfoJson == other.jmComicInfoJson;
  }

  @override
  int get hashCode => key.hashCode ^ jmComicInfoJson.hashCode;
}

/// generated route for
/// [_i17.JmPromotePage]
class JmPromoteRoute extends _i30.PageRouteInfo<void> {
  const JmPromoteRoute({List<_i30.PageRouteInfo>? children})
    : super(JmPromoteRoute.name, initialChildren: children);

  static const String name = 'JmPromoteRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i17.JmPromotePage();
    },
  );
}

/// generated route for
/// [_i18.JmRegisterPage]
class JmRegisterRoute extends _i30.PageRouteInfo<void> {
  const JmRegisterRoute({List<_i30.PageRouteInfo>? children})
    : super(JmRegisterRoute.name, initialChildren: children);

  static const String name = 'JmRegisterRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i18.JmRegisterPage();
    },
  );
}

/// generated route for
/// [_i19.JmSearchResultPage]
class JmSearchResultRoute extends _i30.PageRouteInfo<JmSearchResultRouteArgs> {
  JmSearchResultRoute({
    _i31.Key? key,
    required _i42.JmSearchResultEvent event,
    List<_i30.PageRouteInfo>? children,
  }) : super(
         JmSearchResultRoute.name,
         args: JmSearchResultRouteArgs(key: key, event: event),
         initialChildren: children,
       );

  static const String name = 'JmSearchResultRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<JmSearchResultRouteArgs>();
      return _i19.JmSearchResultPage(key: args.key, event: args.event);
    },
  );
}

class JmSearchResultRouteArgs {
  const JmSearchResultRouteArgs({this.key, required this.event});

  final _i31.Key? key;

  final _i42.JmSearchResultEvent event;

  @override
  String toString() {
    return 'JmSearchResultRouteArgs{key: $key, event: $event}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! JmSearchResultRouteArgs) return false;
    return key == other.key && event == other.event;
  }

  @override
  int get hashCode => key.hashCode ^ event.hashCode;
}

/// generated route for
/// [_i20.LoginPage]
class LoginRoute extends _i30.PageRouteInfo<LoginRouteArgs> {
  LoginRoute({
    _i31.Key? key,
    _i32.From? from,
    List<_i30.PageRouteInfo>? children,
  }) : super(
         LoginRoute.name,
         args: LoginRouteArgs(key: key, from: from),
         initialChildren: children,
       );

  static const String name = 'LoginRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<LoginRouteArgs>(
        orElse: () => const LoginRouteArgs(),
      );
      return _i20.LoginPage(key: args.key, from: args.from);
    },
  );
}

class LoginRouteArgs {
  const LoginRouteArgs({this.key, this.from});

  final _i31.Key? key;

  final _i32.From? from;

  @override
  String toString() {
    return 'LoginRouteArgs{key: $key, from: $from}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LoginRouteArgs) return false;
    return key == other.key && from == other.from;
  }

  @override
  int get hashCode => key.hashCode ^ from.hashCode;
}

/// generated route for
/// [_i21.NavigationBar]
class NavigationBar extends _i30.PageRouteInfo<void> {
  const NavigationBar({List<_i30.PageRouteInfo>? children})
    : super(NavigationBar.name, initialChildren: children);

  static const String name = 'NavigationBar';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i21.NavigationBar();
    },
  );
}

/// generated route for
/// [_i22.RankingListPage]
class RankingListRoute extends _i30.PageRouteInfo<void> {
  const RankingListRoute({List<_i30.PageRouteInfo>? children})
    : super(RankingListRoute.name, initialChildren: children);

  static const String name = 'RankingListRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i22.RankingListPage();
    },
  );
}

/// generated route for
/// [_i23.RegisterPage]
class RegisterRoute extends _i30.PageRouteInfo<void> {
  const RegisterRoute({List<_i30.PageRouteInfo>? children})
    : super(RegisterRoute.name, initialChildren: children);

  static const String name = 'RegisterRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i23.RegisterPage();
    },
  );
}

/// generated route for
/// [_i24.SearchResultPage]
class SearchResultRoute extends _i30.PageRouteInfo<SearchResultRouteArgs> {
  SearchResultRoute({
    _i31.Key? key,
    required _i43.SearchEnter searchEnter,
    List<_i30.PageRouteInfo>? children,
  }) : super(
         SearchResultRoute.name,
         args: SearchResultRouteArgs(key: key, searchEnter: searchEnter),
         initialChildren: children,
       );

  static const String name = 'SearchResultRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SearchResultRouteArgs>();
      return _i24.SearchResultPage(
        key: args.key,
        searchEnter: args.searchEnter,
      );
    },
  );
}

class SearchResultRouteArgs {
  const SearchResultRouteArgs({this.key, required this.searchEnter});

  final _i31.Key? key;

  final _i43.SearchEnter searchEnter;

  @override
  String toString() {
    return 'SearchResultRouteArgs{key: $key, searchEnter: $searchEnter}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SearchResultRouteArgs) return false;
    return key == other.key && searchEnter == other.searchEnter;
  }

  @override
  int get hashCode => key.hashCode ^ searchEnter.hashCode;
}

/// generated route for
/// [_i25.ShowColorPage]
class ShowColorRoute extends _i30.PageRouteInfo<void> {
  const ShowColorRoute({List<_i30.PageRouteInfo>? children})
    : super(ShowColorRoute.name, initialChildren: children);

  static const String name = 'ShowColorRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i25.ShowColorPage();
    },
  );
}

/// generated route for
/// [_i26.ThemeColorPage]
class ThemeColorRoute extends _i30.PageRouteInfo<void> {
  const ThemeColorRoute({List<_i30.PageRouteInfo>? children})
    : super(ThemeColorRoute.name, initialChildren: children);

  static const String name = 'ThemeColorRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i26.ThemeColorPage();
    },
  );
}

/// generated route for
/// [_i27.UserCommentsPage]
class UserCommentsRoute extends _i30.PageRouteInfo<void> {
  const UserCommentsRoute({List<_i30.PageRouteInfo>? children})
    : super(UserCommentsRoute.name, initialChildren: children);

  static const String name = 'UserCommentsRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i27.UserCommentsPage();
    },
  );
}

/// generated route for
/// [_i28.WebDavSyncPage]
class WebDavSyncRoute extends _i30.PageRouteInfo<void> {
  const WebDavSyncRoute({List<_i30.PageRouteInfo>? children})
    : super(WebDavSyncRoute.name, initialChildren: children);

  static const String name = 'WebDavSyncRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i28.WebDavSyncPage();
    },
  );
}

/// generated route for
/// [_i29.WebViewPage]
class WebViewRoute extends _i30.PageRouteInfo<WebViewRouteArgs> {
  WebViewRoute({
    _i31.Key? key,
    required List<String> info,
    List<_i30.PageRouteInfo>? children,
  }) : super(
         WebViewRoute.name,
         args: WebViewRouteArgs(key: key, info: info),
         initialChildren: children,
       );

  static const String name = 'WebViewRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<WebViewRouteArgs>();
      return _i29.WebViewPage(key: args.key, info: args.info);
    },
  );
}

class WebViewRouteArgs {
  const WebViewRouteArgs({this.key, required this.info});

  final _i31.Key? key;

  final List<String> info;

  @override
  String toString() {
    return 'WebViewRouteArgs{key: $key, info: $info}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WebViewRouteArgs) return false;
    return key == other.key &&
        const _i39.ListEquality().equals(info, other.info);
  }

  @override
  int get hashCode => key.hashCode ^ const _i39.ListEquality().hash(info);
}
