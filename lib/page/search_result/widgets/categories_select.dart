import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/sundry.dart';

Future<Map<String, bool>?> showCategoryDialog(
  BuildContext context,
  Map<String, bool> initialMap,
) {
  final Map<String, bool> tempMap = Map<String, bool>.from(initialMap);

  return showDialog<Map<String, bool>>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('选择分类'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SizedBox(
              width: context.screenWidth * 0.8,
              height: context.screenHeight * 0.6,
              child: ListView(
                children: [
                  for (final entry in tempMap.entries)
                    CheckboxListTile(
                      title: Text(entry.key.let(t2s)),
                      value: entry.value,
                      onChanged: (bool? newValue) {
                        setState(() {
                          tempMap[entry.key] = newValue ?? false;
                        });
                      },
                    ),
                ],
              ),
            );
          },
        ),
        actions: <Widget>[
          TextButton(child: const Text('取消'), onPressed: () => context.pop()),
          TextButton(
            child: const Text('确定'),
            onPressed: () => context.pop(tempMap),
          ),
        ],
      );
    },
  );
}
