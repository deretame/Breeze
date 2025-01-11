import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/page/user_favourite/user_favourite.dart';

import '../../../config/global.dart';
import '../../../main.dart';

class CategoriesShield extends StatelessWidget {
  const CategoriesShield({
    super.key,
  });

  Future<Map<String, bool>?> showShieldCategoryDialog(BuildContext context) {
    late Map<String, bool> shieldCategoriesMap =
        Map.of(bikaSetting.getShieldCategoryMap());

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
                    title: Text(key),
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
                width: screenWidth * 0.8, // 设置对话框宽度
                height: screenHeight * 0.6, // 设置对话框高度
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
                Navigator.of(context).pop(shieldCategoriesMap);
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

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        late var oldCategoriesMap = Map.of(bikaSetting.getShieldCategoryMap());
        final categoriesShield = await showShieldCategoryDialog(context);

        if (categoriesShield == null) {
          return;
        }

        if (oldCategoriesMap == categoriesShield) {
          return;
        }

        bikaSetting.setShieldCategoryMap(categoriesShield);

        if (!context.mounted) return;

        context
            .read<UserFavouriteBloc>()
            .add(UserFavouriteEvent(1, Uuid().v4()));
      },
      child: Row(
        children: <Widget>[
          Text(
            "屏蔽分类",
            style: TextStyle(
              fontSize: 16,
            ),
          ),
          Icon(Icons.expand_more)
        ],
      ),
    );
  }
}
