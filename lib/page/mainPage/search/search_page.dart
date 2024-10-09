import 'package:animated_search_bar/animated_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../type/search_enter.dart';
import '../../../util/router.dart';
import '../../../util/state_management.dart';

// 主页的搜索页面
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({
    super.key,
  });

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late SearchEnter _localEnter;

  @override
  void initState() {
    _localEnter = SearchEnter();
    super.initState();
  }

  // String searchText = '';

  @override
  Widget build(BuildContext context) {
    final colorNotifier = ref.watch(defaultColorProvider);
    colorNotifier.initialize(context); // 显式初始化

    return Scaffold(
      appBar: AppBar(
        title: AnimatedSearchBar(
          label: "搜索本子",
          labelStyle: TextStyle(
            color: colorNotifier.defaultTextColor,
            fontWeight: FontWeight.normal,
          ),
          searchStyle: TextStyle(color: colorNotifier.defaultTextColor),
          cursorColor: colorNotifier.defaultTextColor,
          searchDecoration: InputDecoration(
            labelText: '搜索本子',
            alignLabelWithHint: true,
            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
          textInputAction: TextInputAction.done,
          // 动画效果，似乎没有用
          // animationDuration: const Duration(seconds: 5),
          onFieldSubmitted: ((value) {
            setState(() {
              _localEnter.keyword = value;
              navigateTo(context, '/search', extra: _localEnter);
            });
          }),
        ),
      ),
    );
  }
}
