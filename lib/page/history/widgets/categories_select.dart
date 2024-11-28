import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/bika/bika_setting.dart';

import '../../../config/global.dart';
import '../bloc/history_bloc.dart';
import '../method/search_enter_provider.dart';
import '../models/search_enter.dart';

class CategoriesSelect extends StatelessWidget {
  const CategoriesSelect({
    super.key,
  });

  Future<Map<String, bool>?> showCategoryDialog(BuildContext context) async {
    final searchEnter = SearchEnterProvider.of(context)!.searchEnter;
    Map<String, bool> categoriesMap = Map.from(categoryMap);
    for (String category in searchEnter.categories) {
      // 如果 categoriesMap 中存在该分类，则将其值设为 true
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
                Navigator.of(context).pop(); // 返回 null
              },
            ),
            TextButton(
              child: Text('提交'),
              onPressed: () {
                Navigator.of(context).pop(categoriesMap); // 返回选中的值
              },
            ),
          ],
        );
      },
    ).then((value) {
      if (value != null) {
        debugPrint('Checkbox values: $value');
      }
      return value; // 返回选中的值或 null
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchEnter = SearchEnterProvider.of(context)!.searchEnter;
    return InkWell(
      onTap: () async {
        var categoriesMap = Map.from(categoryMap);
        for (String category in searchEnter.categories) {
          // 如果 categoriesMap 中存在该分类，则将其值设为 true
          if (categoriesMap.containsKey(category)) {
            categoriesMap[category] = true;
          }
        }

        List<String> categoriesChoice = [];

        final categories = await showCategoryDialog(context);

        if (categories == null) {
          return;
        }

        if (categoriesMap == categories) return;

        categories.forEach((key, value) {
          if (value == true) {
            categoriesChoice.add(key);
          }
        });

        if (!context.mounted) return;
        context.read<HistoryBloc>().add(
              HistoryEvent(
                SearchEnterConst(
                  keyword: searchEnter.keyword,
                  sort: searchEnter.sort,
                  categories: categoriesChoice,
                  refresh: searchEnter.refresh,
                ),
              ),
            );
      },
      child: Row(
        children: <Widget>[
          Text(
            "选择分类",
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
