import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:zephyr/widgets/toast.dart';

import '../../main.dart';
import '../../object_box/objectbox.g.dart';
import '../../type/enum.dart';
import '../../util/router/router.gr.dart';
import 'comic_simplify_entry_info.dart';
import 'cover.dart';

class ComicFixedSizeHorizontalList extends StatelessWidget {
  final List<ComicSimplifyEntryInfo> entries;
  final double spacing; // 卡片之间的横向间距
  final double itemWidth; // 卡片固定宽度
  final bool roundedCorner; // 是否有圆角

  const ComicFixedSizeHorizontalList({
    super.key,
    required this.entries,
    this.spacing = 10.0, // 默认间距设为 10
    this.itemWidth = 200, // 固定宽度，不随窗口宽高比变化
    this.roundedCorner = true,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    // 使用固定的宽高，避免在 Windows 桌面端拖动窗口时因
    // MediaQuery.orientation 随宽高比切换而导致高度跳变
    final double itemHeight = itemWidth / 0.75;

    // 最外层需要限制高度，否则横向 ListView 会报错
    return SizedBox(
      height: itemHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final info = entries[index];

          // 过滤无数据的情况
          if (info.title == "无数据") {
            return const SizedBox.shrink();
          }

          return Padding(
            padding: EdgeInsets.only(right: spacing),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _navigateToComicInfo(context, info),
              child: SizedBox(
                width: itemWidth,
                height: itemHeight,
                child: _buildCoverWithTitle(info, itemWidth, itemHeight),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCoverWithTitle(
    ComicSimplifyEntryInfo info,
    double width,
    double height,
  ) {
    double circular = roundedCorner ? 5.0 : 0.0;
    return Stack(
      children: [
        // 1. 底层封面图
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

        // 2. 顶部阴影与标题
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
                stops: const [0.0, 0.7],
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
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
            ),
          ),
        ),
      ],
    );
  }

  // 点击跳转逻辑 (需要把当前的 info 传进来)
  void _navigateToComicInfo(BuildContext context, ComicSimplifyEntryInfo info) {
    if (info.from == From.bika) {
      context.pushRoute(
        ComicInfoRoute(
          comicId: info.id,
          type: ComicEntryType.normal,
          from: From.bika,
        ),
      );
    } else if (info.from == From.jm) {
      context.pushRoute(
        ComicInfoRoute(
          comicId: info.id,
          type: ComicEntryType.normal,
          from: From.jm,
        ),
      );
    }
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
    if (info.title == "无数据") {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = width / 0.75;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _navigateToComicInfo(context),
          onLongPress: () =>
              type != ComicEntryType.normal ? _showDeleteDialog(context) : null,
          child: SizedBox(
            width: width,
            height: height,
            child: _buildCoverWithTitle(width, height),
          ),
        );
      },
    );
  }

  Widget _buildCoverWithTitle(double width, double height) {
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
    if (info.from == From.bika) {
      context.pushRoute(
        ComicInfoRoute(comicId: info.id, type: type, from: From.bika),
      );
    }
    if (info.from == From.jm) {
      context.pushRoute(
        ComicInfoRoute(comicId: info.id, type: type, from: From.jm),
      );
    }
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final (title, content) = _getDialogContent();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text("取消")),
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
    if (info.from == From.bika) {
      final temp = objectbox.bikaHistoryBox
          .query(BikaComicHistory_.comicId.equals(info.id))
          .build()
          .findFirst();

      if (temp != null) {
        temp.deleted = true;
        temp.history = DateTime.now().toUtc();
        objectbox.bikaHistoryBox.put(temp);
      }
    } else if (info.from == From.jm) {
      final temp = objectbox.jmHistoryBox
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
    if (info.from == From.bika) {
      final temp = objectbox.bikaDownloadBox
          .query(BikaComicDownload_.comicId.equals(info.id))
          .build()
          .findFirst();

      if (temp != null) {
        objectbox.bikaDownloadBox.remove(temp.id);
        await _deleteDownloadDirectory(info.id);
      }
    } else if (info.from == From.jm) {
      final temp = objectbox.jmDownloadBox
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
    if (info.from == From.bika) {
    } else if (info.from == From.jm) {
      final temp = objectbox.jmFavoriteBox
          .query(JmFavorite_.comicId.equals(info.id))
          .build()
          .findFirst();

      if (temp != null) {
        objectbox.jmFavoriteBox.remove(temp.id);
      }
    }
  }

  Future<void> _deleteDownloadDirectory(String id) async {
    final path = p.join(
      '/data/data/com.zephyr.breeze/files/downloads/bika/original',
      id,
    );
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
