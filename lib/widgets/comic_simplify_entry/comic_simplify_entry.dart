import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/widgets/toast.dart';

import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/config/router/router.gr.dart';
import 'package:zephyr/util/text/chinese_convert.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_info.dart';
import 'package:zephyr/widgets/comic_simplify_entry/cover.dart';

const double kComicCardBorderRadius = 5.0;

class ComicFixedSizeHorizontalList extends StatelessWidget {
  final List<ComicSimplifyEntryInfo> entries;
  final double spacing; // 卡片之间的横向间距
  final double itemWidth; // 卡片固定宽度
  final bool roundedCorner; // 是否有圆角
  final bool useRandomImageKey;

  const ComicFixedSizeHorizontalList({
    super.key,
    required this.entries,
    this.spacing = 10.0, // 默认间距设为 10
    this.itemWidth = 200, // 固定宽度，不随窗口宽高比变化
    this.roundedCorner = true,
    this.useRandomImageKey = false,
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
                child: _buildCoverWithTitle(
                  info,
                  itemWidth,
                  itemHeight,
                  useRandomImageKey
                      ? ValueKey('cover-${const Uuid().v4()}')
                      : ValueKey('cover-${info.from}:${info.id}:${info.path}'),
                ),
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
    Key coverKey,
  ) {
    final circular = roundedCorner ? kComicCardBorderRadius : 0.0;
    return Stack(
      children: [
        // 1. 底层封面图
        CoverWidget(
          key: coverKey,
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
              info.title.let(convertChineseForDisplay),
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
    final pluginId = (info.source.trim().isNotEmpty ? info.source : info.from)
        .trim();
    if (pluginId.isEmpty) return;
    context.pushRoute(
      ComicInfoRoute(
        comicId: info.id,
        type: ComicEntryType.normal,
        from: pluginId,
      ),
    );
  }
}

class ComicSimplifyEntry extends StatelessWidget {
  final ComicSimplifyEntryInfo info;
  final ComicEntryType type;
  final VoidCallback? refresh;
  final ValueChanged<String>? onDeleteSuccess;
  final ValueChanged<ComicSimplifyEntryInfo>? onTapOverride;
  final void Function(
    ComicSimplifyEntryInfo info,
    LongPressStartDetails details,
  )?
  onLongPressOverride;
  final void Function(ComicSimplifyEntryInfo info, TapDownDetails details)?
  onSecondaryTapDown;
  final bool isSelected;
  final bool selectionMode;
  final bool topPadding;
  final bool roundedCorner;
  final String? collectionTargetId;
  final String? collectionTargetName;
  final bool detailed;

  const ComicSimplifyEntry({
    super.key,
    required this.info,
    required this.type,
    this.refresh,
    this.onDeleteSuccess,
    this.onTapOverride,
    this.onLongPressOverride,
    this.onSecondaryTapDown,
    this.isSelected = false,
    this.selectionMode = false,
    this.topPadding = true,
    this.roundedCorner = true,
    this.detailed = false,
    this.collectionTargetId,
    this.collectionTargetName,
  });

  @override
  Widget build(BuildContext context) {
    if (info.title == "无数据") {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            final onTapHandler = onTapOverride;
            if (onTapHandler != null) {
              onTapHandler(info);
              return;
            }
            _navigateToComicInfo(context);
          },
          onLongPressStart: (details) {
            final onLongPressHandler = onLongPressOverride;
            if (onLongPressHandler != null) {
              onLongPressHandler(info, details);
              return;
            }
            if (type != ComicEntryType.normal) {
              _showDeleteDialog(context);
            }
          },
          onSecondaryTapDown: (details) {
            onSecondaryTapDown?.call(info, details);
          },
          child: detailed
              ? _buildDetailedRow(context, constraints.maxWidth)
              : _buildCoverGrid(context, constraints.maxWidth),
        );
      },
    );
  }

  Widget _buildCoverGrid(BuildContext context, double width) {
    final height = width / 0.75;
    return SizedBox(
      width: width,
      height: height,
      child: _buildCoverWithTitle(context, width, height),
    );
  }

  Widget _buildDetailedRow(BuildContext context, double width) {
    // 无 Tooltip：移动端长按会先弹 Tooltip 再弹菜单，跟网格模式行为对不齐；
    // 标题本来就是 1 行省略，桌面端不需要悬浮提示。
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: _DetailedRowBody(
        info: info,
        width: width,
        isSelected: isSelected,
        selectionMode: selectionMode,
      ),
    );
  }

  Widget _buildCoverWithTitle(
    BuildContext context,
    double width,
    double height,
  ) {
    final circular = roundedCorner ? kComicCardBorderRadius : 0.0;
    final primary = Theme.of(context).colorScheme.primary;
    return ClipRRect(
      borderRadius: BorderRadius.circular(circular),
      // 选中边框常驻（透明/主色切换）+ 隐式动画：进入多选模式时边框层
      // 本来就存在，只是颜色从透明变过来，不会出现整表同时弹边框的闪。
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        foregroundDecoration: BoxDecoration(
          border: Border.all(
            color: isSelected && selectionMode ? primary : Colors.transparent,
            width: 4,
          ),
          borderRadius: BorderRadius.circular(circular),
        ),
        child: Stack(
          children: [
            CoverWidget(
              fileServer: info.fileServer,
              path: info.path,
              id: info.id,
              pictureType: info.pictureType,
              from: info.from,
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
                  info.title.let(convertChineseForDisplay),
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
                  textAlign:
                      TextAlign.start, // 文字对齐方式，也可以用 TextAlign.center 居中显示
                ),
              ),
            ),
            // 徽章常驻，用缩放+淡出控制显隐：进入多选模式时所有徽章
            // 同时淡入，比凭空 if 出来少一次整表闪。
            Positioned(
              top: 8,
              right: 8,
              child: AnimatedScale(
                scale: selectionMode ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: selectionMode ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOutCubic,
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isSelected ? primary : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black87,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      child: Icon(
                        isSelected ? Icons.check : Icons.radio_button_unchecked,
                        key: ValueKey(isSelected),
                        color: isSelected ? Colors.white : Colors.black54,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToComicInfo(BuildContext context) {
    final pluginId = (info.source.trim().isNotEmpty ? info.source : info.from)
        .trim();
    if (pluginId.isEmpty) return;
    context.pushRoute(
      ComicInfoRoute(
        comicId: info.id,
        type: type,
        from: pluginId,
        collectionTargetId: collectionTargetId,
        collectionTargetName: collectionTargetName,
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final (title, content) = _getDialogContent();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(t.common.cancel),
          ),
          TextButton(
            onPressed: () {
              context.router.pop();
              _handleDeleteAction(context);
            },
            child: Text(t.common.confirm),
          ),
        ],
      ),
    );
  }

  (String, String) _getDialogContent() {
    logger.d(type);
    switch (type) {
      case ComicEntryType.favorite:
        return (
          t.comicEntry.deleteFavorite,
          t.comicEntry.deleteFavoriteConfirm(
            title: info.title.let(convertChineseForDisplay),
          ),
        );
      case ComicEntryType.history:
        return (
          t.comicEntry.deleteHistory,
          t.comicEntry.deleteHistoryConfirm(
            title: info.title.let(convertChineseForDisplay),
          ),
        );
      case ComicEntryType.download:
        return (
          t.comicEntry.deleteDownload,
          t.comicEntry.deleteDownloadConfirm(
            title: info.title.let(convertChineseForDisplay),
          ),
        );
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
      final deletedKey = '${info.from.trim()}:${info.id}';
      if (onDeleteSuccess != null) {
        onDeleteSuccess!(deletedKey);
      } else {
        refresh?.call();
      }
    } catch (e, s) {
      logger.e('删除失败', error: e, stackTrace: s);
      showErrorToast(t.comicEntry.deleteFailed);
    }
  }

  Future<void> _deleteHistory() async {
    final uniqueKey = '${info.from.trim()}:${info.id}';
    final temp = objectbox.unifiedHistoryBox
        .query(UnifiedComicHistory_.uniqueKey.equals(uniqueKey))
        .build()
        .findFirst();

    if (temp != null) {
      temp.deleted = true;
      temp.updatedAt = DateTime.now().toUtc();
      objectbox.unifiedHistoryBox.put(temp);
    }
  }

  Future<void> _deleteDownload() async {
    final uniqueKey = '${info.from.trim()}:${info.id}';
    final temp = objectbox.unifiedDownloadBox
        .query(UnifiedComicDownload_.uniqueKey.equals(uniqueKey))
        .build()
        .findFirst();

    if (temp != null) {
      objectbox.unifiedDownloadBox.remove(temp.id);
      await _deleteDownloadDirectory(info.id);
    }
  }

  Future<void> _deleteFavorite() async {
    final uniqueKey = '${info.from.trim()}:${info.id}';
    final temp = objectbox.unifiedFavoriteBox
        .query(UnifiedComicFavorite_.uniqueKey.equals(uniqueKey))
        .build()
        .findFirst();

    if (temp != null) {
      temp.deleted = true;
      temp.updatedAt = DateTime.now().toUtc();
      objectbox.unifiedFavoriteBox.put(temp);
    }
  }

  Future<void> _deleteDownloadDirectory(String id) async {
    try {
      await deleteComicDownloadDirectory(info.from, id);
      logger.d('目录已成功删除: $id');
    } catch (e) {
      logger.e('删除目录时发生错误: $e');
      throw Exception('删除目录失败');
    }
  }
}

class _DetailedRowBody extends StatelessWidget {
  const _DetailedRowBody({
    required this.info,
    required this.width,
    required this.isSelected,
    required this.selectionMode,
  });

  final ComicSimplifyEntryInfo info;
  final double width;
  final bool isSelected;
  final bool selectionMode;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    final titleStyle = Theme.of(
      context,
    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, height: 1.3);
    final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
      height: 1.4,
    );
    // Venera 式简洁风：透明底、无边框；hover 只给一层极淡底色。
    final pills = info.metadata
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .take(3)
        .toList();
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width > kDetailRowMaxWidth ? kDetailRowMaxWidth : width,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
          ),
          // 选中边框常驻（透明/主色切换）+ 隐式动画：进入多选模式时
          // 边框层本来就存在，只是颜色从透明变过来，不闪。
          foregroundDecoration: BoxDecoration(
            border: Border.all(
              color: isSelected && selectionMode ? primary : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CoverWidget(
                  fileServer: info.fileServer,
                  path: info.path,
                  id: info.id,
                  pictureType: info.pictureType,
                  from: info.from,
                  roundedCorner: false,
                  width: 114,
                  height: 153,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.title.let(convertChineseForDisplay),
                      style: titleStyle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (info.author.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        info.author.let(convertChineseForDisplay),
                        style: subtitleStyle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (pills.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final pill in pills) _DetailPill(label: pill),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 状态/分类小胶囊：淡底 + 主色文字，Venera 式。
class _DetailPill extends StatelessWidget {
  const _DetailPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.let(convertChineseForDisplay),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onSecondaryContainer,
          height: 1.4,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
