import 'package:flutter/material.dart';
import 'package:zephyr/i18n/strings.g.dart';

Future<Map<String, bool>?> showSourceSelectDialog(
  BuildContext context, {
  required Map<String, bool> initial,
  required List<({String pluginId, String title})> sourceOptions,
}) {
  final next = Map<String, bool>.from(initial);
  return showDialog<Map<String, bool>>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(t.search.selectSource),
            content: SizedBox(
              width: 320,
              child: Wrap(
                alignment: WrapAlignment.start,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final source in sourceOptions)
                    FilterChip(
                      showCheckmark: false,
                      label: Text(source.title),
                      selected: next[source.pluginId] ?? true,
                      onSelected: (selected) {
                        setState(() {
                          next[source.pluginId] = selected;
                        });
                      },
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(t.common.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(next),
                child: Text(t.common.apply),
              ),
            ],
          );
        },
      );
    },
  );
}
