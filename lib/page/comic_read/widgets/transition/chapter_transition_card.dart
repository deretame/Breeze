import 'package:flutter/material.dart';
import 'package:zephyr/page/comic_read/model/seamless_transition_state.dart';

class ChapterTransitionCard extends StatelessWidget {
  const ChapterTransitionCard({
    super.key,
    required this.previousChapterOrder,
    required this.previousChapterTitle,
    required this.nextChapterOrder,
    required this.nextChapterTitle,
    required this.transitionStatus,
    required this.onTap,
    required this.backgroundColor,
    this.minHeight = 320,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
    this.titleMaxLines = 2,
    this.lineSpacing = 34,
  });

  final int? previousChapterOrder;
  final String? previousChapterTitle;
  final int nextChapterOrder;
  final String nextChapterTitle;
  final SeamlessTransitionStatus transitionStatus;
  final VoidCallback onTap;
  final Color backgroundColor;
  final double minHeight;
  final EdgeInsetsGeometry padding;
  final int titleMaxLines;
  final double lineSpacing;

  @override
  Widget build(BuildContext context) {
    final isDarkBackground =
        ThemeData.estimateBrightnessForColor(backgroundColor) ==
        Brightness.dark;
    final primaryTextColor = isDarkBackground ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkBackground
        ? Colors.white.withValues(alpha: 0.78)
        : Colors.black.withValues(alpha: 0.72);
    final previousTitle = (previousChapterTitle ?? '').trim().isEmpty
        ? '章节 ${previousChapterOrder ?? '--'}'
        : previousChapterTitle!;
    final currentTitle = nextChapterTitle.trim().isEmpty
        ? '章节 $nextChapterOrder'
        : nextChapterTitle;
    final statusMeta = _resolveStatusMeta(
      transitionStatus,
      indicatorColor: secondaryTextColor,
    );

    return GestureDetector(
      onTap: statusMeta.canTap ? onTap : null,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: minHeight),
        padding: padding,
        alignment: Alignment.center,
        child: IconTheme(
          data: IconThemeData(color: secondaryTextColor, size: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                previousTitle,
                textAlign: TextAlign.center,
                maxLines: titleMaxLines,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: secondaryTextColor,
                ),
              ),
              SizedBox(height: lineSpacing),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (statusMeta.leading != null) ...[
                    statusMeta.leading!,
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Text(
                      statusMeta.message,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        color: primaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: lineSpacing),
              Text(
                currentTitle,
                textAlign: TextAlign.center,
                maxLines: titleMaxLines,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: primaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _TransitionStatusMeta _resolveStatusMeta(
    SeamlessTransitionStatus status, {
    required Color indicatorColor,
  }) {
    switch (status) {
      case SeamlessTransitionStatus.hidden:
        return const _TransitionStatusMeta(
          message: '继续翻页加载',
          canTap: true,
          leading: Icon(Icons.arrow_forward, size: 16),
        );
      case SeamlessTransitionStatus.loading:
        return _TransitionStatusMeta(
          message: '正在加载...',
          canTap: false,
          leading: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
            ),
          ),
        );
      case SeamlessTransitionStatus.ready:
        return const _TransitionStatusMeta(
          message: '加载完成',
          canTap: false,
          leading: Icon(Icons.check_circle_outline, size: 16),
        );
      case SeamlessTransitionStatus.error:
        return const _TransitionStatusMeta(
          message: '加载失败，点击重试',
          canTap: true,
          leading: Icon(Icons.refresh, size: 16),
        );
    }
  }
}

class _TransitionStatusMeta {
  const _TransitionStatusMeta({
    required this.message,
    required this.canTap,
    required this.leading,
  });

  final String message;
  final bool canTap;
  final Widget? leading;
}
