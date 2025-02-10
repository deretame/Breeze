import 'package:flutter/material.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart';

import '../../../config/bika/bika_setting.dart';
import '../../../config/global.dart';

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
                  title: Text(key),
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
              width: screenWidth * 0.8,
              height: screenHeight * 0.6,
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
          TextButton(
            child: Text('取消'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('提交'),
            onPressed: () {
              Navigator.of(context).pop(categoriesMap);
            },
          ),
        ],
      );
    },
  ).then((value) {
    if (value != null) {
      debugPrint('Checkbox values: $value');
    }
    return value;
  });
}
