// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i45;

import 'package:auto_route/auto_route.dart' as _i35;
import 'package:collection/collection.dart' as _i44;
import 'package:flutter/material.dart' as _i36;
import 'package:zephyr/cubit/bool_select.dart' as _i40;
import 'package:zephyr/cubit/int_select.dart' as _i41;
import 'package:zephyr/cubit/string_select.dart' as _i38;
import 'package:zephyr/debug/show_color.dart' as _i29;
import 'package:zephyr/page/about/view/about_page.dart' as _i1;
import 'package:zephyr/page/bookshelf/view/bookshelf_page.dart' as _i3;
import 'package:zephyr/page/change_log_page.dart' as _i4;
import 'package:zephyr/page/comic_info/json/bika/comic_info/comic_info.dart'
    as _i42;
import 'package:zephyr/page/comic_info/json/bika/eps/eps.dart' as _i43;
import 'package:zephyr/page/comic_info/json/jm/jm_comic_info_json.dart' as _i46;
import 'package:zephyr/page/comic_info/view/comic_info.dart' as _i5;
import 'package:zephyr/page/comic_read/view/comic_read.dart' as _i6;
import 'package:zephyr/page/comments/json/comments_json/comments_json.dart'
    as _i39;
import 'package:zephyr/page/comments/view/comments.dart' as _i8;
import 'package:zephyr/page/comments_children/view/comments_children_page.dart'
    as _i7;
import 'package:zephyr/page/download/view/download.dart' as _i9;
import 'package:zephyr/page/home/view/home.dart' as _i12;
import 'package:zephyr/page/image_crop.dart' as _i13;
import 'package:zephyr/page/jm/jm_comments/view/jm_comments.dart' as _i15;
import 'package:zephyr/page/jm/jm_download/view/view.dart' as _i16;
import 'package:zephyr/page/jm/jm_promote/view/jm_promote.dart' as _i18;
import 'package:zephyr/page/jm/jm_promote_list/view/jm_promote_list.dart'
    as _i17;
import 'package:zephyr/page/jm/jm_ranking/view/jm_ranking.dart' as _i19;
import 'package:zephyr/page/jm/jm_ranking/widget/time_ranking.dart' as _i31;
import 'package:zephyr/page/jm/jm_search_result/jm_search_result.dart' as _i47;
import 'package:zephyr/page/jm/jm_search_result/view/view.dart' as _i21;
import 'package:zephyr/page/jm/jm_week_ranking/view/jm_week_ranking.dart'
    as _i22;
import 'package:zephyr/page/login_page.dart' as _i23;
import 'package:zephyr/page/navigation_bar.dart' as _i24;
import 'package:zephyr/page/ranking_list/view/ranking_list_page.dart' as _i25;
import 'package:zephyr/page/register/bika/register_page.dart' as _i26;
import 'package:zephyr/page/register/jm/jm_register_page.dart' as _i20;
import 'package:zephyr/page/search/cubit/search_cubit.dart' as _i48;
import 'package:zephyr/page/search/view/search_page.dart' as _i27;
import 'package:zephyr/page/search_result/search_result.dart' as _i49;
import 'package:zephyr/page/search_result/view/search_result_page.dart' as _i28;
import 'package:zephyr/page/setting/bika/bika_setting.dart' as _i2;
import 'package:zephyr/page/setting/global/global_setting.dart' as _i11;
import 'package:zephyr/page/setting/jm/jm_setting.dart' as _i14;
import 'package:zephyr/page/theme_color/view/theme_color_page.dart' as _i30;
import 'package:zephyr/page/user_comments/view/user_comments_page.dart' as _i32;
import 'package:zephyr/page/webdav_sync/view/webdav_sync_page.dart' as _i33;
import 'package:zephyr/page/webview_page.dart' as _i34;
import 'package:zephyr/type/enum.dart' as _i37;
import 'package:zephyr/widgets/full_screen_image_view.dart' as _i10;

/// generated route for
/// [_i1.AboutPage]
class AboutRoute extends _i35.PageRouteInfo<void> {
  const AboutRoute({List<_i35.PageRouteInfo>? children})
    : super(AboutRoute.name, initialChildren: children);

  static const String name = 'AboutRoute';

  static _i35.PageInfo page = _i35.PageInfo(
    name,
    builder: (data) {
      return const _i1.AboutPage();
    },
  );
}

/// generated route for
/// [_i2.BikaSettingPage]
class BikaSettingRoute extends _i35.PageRouteInfo<void> {
  const BikaSettingRoute({List<_i35.PageRouteInfo>? children})
    : super(BikaSettingRoute.name, initialChildren: children);

  static const String name = 'BikaSettingRoute';

  static _i35.PageInfo page = _i35.PageInfo(
    name,
    builder: (data) {
      return const _i2.BikaSettingPage();
    },
  );
}

/// generated route for
/// [_i3.BookshelfPage]
class BookshelfRoute extends _i35.PageRouteInfo<void> {
  const BookshelfRoute({List<_i35.PageRouteInfo>? children})
    : super(BookshelfRoute.name, initialChildren: children);

  static const String name = 'BookshelfRoute';

  static _i35.PageInfo page = _i35.PageInfo(
    name,
    builder: (data) {
      return const _i3.BookshelfPage();
    },
  );
}

/// generated route for
/// [_i4.ChangelogPage]
class ChangelogRoute extends _i35.PageRouteInfo<void> {
  const ChangelogRoute({List<_i35.PageRouteInfo>? children})
    : super(ChangelogRoute.name, initialChildren: children);

  static const String name = 'ChangelogRoute';

  static _i35.PageInfo page = _i35.PageInfo(
    name,
    builder: (data) {
      return const _i4.ChangelogPage();
    },
  );
}

/// generated route for
/// [_i5.ComicInfoPage]
class ComicInfoRoute extends _i35.PageRouteInfo<ComicInfoRouteArgs> {
  ComicInfoRoute({
    _i36.Key? key,
    required String comicId,
    required _i37.From from,
    required _i37.ComicEntryType type,
    List<_i35.PageRouteInfo>? children,
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

  static _i35.PageInfo page = _i35.PageInfo(
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

  final _i36.Key? key;

  final String comicId;

  final _i37.From from;

  final _i37.ComicEntryType type;

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
/// [_i6.ComicReadPage]
class ComicReadRoute extends _i35.PageRouteInfo<ComicReadRouteArgs> {
  ComicReadRoute({
    _i36.Key? key,
    required String comicId,
    required int order,
    required int epsNumber,
    required _i37.From from,
    required _i38.StringSelectCubit stringSelectCubit,
    required _i37.ComicEntryType type,
    required dynamic comicInfo,
    List<_i35.PageRouteInfo>? children,
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

  static _i35.PageInfo page = _i35.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ComicReadRouteArgs>();
      return _i6.ComicReadPage(
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

  final _i36.Key? key;

  final String comicId;

  final int order;

  final int epsNumber;

  final _i37.From from;

  final _i38.StringSelectCubit stringSelectCubit;

  final _i37.ComicEntryType type;

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
/// [_i7.CommentsChildrenPage]
class CommentsChildrenRoute
    extends _i35.PageRouteInfo<CommentsChildrenRouteArgs> {
  CommentsChildrenRoute({
    _i36.Key? key,
    required _i39.Doc fatherDoc,
    required _i40.BoolSelectCubit boolSelectCubit,
    required _i41.IntSelectCubit intSelectCubit,
    List<_i35.PageRouteInfo>? children,
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

  static _i35.PageInfo page = _i35.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<CommentsChildrenRouteArgs>();
      return _i7.CommentsChildrenPage(
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

  final _i36.Key? key;

  final _i39.Doc fatherDoc;

  final _i40.BoolSelectCubit boolSelectCubit;

  final _i41.IntSelectCubit intSelectCubit;

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
/// [_i8.CommentsPage]
class CommentsRoute extends _i35.PageRouteInfo<CommentsRouteArgs> {
  CommentsRoute({
    _i36.Key? key,
    required String comicId,
    required String comicTitle,
    List<_i35.PageRouteInfo>? children,
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

  static _i35.PageInfo page = _i35.PageInfo(
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

  final _i36.Key? key;

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
/// [_i9.DownloadPage]
class DownloadRoute extends _i35.PageRouteInfo<DownloadRouteArgs> {
  DownloadRoute({
    _i36.Key? key,
    required _i42.Comic comicInfo,
    required List<_i43.Doc> epsInfo,
    List<_i35.PageRouteInfo>? children,
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

  static _i35.PageInfo page = _i35.PageInfo(
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

  final _i36.Key? key;

  final _i42.Comic comicInfo;

  final List<_i43.Doc> epsInfo;

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
        const _i44.ListEquality<_i43.Doc>().equals(epsInfo, other.epsInfo);
  }

  @override
  int get hashCode =>
      key.hashCode ^
      comicInfo.hashCode ^
      const _i44.ListEquality<_i43.Doc>().hash(epsInfo);
}

/// generated route for
/// [_i10.FullScreenImagePage]
class FullRouteImageRoute extends _i35.PageRouteInfo<FullRouteImageRouteArgs> {
  FullRouteImageRoute({
    _i36.Key? key,
    required String imagePath,
    List<_i35.PageRouteInfo>? children,
  }) : super(
         FullRouteImageRoute.name,
         args: FullRouteImageRouteArgs(key: key, imagePath: imagePath),
         initialChildren: children,
       );

  static const String name = 'FullRouteImageRoute';

  static _i35.PageInfo page = _i35.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<FullRouteImageRouteArgs>();
      return _i10.FullScreenImagePage(key: args.key, imagePath: args.imagePath);
    },
  );
}

class FullRouteImageRouteArgs {
  const FullRouteImageRouteArgs({this.key, required this.imagePath});

  final _i36.Key? key;

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
/// [_i11.GlobalSettingPage]
class GlobalSettingRoute extends _i35.PageRouteInfo<void> {
  const GlobalSettingRoute({List<_i35.PageRouteInfo>? children})
    : super(GlobalSettingRoute.name, initialChildren: children);

  static const String name = 'GlobalSettingRoute';

  static _i35.PageInfo page = _i35.PageInfo(
    name,
    builder: (data) {
      return const _i11.GlobalSettingPage();
    },
  );
}

/// generated route for
/// [_i12.HomePage]
class HomeRoute extends _i35.PageRouteInfo<void> {
  const HomeRoute({List<_i35.PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static _i35.PageInfo page = _i35.PageInfo(
    name,
    builder: (data) {
      return const _i12.HomePage();
    },
  );
}

/// generated route for
/// [_i13.ImageCropPage]
class ImageCropRoute extends _i35.PageRouteInfo<ImageCropRouteArgs> {
  ImageCropRoute({
    _i36.Key? key,
    required _i45.Uint8List imageData,
    List<_i35.PageRouteInfo>? children,
  }) : super(
         ImageCropRoute.name,
         args: ImageCropRouteArgs(key: key, imageData: imageData),
         initialChildren: children,
       );

  static const String name = 'ImageCropRoute';

  static _i35.PageInfo page = _i35.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ImageCropRouteArgs>();
      return _i13.ImageCropPage(key: args.key, imageData: args.imageData);
    },
  );
}

class ImageCropRouteArgs {
  const ImageCropRouteArgs({this.key, required this.imageData});

  final _i36.Key? key;

  final _i45.Uint8List imageData;

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
/// [_i14.JMSettingPage]
class JMSettingRoute extends _i35.PageRouteInfo<void> {
  const JMSettingRoute({List<_i35.PageRouteInfo>? children})
    : super(JMSettingRoute.name, initialChildren: children);

  static const String name = 'JMSettingRoute';

  static _i35.PageInfo page = _i35.PageInfo(
    name,
    builder: (data) {
      return const _i14.JMSettingPage();
    },
  );
}

/// generated route for
/// [_i15.JmCommentsPage]
class JmCommentsRoute extends _i35.PageRouteInfo<JmCommentsRouteArgs> {
  JmCommentsRoute({
    _i36.Key? key,
    required String comicId,
    required String comicTitle,
    List<_i35.PageRouteInfo>? children,
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

  static _i35.PageInfo page = _i35.PageInfo(
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

  final _i36.Key? key;

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
class JmDownloadRoute extends _i35.PageRouteInfo<JmDownloadRouteArgs> {
  JmDownloadRoute({
    _i36.Key? key,
    required _i46.JmComicInfoJson jmComicInfoJson,
    List<_i35.PageRouteInfo>? children,
  }) : super(
         JmDownloadRoute.name,
         args: JmDownloadRouteArgs(key: key, jmComicInfoJson: jmComicInfoJson),
         initialChildren: children,
       );

  static const String name = 'JmDownloadRoute';

  static _i35.PageInfo page = _i35.PageInfo(
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

  final _i36.Key? key;

  final _i46.JmComicInfoJson jmComicInfoJson;

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
/// [_i17.JmPromoteListPage]
class JmPromoteListRoute extends _i35.PageRouteInfo<JmPromoteListRouteArgs> {
  JmPromoteListRoute({
    _i36.Key? key,
    required int id,
    required String name,
    List<_i35.PageRouteInfo>? children,
  }) : super(
         JmPromoteListRoute.name,
         args: JmPromoteListRouteArgs(key: key, id: id, name: name),
         initialChildren: children,
       );

  static const String name = 'JmPromoteListRoute';

  static _i35.PageInfo page = _i35.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<JmPromoteListRouteArgs>();
      return _i17.JmPromoteListPage(
        key: args.key,
        id: args.id,
        name: args.name,
      );
    },
  );
}

class JmPromoteListRouteArgs {
  const JmPromoteListRouteArgs({
    this.key,
    required this.id,
    required this.name,
  });

  final _i36.Key? key;

  final int id;

  final String name;

  @override
  String toString() {
    return 'JmPromoteListRouteArgs{key: $key, id: $id, name: $name}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! JmPromoteListRouteArgs) return false;
    return key == other.key && id == other.id && name == other.name;
  }

  @override
  int get hashCode => key.hashCode ^ id.hashCode ^ name.hashCode;
}

/// generated route for
/// [_i18.JmPromotePage]
class JmPromoteRoute extends _i35.PageRouteInfo<void> {
  const JmPromoteRoute({List<_i35.PageRouteInfo>? children})
    : super(JmPromoteRoute.name, initialChildren: children);

  static const String name = 'JmPromoteRoute';

  static _i35.PageInfo page = _i35.PageInfo(
    name,
    builder: (data) {
      return const _i18.JmPromotePage();
    },
  );
}

/// generated route for
/// [_i19.JmRankingPage]
class JmRankingRoute extends _i35.PageRouteInfo<JmRankingRouteArgs> {
  JmRankingRoute({
    _i36.Key? key,
    String categoryId = '0',
    String sortId = 'new',
    List<_i35.PageRouteInfo>? children,
  }) : super(
         JmRankingRoute.name,
         args: JmRankingRouteArgs(
           key: key,
           categoryId: categoryId,
           sortId: sortId,
         ),
         initialChildren: children,
       );

  static const String name = 'JmRankingRoute';

  static _i35.PageInfo page = _i35.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<JmRankingRouteArgs>(
        orElse: () => const JmRankingRouteArgs(),
      );
      return _i19.JmRankingPage(
        key: args.key,
        categoryId: args.categoryId,
        sortId: args.sortId,
      );
    },
  );
}

class JmRankingRouteArgs {
  const JmRankingRouteArgs({
    this.key,
    this.categoryId = '0',
    this.sortId = 'new',
  });

  final _i36.Key? key;

  final String categoryId;

  final String sortId;

  @override
  String toString() {
    return 'JmRankingRouteArgs{key: $key, categoryId: $categoryId, sortId: $sortId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! JmRankingRouteArgs) return false;
    return key == other.key &&
        categoryId == other.categoryId &&
        sortId == other.sortId;
  }

  @override
  int get hashCode => key.hashCode ^ categoryId.hashCode ^ sortId.hashCode;
}

/// generated route for
/// [_i20.JmRegisterPage]
class JmRegisterRoute extends _i35.PageRouteInfo<void> {
  const JmRegisterRoute({List<_i35.PageRouteInfo>? children})
    : super(JmRegisterRoute.name, initialChildren: children);

  static const String name = 'JmRegisterRoute';

  static _i35.PageInfo page = _i35.PageInfo(
    name,
    builder: (data) {
      return const _i20.JmRegisterPage();
    },
  );
}

/// generated route for
/// [_i21.JmSearchResultPage]
class JmSearchResultRoute extends _i35.PageRouteInfo<JmSearchResultRouteArgs> {
  JmSearchResultRoute({
    _i36.Key? key,
    required _i47.JmSearchResultEvent event,
    List<_i35.PageRouteInfo>? children,
  }) : super(
         JmSearchResultRoute.name,
         args: JmSearchResultRouteArgs(key: key, event: event),
         initialChildren: children,
       );

  static const String name = 'JmSearchResultRoute';

  static _i35.PageInfo page = _i35.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<JmSearchResultRouteArgs>();
      return _i21.JmSearchResultPage(key: args.key, event: args.event);
    },
  );
}

class JmSearchResultRouteArgs {
  const JmSearchResultRouteArgs({this.key, required this.event});

  final _i36.Key? key;

  final _i47.JmSearchResultEvent event;

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
/// [_i22.JmWeekRankingPage]
class JmWeekRankingRoute extends _i35.PageRouteInfo<void> {
  const JmWeekRankingRoute({List<_i35.PageRouteInfo>? children})
    : super(JmWeekRankingRoute.name, initialChildren: children);

  static const String name = 'JmWeekRankingRoute';

  static _i35.PageInfo page = _i35.PageInfo(
    name,
    builder: (data) {
      return const _i22.JmWeekRankingPage();
    },
  );
}

/// generated route for
/// [_i23.LoginPage]
class LoginRoute extends _i35.PageRouteInfo<LoginRouteArgs> {
  LoginRoute({
    _i36.Key? key,
    _i37.From? from,
    List<_i35.PageRouteInfo>? children,
  }) : super(
         LoginRoute.name,
         args: LoginRouteArgs(key: key, from: from),
         initialChildren: children,
       );

  static const String name = 'LoginRoute';

  static _i35.PageInfo page = _i35.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<LoginRouteArgs>(
        orElse: () => const LoginRouteArgs(),
      );
      return _i23.LoginPage(key: args.key, from: args.from);
    },
  );
}

class LoginRouteArgs {
  const LoginRouteArgs({this.key, this.from});

  final _i36.Key? key;

  final _i37.From? from;

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
/// [_i24.NavigationBar]
class NavigationBar extends _i35.PageRouteInfo<void> {
  const NavigationBar({List<_i35.PageRouteInfo>? children})
    : super(NavigationBar.name, initialChildren: children);

  static const String name = 'NavigationBar';

  static _i35.PageInfo page = _i35.PageInfo(
    name,
    builder: (data) {
      return const _i24.NavigationBar();
    },
  );
}

/// generated route for
/// [_i25.RankingListPage]
class RankingListRoute extends _i35.PageRouteInfo<void> {
  const RankingListRoute({List<_i35.PageRouteInfo>? children})
    : super(RankingListRoute.name, initialChildren: children);

  static const String name = 'RankingListRoute';

  static _i35.PageInfo page = _i35.PageInfo(
    name,
    builder: (data) {
      return const _i25.RankingListPage();
    },
  );
}

/// generated route for
/// [_i26.RegisterPage]
class RegisterRoute extends _i35.PageRouteInfo<void> {
  const RegisterRoute({List<_i35.PageRouteInfo>? children})
    : super(RegisterRoute.name, initialChildren: children);

  static const String name = 'RegisterRoute';

  static _i35.PageInfo page = _i35.PageInfo(
    name,
    builder: (data) {
      return const _i26.RegisterPage();
    },
  );
}

/// generated route for
/// [_i27.SearchPage]
class SearchRoute extends _i35.PageRouteInfo<SearchRouteArgs> {
  SearchRoute({
    _i36.Key? key,
    required _i48.SearchStates searchState,
    List<_i35.PageRouteInfo>? children,
  }) : super(
         SearchRoute.name,
         args: SearchRouteArgs(key: key, searchState: searchState),
         initialChildren: children,
       );

  static const String name = 'SearchRoute';

  static _i35.PageInfo page = _i35.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SearchRouteArgs>();
      return _i27.SearchPage(key: args.key, searchState: args.searchState);
    },
  );
}

class SearchRouteArgs {
  const SearchRouteArgs({this.key, required this.searchState});

  final _i36.Key? key;

  final _i48.SearchStates searchState;

  @override
  String toString() {
    return 'SearchRouteArgs{key: $key, searchState: $searchState}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SearchRouteArgs) return false;
    return key == other.key && searchState == other.searchState;
  }

  @override
  int get hashCode => key.hashCode ^ searchState.hashCode;
}

/// generated route for
/// [_i28.SearchResultPage]
class SearchResultRoute extends _i35.PageRouteInfo<SearchResultRouteArgs> {
  SearchResultRoute({
    _i36.Key? key,
    required _i49.SearchEnter searchEnter,
    List<_i35.PageRouteInfo>? children,
  }) : super(
         SearchResultRoute.name,
         args: SearchResultRouteArgs(key: key, searchEnter: searchEnter),
         initialChildren: children,
       );

  static const String name = 'SearchResultRoute';

  static _i35.PageInfo page = _i35.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SearchResultRouteArgs>();
      return _i28.SearchResultPage(
        key: args.key,
        searchEnter: args.searchEnter,
      );
    },
  );
}

class SearchResultRouteArgs {
  const SearchResultRouteArgs({this.key, required this.searchEnter});

  final _i36.Key? key;

  final _i49.SearchEnter searchEnter;

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
/// [_i29.ShowColorPage]
class ShowColorRoute extends _i35.PageRouteInfo<void> {
  const ShowColorRoute({List<_i35.PageRouteInfo>? children})
    : super(ShowColorRoute.name, initialChildren: children);

  static const String name = 'ShowColorRoute';

  static _i35.PageInfo page = _i35.PageInfo(
    name,
    builder: (data) {
      return const _i29.ShowColorPage();
    },
  );
}

/// generated route for
/// [_i30.ThemeColorPage]
class ThemeColorRoute extends _i35.PageRouteInfo<void> {
  const ThemeColorRoute({List<_i35.PageRouteInfo>? children})
    : super(ThemeColorRoute.name, initialChildren: children);

  static const String name = 'ThemeColorRoute';

  static _i35.PageInfo page = _i35.PageInfo(
    name,
    builder: (data) {
      return const _i30.ThemeColorPage();
    },
  );
}

/// generated route for
/// [_i31.TimeRankingPage]
class TimeRankingRoute extends _i35.PageRouteInfo<TimeRankingRouteArgs> {
  TimeRankingRoute({
    _i36.Key? key,
    required String tag,
    String? title,
    List<_i35.PageRouteInfo>? children,
  }) : super(
         TimeRankingRoute.name,
         args: TimeRankingRouteArgs(key: key, tag: tag, title: title),
         initialChildren: children,
       );

  static const String name = 'TimeRankingRoute';

  static _i35.PageInfo page = _i35.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TimeRankingRouteArgs>();
      return _i31.TimeRankingPage(
        key: args.key,
        tag: args.tag,
        title: args.title,
      );
    },
  );
}

class TimeRankingRouteArgs {
  const TimeRankingRouteArgs({this.key, required this.tag, this.title});

  final _i36.Key? key;

  final String tag;

  final String? title;

  @override
  String toString() {
    return 'TimeRankingRouteArgs{key: $key, tag: $tag, title: $title}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TimeRankingRouteArgs) return false;
    return key == other.key && tag == other.tag && title == other.title;
  }

  @override
  int get hashCode => key.hashCode ^ tag.hashCode ^ title.hashCode;
}

/// generated route for
/// [_i32.UserCommentsPage]
class UserCommentsRoute extends _i35.PageRouteInfo<void> {
  const UserCommentsRoute({List<_i35.PageRouteInfo>? children})
    : super(UserCommentsRoute.name, initialChildren: children);

  static const String name = 'UserCommentsRoute';

  static _i35.PageInfo page = _i35.PageInfo(
    name,
    builder: (data) {
      return const _i32.UserCommentsPage();
    },
  );
}

/// generated route for
/// [_i33.WebDavSyncPage]
class WebDavSyncRoute extends _i35.PageRouteInfo<void> {
  const WebDavSyncRoute({List<_i35.PageRouteInfo>? children})
    : super(WebDavSyncRoute.name, initialChildren: children);

  static const String name = 'WebDavSyncRoute';

  static _i35.PageInfo page = _i35.PageInfo(
    name,
    builder: (data) {
      return const _i33.WebDavSyncPage();
    },
  );
}

/// generated route for
/// [_i34.WebViewPage]
class WebViewRoute extends _i35.PageRouteInfo<WebViewRouteArgs> {
  WebViewRoute({
    _i36.Key? key,
    required List<String> info,
    List<_i35.PageRouteInfo>? children,
  }) : super(
         WebViewRoute.name,
         args: WebViewRouteArgs(key: key, info: info),
         initialChildren: children,
       );

  static const String name = 'WebViewRoute';

  static _i35.PageInfo page = _i35.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<WebViewRouteArgs>();
      return _i34.WebViewPage(key: args.key, info: args.info);
    },
  );
}

class WebViewRouteArgs {
  const WebViewRouteArgs({this.key, required this.info});

  final _i36.Key? key;

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
        const _i44.ListEquality<String>().equals(info, other.info);
  }

  @override
  int get hashCode =>
      key.hashCode ^ const _i44.ListEquality<String>().hash(info);
}
