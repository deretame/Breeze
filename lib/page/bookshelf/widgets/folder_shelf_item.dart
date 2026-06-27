import 'package:flutter/material.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/sundry.dart';

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
        final circular = 5.0;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          onLongPress: onLongPress,
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              children: [
                // 文件夹背景
                Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(circular),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.2),
                      width: isSelected ? 4 : 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.folder_rounded,
                      size: width * 0.45,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                // 选择指示器
                if (selectionMode)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white,
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
                      child: Icon(
                        isSelected ? Icons.check : Icons.radio_button_unchecked,
                        color: isSelected ? Colors.white : Colors.black54,
                        size: 20,
                      ),
                    ),
                  ),
                // 底部标题阴影
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
                      folder.name.let(convertChineseForDisplay),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 2,
                            color: Colors.black54,
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
            ),
          ),
        );
      },
    );
  }
}
