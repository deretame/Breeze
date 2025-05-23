import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/search_result/models/models.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/sundry.dart';

import '../../../config/global/global.dart';
import '../../../main.dart';
import '../bloc/search_bloc.dart';

class CategoriesShield extends StatelessWidget {
  final SearchEnter searchEnter;
  final ValueChanged<SearchEnter> onChanged;

  const CategoriesShield({
    super.key,
    required this.searchEnter,
    required this.onChanged,
  });

  Future<Map<String, bool>?> showShieldCategoryDialog(BuildContext context) {
    late Map<String, bool> shieldCategoriesMap = Map.of(
      bikaSetting.getShieldCategoryMap(),
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

        final newSearchEnter = searchEnter.copyWith(state: "更新屏蔽列表");

        context.read<SearchBloc>().add(
          FetchSearchResult(newSearchEnter, SearchStatus.initial),
        );

        onChanged(newSearchEnter);
      },
      child: Row(
        children: <Widget>[
          Text("屏蔽分类", style: TextStyle(fontSize: 16)),
          Icon(Icons.expand_more),
        ],
      ),
    );
  }
}
