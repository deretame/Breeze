import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/debouncer.dart';
import 'package:zephyr/widgets/toast.dart';

import '../../main.dart';
import '../../object_box/objectbox.g.dart';
import '../../type/enum.dart';
import '../../util/router/router.gr.dart';
import 'comic_simplify_entry_info.dart';
import 'cover.dart';

class ComicSimplifyEntryRow extends StatelessWidget {
  final List<ComicSimplifyEntryInfo> entries;
  final ComicEntryType type;
  final VoidCallback? refresh;

  const ComicSimplifyEntryRow({
    super.key,
    required this.entries,
    required this.type,
    this.refresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          entries
              .map(
                (entry) => ComicSimplifyEntry(
                  info: entry,
                  type: type,
                  refresh: refresh,
                ),
              )
              .toList(),
    );
  }
}

class ComicSimplifyEntry extends StatelessWidget {
  final ComicSimplifyEntryInfo info;
  final ComicEntryType type;
  final VoidCallback? refresh;
  final bool topPadding;
  final bool roundedCorner;

  const ComicSimplifyEntry({
    super.key,
    required this.info,
    required this.type,
    this.refresh,
    this.topPadding = true,
    this.roundedCorner = true,
  });

  @override
  Widget build(BuildContext context) {
    double width;
    if (isTabletWithOutContext()) {
      if (isLandscape(context)) {
        width = context.screenWidth * 0.15;
      } else {
        width = context.screenWidth * 0.2;
      }
    } else {
      width = context.screenWidth * 0.3;
    }

    if (info.title == "无数据") {
      return SizedBox(width: width);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _navigateToComicInfo(context),
      onLongPress:
          () =>
              type != ComicEntryType.normal ? _showDeleteDialog(context) : null,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            topPadding
                ? SizedBox(height: MediaQuery.of(context).size.width * 0.025)
                : SizedBox.shrink(),
            _buildCoverWithTitle(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverWithTitle(BuildContext context) {
    final isTablet = isTabletWithOutContext();
    final isLandscapes = isLandscape(context);
    double width;
    double height;
    if (isTablet) {
      width = context.screenWidth * 0.2;
      height = (context.screenWidth * 0.2) / 0.75;
      if (isLandscapes) {
        width = context.screenWidth * 0.15;
        height = (context.screenWidth * 0.15) / 0.75;
      }
    } else {
      width = context.screenWidth * 0.3;
      height = (context.screenWidth * 0.3) / 0.75;
    }
    double circular = roundedCorner ? 5.0 : 0.0;
    return Stack(
      children: [
        CoverWidget(
          fileServer: info.fileServer,
          path: info.path,
          id: info.id,
          pictureType: info.pictureType,
          from: info.from,
          roundedCorner: roundedCorner,
          width: width,
          height: height,
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.7],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(circular),
                bottomRight: Radius.circular(circular),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(5.0, 20.0, 5.0, 5.0),
            child: Text(
              info.title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ],
              ),
              maxLines: 3, // 最多显示3行
              overflow: TextOverflow.ellipsis, // 超出部分显示省略号
              textAlign: TextAlign.start, // 文字对齐方式，也可以用 TextAlign.center 居中显示
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToComicInfo(BuildContext context) {
    if (info.from == 'bika') {
      context.pushRoute(ComicInfoRoute(comicId: info.id, type: type));
    }
    if (info.from == 'jm') {
      context.pushRoute(JmComicInfoRoute(comicId: info.id, type: type));
    }
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final (title, content) = _getDialogContent();

    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text("取消"),
              ),
              TextButton(
                onPressed: () {
                  context.router.pop();
                  _handleDeleteAction(context);
                },
                child: const Text("确定"),
              ),
            ],
          ),
    );
  }

  (String, String) _getDialogContent() {
    logger.d(type);
    switch (type) {
      case ComicEntryType.favorite:
        return ("删除收藏", "确定要删除（${info.title}）的收藏记录吗？");
      case ComicEntryType.history:
        return ("删除历史记录", "确定要删除（${info.title}）的历史记录吗？");
      case ComicEntryType.download:
        return ("删除下载记录", "确定要删除（${info.title}）的下载记录及文件吗？");
      default:
        return ("", "");
    }
  }

  Future<void> _handleDeleteAction(BuildContext context) async {
    try {
      if (type == ComicEntryType.history) {
        await _deleteHistory();
      } else if (type == ComicEntryType.download) {
        await _deleteDownload();
      } else if (type == ComicEntryType.favorite) {
        await _deleteFavorite();
      }
      refresh!();
    } catch (e, s) {
      logger.e('删除失败', error: e, stackTrace: s);
      showErrorToast("删除失败");
    }
  }

  Future<void> _deleteHistory() async {
    if (info.from == 'bika') {
      final temp =
          objectbox.bikaHistoryBox
              .query(BikaComicHistory_.comicId.equals(info.id))
              .build()
              .findFirst();

      if (temp != null) {
        temp.deleted = true;
        temp.history = DateTime.now().toUtc();
        objectbox.bikaHistoryBox.put(temp);
      }
    } else if (info.from == 'jm') {
      final temp =
          objectbox.jmHistoryBox
              .query(JmHistory_.comicId.equals(info.id))
              .build()
              .findFirst();

      if (temp != null) {
        temp.deleted = true;
        temp.history = DateTime.now().toUtc();
        objectbox.jmHistoryBox.put(temp);
      }
    }
  }

  Future<void> _deleteDownload() async {
    if (info.from == 'bika') {
      final temp =
          objectbox.bikaDownloadBox
              .query(BikaComicDownload_.comicId.equals(info.id))
              .build()
              .findFirst();

      if (temp != null) {
        objectbox.bikaDownloadBox.remove(temp.id);
        await _deleteDownloadDirectory(info.id);
      }
    } else if (info.from == 'jm') {
      final temp =
          objectbox.jmDownloadBox
              .query(JmDownload_.comicId.equals(info.id))
              .build()
              .findFirst();

      if (temp != null) {
        objectbox.jmDownloadBox.remove(temp.id);
        await _deleteDownloadDirectory(info.id);
      }
    }
  }

  Future<void> _deleteFavorite() async {
    if (info.from == 'bika') {
    } else if (info.from == 'jm') {
      final temp =
          objectbox.jmFavoriteBox
              .query(JmFavorite_.comicId.equals(info.id))
              .build()
              .findFirst();

      if (temp != null) {
        objectbox.jmFavoriteBox.remove(temp.id);
      }
    }
  }

  Future<void> _deleteDownloadDirectory(String id) async {
    final path =
        '/data/data/com.zephyr.breeze/files/downloads/bika/original/$id';
    final directory = Directory(path);

    if (await directory.exists()) {
      try {
        await directory.delete(recursive: true);
        logger.d('目录已成功删除: $path');
      } catch (e) {
        logger.e('删除目录时发生错误: $e');
        throw Exception('删除目录失败');
      }
    }
  }
}

/// [context] 用于获取屏幕方向和尺寸。
/// [list] 是原始的数据列表。
List<List<ComicSimplifyEntryInfo>> generateResponsiveRows(
  BuildContext context,
  List<ComicSimplifyEntryInfo> list,
) {
  // 1. 根据 context 动态获取每行的项目数
  final int itemCount = _getCrossAxisCount(context);

  // 2. 填充占位符
  final filledList = _fillListWithPlaceholders(list, itemCount);

  // 3. 将列表分割成行
  return _chunkList(filledList, itemCount);
}

/// 根据上下文获取每行的项目数 (crossAxisCount)。
int _getCrossAxisCount(BuildContext context) {
  final orientation = MediaQuery.of(context).orientation;
  if (isTablet(context)) {
    return (orientation == Orientation.landscape) ? 5 : 4;
  } else {
    return 3;
  }
}

/// 用占位符填充列表，确保最后一行是满的。
List<ComicSimplifyEntryInfo> _fillListWithPlaceholders(
  List<ComicSimplifyEntryInfo> list,
  int itemCountPerRow,
) {
  final remainder = list.length % itemCountPerRow;
  if (remainder == 0) return List.from(list);

  final placeholderCount = itemCountPerRow - remainder;
  final placeholders = List.generate(
    placeholderCount,
    (_) => _createPlaceholder(),
  );

  return [...list, ...placeholders];
}

/// 创建一个用于UI占位的条目。
ComicSimplifyEntryInfo _createPlaceholder() {
  return ComicSimplifyEntryInfo(
    title: '无数据', // 特殊标题，用于UI判断
    id: const Uuid().v4(),
    fileServer: '',
    path: '',
    pictureType: '',
    from: '',
  );
}

/// 将一个长列表分割成一个包含多个子列表的列表。
List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
  return List.generate(
    (list.length / chunkSize).ceil(),
    (index) => list.sublist(
      index * chunkSize,
      (index + 1) * chunkSize > list.length
          ? list.length
          : (index + 1) * chunkSize,
    ),
  );
}
