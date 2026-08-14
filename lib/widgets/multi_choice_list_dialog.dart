import 'package:flutter/material.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/text/chinese_convert.dart';

class MultiChoiceDialogOption {
  const MultiChoiceDialogOption({required this.label, required this.value});

  final String label;
  final String value;
}

Future<Set<String>?> showMultiChoiceListDialog(
  BuildContext context, {
  required String title,
  required List<MultiChoiceDialogOption> options,
  Iterable<String> initialSelected = const <String>[],
  String? cancelText,
  String? confirmText,
  bool useFilledConfirmButton = false,
  double width = 520,
  double height = 420,
}) {
  final selected = Set<String>.from(initialSelected);
  // Scrollbar 和 ListView 必须共用同一个 controller，否则在 Dialog 上下文
  // （无 PrimaryScrollController 时）它们会各自建 controller，导致 Scrollbar
  // 的 controller 没有 ScrollPosition 附着，抛
  // "The Scrollbar's ScrollController has no ScrollPosition attached"。
  final scrollController = ScrollController();
  return showDialog<Set<String>>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: width,
              height: height,
              child: Scrollbar(
                controller: scrollController,
                thumbVisibility: true,
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = selected.contains(option.value);
                    return CheckboxListTile(
                      key: ValueKey(option.value),
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: isSelected,
                      title: Text(
                        option.label.let(convertChineseForDisplay),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            selected.add(option.value);
                          } else {
                            selected.remove(option.value);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(cancelText ?? t.common.cancel),
              ),
              if (useFilledConfirmButton)
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(selected),
                  child: Text(confirmText ?? t.common.ok),
                )
              else
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(selected),
                  child: Text(confirmText ?? t.common.ok),
                ),
            ],
          );
        },
      );
    },
    // dialog 关闭后释放 controller
  ).whenComplete(scrollController.dispose);
}
