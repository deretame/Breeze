import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/page/search_result/bloc/search_bloc.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/sundry.dart';
import 'package:zephyr/widgets/toast.dart';

import '../../../util/router/router.gr.dart';

class KeywordWidget extends StatefulWidget {
  final List<String> keywords;

  const KeywordWidget(this.keywords, {super.key});

  @override
  State<KeywordWidget> createState() => _KeywordWidgetState();
}

class _KeywordWidgetState extends State<KeywordWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Wrap(
        spacing: 10,
        children: List.generate(widget.keywords.length, (index) {
          return GestureDetector(
            onTap: () {
              context.pushRoute(
                SearchResultRoute(
                  searchEvent: SearchEvent().copyWith(
                    searchStates: SearchStates.initial(context).copyWith(
                      from: From.bika,
                      searchKeyword: widget.keywords[index],
                    ),
                  ),
                ),
              );
            },
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: widget.keywords[index]));
              showSuccessToast("${widget.keywords[index].let(t2s)}已复制到剪贴板");
            },
            child: Chip(
              backgroundColor: context.backgroundColor, // 设置背景颜色
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10), // 设置圆角
              ),
              label: Text(
                widget.keywords[index].let(t2s),
                style: TextStyle(
                  fontSize: 12,
                  color: context.theme.colorScheme.primary,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
