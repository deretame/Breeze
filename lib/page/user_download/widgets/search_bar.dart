import 'package:animated_search_bar/animated_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/user_download/user_download.dart';

import '../../../main.dart';

class BikaSearchBar extends StatelessWidget implements PreferredSizeWidget {
  const BikaSearchBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final searchEnter = SearchEnterProvider.of(context)!.searchEnter;
    late TextEditingController controller = TextEditingController(text: '');
    late String label = '下载记录';

    if (searchEnter.categories.isNotEmpty) {
      String temp = searchEnter.categories.join('、');
      label = ("分类：$temp");
    } else if (searchEnter.keyword.isNotEmpty) {
      label = searchEnter.keyword;
      controller.text = searchEnter.keyword;
    }

    return AppBar(
      titleSpacing: 0,
      elevation: 0,
      title: AnimatedSearchBar(
        label: label,
        controller: controller,
        labelStyle: TextStyle(
          color: globalSetting.textColor,
          fontWeight: FontWeight.normal,
        ),
        searchStyle: TextStyle(color: globalSetting.textColor),
        cursorColor: globalSetting.textColor,
        searchDecoration: InputDecoration(
          labelText: '搜索本子',
          alignLabelWithHint: true,
          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (value) {
          context.read<UserDownloadBloc>().add(
                UserDownloadEvent(
                  SearchEnterConst(
                    keyword: value,
                    sort: searchEnter.sort,
                    categories: searchEnter.categories,
                  ),
                ),
              );
        },
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
