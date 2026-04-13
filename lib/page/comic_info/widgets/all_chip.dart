// 通用的标签/分类 Widget
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart';
import 'package:zephyr/page/comic_info/models/comic_info_action.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/desktop/window_logic.dart';
import 'package:zephyr/util/sundry.dart';
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
                  processText(title).let(t2s),
                  style: TextStyle(fontSize: 12, color: context.textColor),
                ),
              );
            }
            final item = items[index - 1];
            return GestureDetector(
              onTap: () => _onTap(index, item),
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: processText(item.name)));
                showSuccessToast("已将${item.name.let(t2s)}复制到剪贴板");
              },
              child: Chip(
                backgroundColor: context.backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                label: Text(
                  processText(item.name).let(t2s),
                  style: TextStyle(
                    fontSize: 12,
                    color: context.theme.colorScheme.primary,
                  ),
                ),
              ),
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

  void _onTap(int index, ComicInfoActionItem item) {
    if (item.onTap.isNotEmpty) {
      handleComicInfoAction(context, item.onTap, fallbackPluginId: widget.from);
    }
  }
}
