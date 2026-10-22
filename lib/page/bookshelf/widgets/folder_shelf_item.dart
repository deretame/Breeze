import 'package:material_ui/material_ui.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/text/chinese_convert.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry.dart'
    show kComicCardBorderRadius;
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_info.dart';

class FolderShelfItem extends StatelessWidget {
  const FolderShelfItem({
    super.key,
    required this.folder,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTapDown,
    this.selectionMode = false,
    this.isSelected = false,
    this.detailed = false,
    this.comicCount,
  });

  final ComicFolder folder;
  final VoidCallback? onTap;
  final GestureLongPressStartCallback? onLongPress;
  final GestureTapDownCallback? onSecondaryTapDown;
  final bool selectionMode;
  final bool isSelected;

  /// 详情模式：横行样式，对齐漫画详情行（圆角 8、底色、小图标+标题+数量）。
  final bool detailed;

  /// 文件夹直属漫画数；null 时不显示数量行。
  final int? comicCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          onLongPressStart: onLongPress,
          onSecondaryTapDown: onSecondaryTapDown,
          child: detailed
              ? _buildDetailedRow(context, constraints.maxWidth)
              : _buildGridCard(context, constraints.maxWidth),
        );
      },
    );
  }

  /// 网格卡片：固定宽高比，宽 = 列宽、高 = 宽 / 0.75。
  Widget _buildGridCard(BuildContext context, double width) {
    final height = width / 0.75;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: width,
      height: height,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: isSelected ? 4 : 2,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kComicCardBorderRadius),
          side: isSelected
              ? BorderSide(color: colorScheme.primary, width: 2.5)
              : BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.12),
                  width: 1,
                ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kComicCardBorderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                isSelected
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.7,
                      ),
                colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 文件夹图标
              Center(
                child: Icon(
                  Icons.folder_rounded,
                  size: width * 0.42,
                  color: colorScheme.primary.withValues(alpha: 0.72),
                ),
              ),
              // 底部标题渐变遮罩
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.68),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.75],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(kComicCardBorderRadius),
                      bottomRight: Radius.circular(kComicCardBorderRadius),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
                  child: Text(
                    folder.name.let(convertChineseForDisplay),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                  ),
                ),
              ),
              // 选择指示器：常驻 + 缩放淡入，进入多选模式时不凭空弹出。
              Positioned(
                top: 8,
                right: 8,
                child: AnimatedScale(
                  scale: selectionMode ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  child: AnimatedOpacity(
                    opacity: selectionMode ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.surface,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Icon(
                          isSelected
                              ? Icons.check_rounded
                              : Icons.radio_button_unchecked_rounded,
                          key: ValueKey(isSelected),
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 详情横行：固定高度 76，与漫画行同高；超宽居中限 720。
  ///
  /// 样式对齐 `_DetailedRowBody`（同圆角 8、同底色、同标题字号），
  /// 左侧用文件夹小图标代替封面，避免单列下大卡片被拉成巨型方块。
  Widget _buildDetailedRow(BuildContext context, double width) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    final count = comicCount;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: folder.name.let(convertChineseForDisplay),
        waitDuration: const Duration(milliseconds: 500),
        child: Center(
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
              foregroundDecoration: BoxDecoration(
                border: Border.all(
                  color: isSelected && selectionMode
                      ? primary
                      : Colors.transparent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SizedBox(
                height: 64,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 64,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.folder_rounded,
                        size: 28,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            folder.name.let(convertChineseForDisplay),
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (count != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              t.bookshelf.folderComicCount(count: count),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    height: 1.4,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // 右侧常驻 30 宽：选择模式徽章 / 普通模式箭头交叉淡入淡出，
                    // 进入多选模式时不跳变。
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 160),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeOutCubic,
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              );
                            },
                        layoutBuilder:
                            (
                              Widget? currentChild,
                              List<Widget> previousChildren,
                            ) {
                              return Stack(
                                alignment: Alignment.center,
                                children: <Widget>[
                                  ...previousChildren,
                                  ?currentChild,
                                ],
                              );
                            },
                        child: selectionMode
                            ? AnimatedContainer(
                                key: const ValueKey('badge'),
                                duration: const Duration(milliseconds: 160),
                                curve: Curves.easeOutCubic,
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: isSelected ? primary : scheme.surface,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? primary
                                        : scheme.outline.withValues(alpha: 0.4),
                                    width: 2,
                                  ),
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 160),
                                  child: Icon(
                                    isSelected
                                        ? Icons.check
                                        : Icons.radio_button_unchecked,
                                    key: ValueKey(isSelected),
                                    color: isSelected
                                        ? scheme.onPrimary
                                        : scheme.onSurfaceVariant,
                                    size: 20,
                                  ),
                                ),
                              )
                            : Icon(
                                key: const ValueKey('arrow'),
                                Icons.chevron_right_rounded,
                                color: scheme.onSurfaceVariant.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
