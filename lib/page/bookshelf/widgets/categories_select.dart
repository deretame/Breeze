import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/sundry.dart';

import '../../../config/bika/bika_setting.dart';
import '../../../main.dart';

Future<Map<String, bool>?> showCategoryDialog(
  BuildContext context,
  SearchStatusStore searchStatusStore,
) {
  Map<String, bool> categoriesMap = Map.from(categoryMap);
  for (String category in searchStatusStore.categories) {
    if (categoriesMap.containsKey(category)) {
      categoriesMap[category] = true;
    }
  }

  return showDialog<Map<String, bool>>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('选择分类'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            List<Widget> checkboxes = [];
            categoriesMap.forEach((key, value) {
              checkboxes.add(
                CheckboxListTile(
                  title: Text(key.let(t2s)),
                  value: categoriesMap[key],
                  onChanged: (bool? newValue) {
                    setState(() {
                      categoriesMap[key] = newValue!;
                    });
                  },
                ),
              );
            });
            return SizedBox(
              width: context.screenWidth * 0.8,
              height: context.screenHeight * 0.6,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: checkboxes,
                ),
              ),
            );
          },
        ),
        actions: <Widget>[
          TextButton(child: Text('取消'), onPressed: () => context.pop()),
          TextButton(
            child: Text('提交'),
            onPressed: () => context.pop(categoriesMap),
          ),
        ],
      );
    },
  ).then((value) {
    if (value != null) {
      logger.d('Checkbox values: $value');
    }
    return value;
  });
}
