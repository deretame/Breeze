// 通用的标签/分类 Widget
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart';
import 'package:zephyr/page/comic_info/models/comic_info_action.dart';
import 'package:zephyr/platform/desktop/window_logic.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/text/chinese_convert.dart';
import 'package:zephyr/widgets/toast.dart';

class AllChipWidget extends StatefulWidget {
  final String comicId;
  final ComicInfoMetadata metadata;
  final String from;

  const AllChipWidget({
    super.key,
    required this.comicId,
    required this.metadata,
    required this.from,
  });

  @override
  State<AllChipWidget> createState() => _AllChipWidgetState();
}

class _AllChipWidgetState extends State<AllChipWidget> {
  List<ComicInfoActionItem> get items => widget.metadata.value;
  String get title => widget.metadata.name;

  @override
  Widget build(BuildContext context) {
    final runSpacings = isDesktop ? 5.0 : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: runSpacings),
        Wrap(
          spacing: 10,
          runSpacing: runSpacings,
          children: List.generate(items.length + 1, (index) {
            if (index == 0) {
              return Chip(
                backgroundColor: context.backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                side: BorderSide(color: context.textColor),
                label: Text(
                  processText(title).let(convertChineseForDisplay),
                  style: TextStyle(fontSize: 12, color: context.textColor),
                ),
              );
            }
            final item = items[index - 1];
            return _ClickableChip(
              label: processText(item.name).let(convertChineseForDisplay),
              onTap: () => _onTap(item),
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: processText(item.name)));
                showSuccessToast(
                  t.comicInfo.copiedToClipboard(
                    name: item.name.let(convertChineseForDisplay),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  String processText(String text) {
    if (text.contains('\r')) {
      text = text.replaceAll('\r', '');
    }

    if (text.contains(' ')) {
      text = text.replaceAll(' ', '');
    }

    return text;
  }

  void _onTap(ComicInfoActionItem item) {
    if (item.onTap.isNotEmpty) {
      handleComicInfoAction(context, item.onTap, fallbackPluginId: widget.from);
    }
  }
}

class _ClickableChip extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ClickableChip({
    required this.label,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<_ClickableChip> createState() => _ClickableChipState();
}

class _ClickableChipState extends State<_ClickableChip> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final primary = context.theme.colorScheme.primary;
    final background = context.backgroundColor;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: _hovering ? primary.withValues(alpha: 0.08) : background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: primary.withValues(alpha: _hovering ? 0.9 : 0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: context.textColor.withValues(
                  alpha: _hovering ? 0.28 : 0.18,
                ),
                blurRadius: _hovering ? 10 : 6,
                offset: Offset(0, _hovering ? 3 : 2),
                spreadRadius: _hovering ? 0.5 : 0,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            widget.label,
            style: TextStyle(fontSize: 12, color: primary),
          ),
        ),
      ),
    );
  }
}
