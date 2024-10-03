import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zephyr/config/global.dart';

import '../../../../util/state_management.dart';
import '../widget/comic_list_widget.dart';

class ComicSearchPage extends StatefulWidget {
  const ComicSearchPage({super.key});

  @override
  State<StatefulWidget> createState() => _ComicSearchPageState();
}

class _ComicSearchPageState extends State<ComicSearchPage> {
  String searchVal = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //清除title左右的padding，默认会有一定的距离
        titleSpacing: 0,
        elevation: 0,
        title: SearchAppBar(
          hintLabel: "搜索本子",
          onSubmitted: (value) {
            setState(() {
              searchVal = value;
            });
          },
        ),
      ),
      body: ComicListWidget(query: searchVal),
    );
  }
}

class SearchAppBar extends ConsumerStatefulWidget {
  const SearchAppBar(
      {super.key, required this.hintLabel, required this.onSubmitted});

  final String hintLabel;

  // 回调函数
  final Function(String) onSubmitted;

  @override
  ConsumerState<SearchAppBar> createState() => _SearchAppBarState();
}

class _SearchAppBarState extends ConsumerState<SearchAppBar> {
  // 焦点对象
  final FocusNode _focusNode = FocusNode();

  // 文本的值
  String searchVal = '';

  //用于清空输入框
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    //  获取焦点
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) {
        _focusNode.requestFocus();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorNotifier = ref.watch(defaultColorProvider);
    colorNotifier.initialize(context); // 显式初始化
    return Container(
      // 宽度为屏幕的0.8
      width: screenWidth * 0.8,
      // appBar默认高度是56，这里搜索框设置为40
      height: 44,
      // 设置padding
      padding: const EdgeInsets.only(left: 20),
      // 设置子级位置
      alignment: Alignment.centerLeft,
      // 设置修饰
      decoration: BoxDecoration(
        color: colorNotifier.defaultBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: colorNotifier.themeType
                ? Colors.black.withOpacity(0.2)
                : Colors.white.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 2,
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        // 自动获取焦点
        focusNode: _focusNode,
        autofocus: true,
        decoration: InputDecoration(
            hintText: widget.hintLabel,
            hintStyle: const TextStyle(color: Colors.grey),
            // 取消掉文本框下面的边框
            border: InputBorder.none,
            icon: const Padding(
              padding: EdgeInsets.only(left: 0, top: 0),
              child: Icon(
                Icons.search,
                size: 18,
              ),
            ),
            //  关闭按钮，有值时才显示
            suffixIcon: searchVal.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      //   清空内容
                      setState(
                        () {
                          searchVal = '';
                          _controller.clear();
                        },
                      );
                    },
                  )
                : null),
        onChanged: (value) {
          setState(
            () {
              searchVal = value;
            },
          );
        },
        onSubmitted: (value) {
          widget.onSubmitted(value);
        },
      ),
    );
  }
}
