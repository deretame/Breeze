import 'package:animated_search_bar/animated_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/page/jm/jm_search_result/jm_search_result.dart';
import 'package:zephyr/util/context/context_extensions.dart';

class BikaSearchBar extends StatelessWidget implements PreferredSizeWidget {
  final JmSearchResultEvent event;
  final ValueChanged searchCallback;

  const BikaSearchBar({
    super.key,
    required this.event,
    required this.searchCallback,
  });

  @override
  Widget build(BuildContext context) {
    TextEditingController controller = TextEditingController(
      text: event.keyword,
    );

    // logger.d(event.toString());

    return AppBar(
      titleSpacing: 0,
      elevation: 0,
      title: AnimatedSearchBar(
        label: '搜索本子',
        controller: controller,
        labelStyle: TextStyle(
          color: context.textColor,
          fontWeight: FontWeight.normal,
        ),
        searchStyle: TextStyle(color: context.textColor),
        cursorColor: context.textColor,
        searchDecoration: InputDecoration(
          labelText: '最多8个汉字/字母/数字/符号',
          alignLabelWithHint: true,
          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
        textInputAction: TextInputAction.search,
        onFieldSubmitted: searchCallback,
        autoFocus: event.keyword.isEmpty,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
