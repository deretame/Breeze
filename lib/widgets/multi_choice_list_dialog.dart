import 'package:flutter/material.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/sundry.dart';

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
  String cancelText = '取消',
  String confirmText = '确定',
  bool useFilledConfirmButton = false,
  double width = 520,
  double height = 420,
}) {
  final selected = Set<String>.from(initialSelected);
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
                thumbVisibility: true,
                child: ListView.builder(
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
                        option.label.let(t2s),
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
                child: Text(cancelText),
              ),
              if (useFilledConfirmButton)
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(selected),
                  child: Text(confirmText),
                )
              else
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(selected),
                  child: Text(confirmText),
                ),
            ],
          );
        },
      );
    },
  );
}
