import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/settings_hive_utils.dart';
import 'package:zephyr/util/sundry.dart';

import '../../../main.dart';

Future<Map<String, bool>?> showShieldCategoryDialog(BuildContext context) {
  late Map<String, bool> shieldCategoriesMap = Map.of(
    SettingsHiveUtils.bikaShieldCategoryMap,
  );

  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('选择屏蔽分类'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            List<Widget> checkboxes = [];
            shieldCategoriesMap.forEach((key, value) {
              checkboxes.add(
                CheckboxListTile(
                  title: Text(key.let(t2s)),
                  value: shieldCategoriesMap[key],
                  onChanged: (bool? newValue) {
                    setState(() {
                      shieldCategoriesMap[key] = newValue!;
                    });
                  },
                ),
              );
            });
            return SizedBox(
              width: context.screenWidth * 0.8, // 设置对话框宽度
              height: context.screenHeight * 0.6, // 设置对话框高度
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
            onPressed: () => context.pop(shieldCategoriesMap),
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
