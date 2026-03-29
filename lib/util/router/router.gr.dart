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
import 'package:collection/collection.dart' as _i43;
import 'package:flutter/foundation.dart' as _i34;
import 'package:flutter/material.dart' as _i31;
import 'package:zephyr/cubit/bool_select.dart' as _i37;
import 'package:zephyr/cubit/int_select.dart' as _i38;
import 'package:zephyr/cubit/string_select.dart' as _i35;
import 'package:zephyr/debug/show_color.dart' as _i25;
import 'package:zephyr/page/about/view/about_page.dart' as _i1;
import 'package:zephyr/page/bookshelf/view/bookshelf_page.dart' as _i3;
import 'package:zephyr/page/change_log_page.dart' as _i4;
import 'package:zephyr/page/comic_info/view/comic_info.dart' as _i5;
import 'package:zephyr/page/comic_list/models/comic_list_scene.dart' as _i33;
import 'package:zephyr/page/comic_list/view/comic_list_page.dart' as _i6;
import 'package:zephyr/page/comic_read/view/comic_read.dart' as _i7;
import 'package:zephyr/page/comments/json/comments_json/comments_json.dart'
    as _i36;
import 'package:zephyr/page/comments/view/comments.dart' as _i9;
import 'package:zephyr/page/comments_children/view/comments_children_page.dart'
    as _i8;
import 'package:zephyr/page/donwload_task/view/download_task.dart' as _i11;
import 'package:zephyr/page/download/models/unified_comic_download.dart'
    as _i39;
import 'package:zephyr/page/download/view/download.dart' as _i10;
import 'package:zephyr/page/home/view/home.dart' as _i14;
import 'package:zephyr/page/image_crop.dart' as _i15;
import 'package:zephyr/page/jm/jm_comments/view/jm_comments.dart' as _i17;
import 'package:zephyr/page/login_page.dart' as _i19;
import 'package:zephyr/page/navigation_bar.dart' as _i20;
import 'package:zephyr/page/register/bika/register_page.dart' as _i21;
import 'package:zephyr/page/register/jm/jm_register_page.dart' as _i18;
import 'package:zephyr/page/search/cubit/search_cubit.dart' as _i42;
import 'package:zephyr/page/search/view/search_page.dart' as _i23;
import 'package:zephyr/page/search_aggregate/view/search_aggregate_result_page.dart'
    as _i22;
import 'package:zephyr/page/search_result/bloc/search_bloc.dart' as _i41;
import 'package:zephyr/page/search_result/search_result.dart' as _i44;
import 'package:zephyr/page/search_result/view/search_result_page.dart' as _i24;
import 'package:zephyr/page/setting/bika/bika_setting.dart' as _i2;
import 'package:zephyr/page/setting/global/global_setting.dart' as _i13;
import 'package:zephyr/page/setting/jm/jm_setting.dart' as _i16;
import 'package:zephyr/page/theme_color/view/theme_color_page.dart' as _i26;
import 'package:zephyr/page/user_comments/view/user_comments_page.dart' as _i27;
import 'package:zephyr/page/webdav_sync/view/webdav_sync_page.dart' as _i28;
import 'package:zephyr/page/webview_page.dart' as _i29;
import 'package:zephyr/type/enum.dart' as _i32;
import 'package:zephyr/widgets/full_screen_image_view.dart' as _i12;

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
/// [_i4.ChangelogPage]
class ChangelogRoute extends _i30.PageRouteInfo<void> {
  const ChangelogRoute({List<_i30.PageRouteInfo>? children})
    : super(ChangelogRoute.name, initialChildren: children);

  static const String name = 'ChangelogRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i4.ChangelogPage();
    },
  );
}

/// generated route for
/// [_i5.ComicInfoPage]
class ComicInfoRoute extends _i30.PageRouteInfo<ComicInfoRouteArgs> {
  ComicInfoRoute({
    _i31.Key? key,
    required String comicId,
    required _i32.From from,
    required _i32.ComicEntryType type,
    List<_i30.PageRouteInfo>? children,
  }) : super(
         ComicInfoRoute.name,
         args: ComicInfoRouteArgs(
           key: key,
           comicId: comicId,
           from: from,
           type: type,
         ),
         initialChildren: children,
       );

  static const String name = 'ComicInfoRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ComicInfoRouteArgs>();
      return _i5.ComicInfoPage(
        key: args.key,
        comicId: args.comicId,
        from: args.from,
        type: args.type,
      );
    },
  );
}

class ComicInfoRouteArgs {
  const ComicInfoRouteArgs({
    this.key,
    required this.comicId,
    required this.from,
    required this.type,
  });

  final _i31.Key? key;

  final String comicId;

  final _i32.From from;

  final _i32.ComicEntryType type;

  @override
  String toString() {
    return 'ComicInfoRouteArgs{key: $key, comicId: $comicId, from: $from, type: $type}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ComicInfoRouteArgs) return false;
    return key == other.key &&
        comicId == other.comicId &&
        from == other.from &&
        type == other.type;
  }

  @override
  int get hashCode =>
      key.hashCode ^ comicId.hashCode ^ from.hashCode ^ type.hashCode;
}

/// generated route for
/// [_i6.ComicListPage]
class ComicListRoute extends _i30.PageRouteInfo<ComicListRouteArgs> {
  ComicListRoute({
    _i31.Key? key,
    String? title,
    _i33.ComicListScene? scene,
    _i32.From? sceneSource,
    String? sceneBundleFnPath,
    String? sceneBundleFnPathFallback,
    List<_i30.PageRouteInfo>? children,
  }) : super(
         ComicListRoute.name,
         args: ComicListRouteArgs(
           key: key,
           title: title,
           scene: scene,
           sceneSource: sceneSource,
           sceneBundleFnPath: sceneBundleFnPath,
           sceneBundleFnPathFallback: sceneBundleFnPathFallback,
         ),
         initialChildren: children,
       );

  static const String name = 'ComicListRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ComicListRouteArgs>(
        orElse: () => const ComicListRouteArgs(),
      );
      return _i6.ComicListPage(
        key: args.key,
        title: args.title,
        scene: args.scene,
        sceneSource: args.sceneSource,
        sceneBundleFnPath: args.sceneBundleFnPath,
        sceneBundleFnPathFallback: args.sceneBundleFnPathFallback,
      );
    },
  );
}

class ComicListRouteArgs {
  const ComicListRouteArgs({
    this.key,
    this.title,
    this.scene,
    this.sceneSource,
    this.sceneBundleFnPath,
    this.sceneBundleFnPathFallback,
  });

  final _i31.Key? key;

  final String? title;

  final _i33.ComicListScene? scene;

  final _i32.From? sceneSource;

  final String? sceneBundleFnPath;

  final String? sceneBundleFnPathFallback;

  @override
  String toString() {
    return 'ComicListRouteArgs{key: $key, title: $title, scene: $scene, sceneSource: $sceneSource, sceneBundleFnPath: $sceneBundleFnPath, sceneBundleFnPathFallback: $sceneBundleFnPathFallback}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ComicListRouteArgs) return false;
    return key == other.key &&
        title == other.title &&
        scene == other.scene &&
        sceneSource == other.sceneSource &&
        sceneBundleFnPath == other.sceneBundleFnPath &&
        sceneBundleFnPathFallback == other.sceneBundleFnPathFallback;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      title.hashCode ^
      scene.hashCode ^
      sceneSource.hashCode ^
      sceneBundleFnPath.hashCode ^
      sceneBundleFnPathFallback.hashCode;
}

/// generated route for
/// [_i7.ComicReadPage]
class ComicReadRoute extends _i30.PageRouteInfo<ComicReadRouteArgs> {
  ComicReadRoute({
    _i34.Key? key,
    required String comicId,
    required int order,
    required int epsNumber,
    required _i32.From from,
    required _i35.StringSelectCubit stringSelectCubit,
    required _i32.ComicEntryType type,
    required dynamic comicInfo,
    List<_i30.PageRouteInfo>? children,
  }) : super(
         ComicReadRoute.name,
         args: ComicReadRouteArgs(
           key: key,
           comicId: comicId,
           order: order,
           epsNumber: epsNumber,
           from: from,
           stringSelectCubit: stringSelectCubit,
           type: type,
           comicInfo: comicInfo,
         ),
         initialChildren: children,
       );

  static const String name = 'ComicReadRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ComicReadRouteArgs>();
      return _i7.ComicReadPage(
        key: args.key,
        comicId: args.comicId,
        order: args.order,
        epsNumber: args.epsNumber,
        from: args.from,
        stringSelectCubit: args.stringSelectCubit,
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
    required this.stringSelectCubit,
    required this.type,
    required this.comicInfo,
  });

  final _i34.Key? key;

  final String comicId;

  final int order;

  final int epsNumber;

  final _i32.From from;

  final _i35.StringSelectCubit stringSelectCubit;

  final _i32.ComicEntryType type;

  final dynamic comicInfo;

  @override
  String toString() {
    return 'ComicReadRouteArgs{key: $key, comicId: $comicId, order: $order, epsNumber: $epsNumber, from: $from, stringSelectCubit: $stringSelectCubit, type: $type, comicInfo: $comicInfo}';
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
        stringSelectCubit == other.stringSelectCubit &&
        type == other.type &&
        comicInfo == other.comicInfo;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      comicId.hashCode ^
      order.hashCode ^
      epsNumber.hashCode ^
      from.hashCode ^
      stringSelectCubit.hashCode ^
      type.hashCode ^
      comicInfo.hashCode;
}

/// generated route for
/// [_i8.CommentsChildrenPage]
class CommentsChildrenRoute
    extends _i30.PageRouteInfo<CommentsChildrenRouteArgs> {
  CommentsChildrenRoute({
    _i31.Key? key,
    required _i36.Doc fatherDoc,
    required _i37.BoolSelectCubit boolSelectCubit,
    required _i38.IntSelectCubit intSelectCubit,
    List<_i30.PageRouteInfo>? children,
  }) : super(
         CommentsChildrenRoute.name,
         args: CommentsChildrenRouteArgs(
           key: key,
           fatherDoc: fatherDoc,
           boolSelectCubit: boolSelectCubit,
           intSelectCubit: intSelectCubit,
         ),
         initialChildren: children,
       );

  static const String name = 'CommentsChildrenRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<CommentsChildrenRouteArgs>();
      return _i8.CommentsChildrenPage(
        key: args.key,
        fatherDoc: args.fatherDoc,
        boolSelectCubit: args.boolSelectCubit,
        intSelectCubit: args.intSelectCubit,
      );
    },
  );
}

class CommentsChildrenRouteArgs {
  const CommentsChildrenRouteArgs({
    this.key,
    required this.fatherDoc,
    required this.boolSelectCubit,
    required this.intSelectCubit,
  });

  final _i31.Key? key;

  final _i36.Doc fatherDoc;

  final _i37.BoolSelectCubit boolSelectCubit;

  final _i38.IntSelectCubit intSelectCubit;

  @override
  String toString() {
    return 'CommentsChildrenRouteArgs{key: $key, fatherDoc: $fatherDoc, boolSelectCubit: $boolSelectCubit, intSelectCubit: $intSelectCubit}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CommentsChildrenRouteArgs) return false;
    return key == other.key &&
        fatherDoc == other.fatherDoc &&
        boolSelectCubit == other.boolSelectCubit &&
        intSelectCubit == other.intSelectCubit;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      fatherDoc.hashCode ^
      boolSelectCubit.hashCode ^
      intSelectCubit.hashCode;
}

/// generated route for
/// [_i9.CommentsPage]
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
      return _i9.CommentsPage(
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
/// [_i10.DownloadPage]
class DownloadRoute extends _i30.PageRouteInfo<DownloadRouteArgs> {
  DownloadRoute({
    _i31.Key? key,
    required _i39.UnifiedComicDownloadInfo downloadInfo,
    List<_i30.PageRouteInfo>? children,
  }) : super(
         DownloadRoute.name,
         args: DownloadRouteArgs(key: key, downloadInfo: downloadInfo),
         initialChildren: children,
       );

  static const String name = 'DownloadRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<DownloadRouteArgs>();
      return _i10.DownloadPage(key: args.key, downloadInfo: args.downloadInfo);
    },
  );
}

class DownloadRouteArgs {
  const DownloadRouteArgs({this.key, required this.downloadInfo});

  final _i31.Key? key;

  final _i39.UnifiedComicDownloadInfo downloadInfo;

  @override
  String toString() {
    return 'DownloadRouteArgs{key: $key, downloadInfo: $downloadInfo}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DownloadRouteArgs) return false;
    return key == other.key && downloadInfo == other.downloadInfo;
  }

  @override
  int get hashCode => key.hashCode ^ downloadInfo.hashCode;
}

/// generated route for
/// [_i11.DownloadTaskPage]
class DownloadTaskRoute extends _i30.PageRouteInfo<void> {
  const DownloadTaskRoute({List<_i30.PageRouteInfo>? children})
    : super(DownloadTaskRoute.name, initialChildren: children);

  static const String name = 'DownloadTaskRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i11.DownloadTaskPage();
    },
  );
}

/// generated route for
/// [_i12.FullScreenImagePage]
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
      return _i12.FullScreenImagePage(key: args.key, imagePath: args.imagePath);
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
/// [_i13.GlobalSettingPage]
class GlobalSettingRoute extends _i30.PageRouteInfo<void> {
  const GlobalSettingRoute({List<_i30.PageRouteInfo>? children})
    : super(GlobalSettingRoute.name, initialChildren: children);

  static const String name = 'GlobalSettingRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i13.GlobalSettingPage();
    },
  );
}

/// generated route for
/// [_i14.HomePage]
class HomeRoute extends _i30.PageRouteInfo<void> {
  const HomeRoute({List<_i30.PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i14.HomePage();
    },
  );
}

/// generated route for
/// [_i15.ImageCropPage]
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
      return _i15.ImageCropPage(key: args.key, imageData: args.imageData);
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
/// [_i16.JMSettingPage]
class JMSettingRoute extends _i30.PageRouteInfo<void> {
  const JMSettingRoute({List<_i30.PageRouteInfo>? children})
    : super(JMSettingRoute.name, initialChildren: children);

  static const String name = 'JMSettingRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i16.JMSettingPage();
    },
  );
}

/// generated route for
/// [_i17.JmCommentsPage]
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
      return _i17.JmCommentsPage(
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
/// [_i19.LoginPage]
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
      return _i19.LoginPage(key: args.key, from: args.from);
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
/// [_i20.NavigationBar]
class NavigationBar extends _i30.PageRouteInfo<void> {
  const NavigationBar({List<_i30.PageRouteInfo>? children})
    : super(NavigationBar.name, initialChildren: children);

  static const String name = 'NavigationBar';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i20.NavigationBar();
    },
  );
}

/// generated route for
/// [_i21.RegisterPage]
class RegisterRoute extends _i30.PageRouteInfo<void> {
  const RegisterRoute({List<_i30.PageRouteInfo>? children})
    : super(RegisterRoute.name, initialChildren: children);

  static const String name = 'RegisterRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i21.RegisterPage();
    },
  );
}

/// generated route for
/// [_i22.SearchAggregateResultPage]
class SearchAggregateResultRoute
    extends _i30.PageRouteInfo<SearchAggregateResultRouteArgs> {
  SearchAggregateResultRoute({
    _i31.Key? key,
    required _i41.SearchEvent searchEvent,
    _i42.SearchCubit? searchCubit,
    Map<String, bool> selectedSources = const <String, bool>{
      'jm': true,
      'bika': true,
    },
    List<_i30.PageRouteInfo>? children,
  }) : super(
         SearchAggregateResultRoute.name,
         args: SearchAggregateResultRouteArgs(
           key: key,
           searchEvent: searchEvent,
           searchCubit: searchCubit,
           selectedSources: selectedSources,
         ),
         initialChildren: children,
       );

  static const String name = 'SearchAggregateResultRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SearchAggregateResultRouteArgs>();
      return _i30.WrappedRoute(
        child: _i22.SearchAggregateResultPage(
          key: args.key,
          searchEvent: args.searchEvent,
          searchCubit: args.searchCubit,
          selectedSources: args.selectedSources,
        ),
      );
    },
  );
}

class SearchAggregateResultRouteArgs {
  const SearchAggregateResultRouteArgs({
    this.key,
    required this.searchEvent,
    this.searchCubit,
    this.selectedSources = const <String, bool>{'jm': true, 'bika': true},
  });

  final _i31.Key? key;

  final _i41.SearchEvent searchEvent;

  final _i42.SearchCubit? searchCubit;

  final Map<String, bool> selectedSources;

  @override
  String toString() {
    return 'SearchAggregateResultRouteArgs{key: $key, searchEvent: $searchEvent, searchCubit: $searchCubit, selectedSources: $selectedSources}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SearchAggregateResultRouteArgs) return false;
    return key == other.key &&
        searchEvent == other.searchEvent &&
        searchCubit == other.searchCubit &&
        const _i43.MapEquality<String, bool>().equals(
          selectedSources,
          other.selectedSources,
        );
  }

  @override
  int get hashCode =>
      key.hashCode ^
      searchEvent.hashCode ^
      searchCubit.hashCode ^
      const _i43.MapEquality<String, bool>().hash(selectedSources);
}

/// generated route for
/// [_i23.SearchPage]
class SearchRoute extends _i30.PageRouteInfo<SearchRouteArgs> {
  SearchRoute({
    _i31.Key? key,
    required _i42.SearchStates searchState,
    bool aggregateMode = true,
    List<_i30.PageRouteInfo>? children,
  }) : super(
         SearchRoute.name,
         args: SearchRouteArgs(
           key: key,
           searchState: searchState,
           aggregateMode: aggregateMode,
         ),
         initialChildren: children,
       );

  static const String name = 'SearchRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SearchRouteArgs>();
      return _i23.SearchPage(
        key: args.key,
        searchState: args.searchState,
        aggregateMode: args.aggregateMode,
      );
    },
  );
}

class SearchRouteArgs {
  const SearchRouteArgs({
    this.key,
    required this.searchState,
    this.aggregateMode = true,
  });

  final _i31.Key? key;

  final _i42.SearchStates searchState;

  final bool aggregateMode;

  @override
  String toString() {
    return 'SearchRouteArgs{key: $key, searchState: $searchState, aggregateMode: $aggregateMode}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SearchRouteArgs) return false;
    return key == other.key &&
        searchState == other.searchState &&
        aggregateMode == other.aggregateMode;
  }

  @override
  int get hashCode =>
      key.hashCode ^ searchState.hashCode ^ aggregateMode.hashCode;
}

/// generated route for
/// [_i24.SearchResultPage]
class SearchResultRoute extends _i30.PageRouteInfo<SearchResultRouteArgs> {
  SearchResultRoute({
    _i31.Key? key,
    required _i44.SearchEvent searchEvent,
    _i42.SearchCubit? searchCubit,
    List<_i30.PageRouteInfo>? children,
  }) : super(
         SearchResultRoute.name,
         args: SearchResultRouteArgs(
           key: key,
           searchEvent: searchEvent,
           searchCubit: searchCubit,
         ),
         initialChildren: children,
       );

  static const String name = 'SearchResultRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SearchResultRouteArgs>();
      return _i30.WrappedRoute(
        child: _i24.SearchResultPage(
          key: args.key,
          searchEvent: args.searchEvent,
          searchCubit: args.searchCubit,
        ),
      );
    },
  );
}

class SearchResultRouteArgs {
  const SearchResultRouteArgs({
    this.key,
    required this.searchEvent,
    this.searchCubit,
  });

  final _i31.Key? key;

  final _i44.SearchEvent searchEvent;

  final _i42.SearchCubit? searchCubit;

  @override
  String toString() {
    return 'SearchResultRouteArgs{key: $key, searchEvent: $searchEvent, searchCubit: $searchCubit}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SearchResultRouteArgs) return false;
    return key == other.key &&
        searchEvent == other.searchEvent &&
        searchCubit == other.searchCubit;
  }

  @override
  int get hashCode =>
      key.hashCode ^ searchEvent.hashCode ^ searchCubit.hashCode;
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
        const _i43.ListEquality<String>().equals(info, other.info);
  }

  @override
  int get hashCode =>
      key.hashCode ^ const _i43.ListEquality<String>().hash(info);
}
