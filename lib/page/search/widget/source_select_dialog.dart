import 'package:flutter/material.dart';
import 'package:zephyr/type/enum.dart';

Future<Map<From, bool>?> showSourceSelectDialog(
  BuildContext context, {
  required Map<From, bool> initial,
}) {
  final next = Map<From, bool>.from(initial);
  return showDialog<Map<From, bool>>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('选择漫画源'),
            content: SizedBox(
              width: 320,
              child: Wrap(
                alignment: WrapAlignment.start,
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    showCheckmark: false,
                    label: const Text('禁漫'),
                    selected: next[From.jm] ?? true,
                    onSelected: (selected) {
                      setState(() {
                        next[From.jm] = selected;
                      });
                    },
                  ),
                  FilterChip(
                    showCheckmark: false,
                    label: const Text('哔咔'),
                    selected: next[From.bika] ?? true,
                    onSelected: (selected) {
                      setState(() {
                        next[From.bika] = selected;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(next),
                child: const Text('应用'),
              ),
            ],
          );
        },
      );
    },
  );
}
