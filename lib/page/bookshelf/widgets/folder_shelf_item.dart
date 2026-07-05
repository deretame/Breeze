import 'package:flutter/material.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/sundry.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry.dart'
    show kComicCardBorderRadius;

class FolderShelfItem extends StatelessWidget {
  const FolderShelfItem({
    super.key,
    required this.folder,
    this.onTap,
    this.onLongPress,
    this.selectionMode = false,
    this.isSelected = false,
  });

  final ComicFolder folder;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selectionMode;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = width / 0.75;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          onLongPress: onLongPress,
          child: SizedBox(
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
                      colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      ),
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
                    // 选择指示器
                    if (selectionMode)
                      Positioned(
                        top: 8,
                        right: 8,
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
                          child: Icon(
                            isSelected
                                ? Icons.check_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: isSelected
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant,
                            size: 18,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
