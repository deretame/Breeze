import 'package:animated_search_bar/animated_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/search_result/models/search_enter.dart';

import '../../../main.dart';
import '../bloc/search_bloc.dart';

class BikaSearchBar extends StatelessWidget implements PreferredSizeWidget {
  final SearchEnter searchEnter;
  final ValueChanged<SearchEnter> onChanged;

  const BikaSearchBar({
    super.key,
    required this.searchEnter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    late TextEditingController controller = TextEditingController(text: '');
    late String label = '搜索本子';

    if (searchEnter.categories.isNotEmpty) {
      String temp = searchEnter.categories.join('、');
      label = ("分类：$temp");
    } else if (searchEnter.keyword.isNotEmpty) {
      label = searchEnter.keyword;
      controller.text = searchEnter.keyword;
    }

    // logger.d(searchEnter.toString());

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
        textInputAction: TextInputAction.search,
        onFieldSubmitted: (value) {
          final newSearchEnter = searchEnter.copyWith(
            keyword: value,
            pageCount: 1,
          );
          context.read<SearchBloc>().add(
            FetchSearchResult(newSearchEnter, SearchStatus.initial),
          );
          onChanged(newSearchEnter);
        },
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
