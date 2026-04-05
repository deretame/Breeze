import 'package:flutter/material.dart';
import 'package:zephyr/page/download/models/unified_comic_download.dart';

class EpsWidget extends StatefulWidget {
  final UnifiedComicDownloadChapter chapter;
  final bool downloaded;
  final Function(int order) onUpdateDownloadInfo; // 用来更新观看按钮信息

  const EpsWidget({
    super.key,
    required this.chapter,
    required this.downloaded,
    required this.onUpdateDownloadInfo,
  });

  @override
  State<EpsWidget> createState() => _EpsWidgetState();
}

class _EpsWidgetState extends State<EpsWidget> {
  bool _isChecked = false; // 复选框状态

  @override
  void initState() {
    super.initState();
    _isChecked = widget.downloaded; // 初始化复选框状态
  }

  @override
  void didUpdateWidget(EpsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.downloaded != widget.downloaded) {
      setState(() => _isChecked = widget.downloaded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isChecked = _isChecked;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        widget.onUpdateDownloadInfo(widget.chapter.order);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isChecked
              ? colorScheme.primaryContainer.withValues(alpha: 0.3)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isChecked
                ? colorScheme.primary.withValues(alpha: 0.5)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(
              isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isChecked
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                widget.chapter.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isChecked ? FontWeight.w600 : FontWeight.w500,
                  color: isChecked
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
