// 通用的标签/分类 Widget
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zephyr/page/jm/jm_search_result/bloc/jm_search_result_bloc.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/sundry.dart';
import 'package:zephyr/widgets/toast.dart';

import '../../../util/router/router.gr.dart';
import '../../search_result/models/search_enter.dart';

class AllChipWidget extends StatefulWidget {
  final String comicId;
  final String type;
  final List<String> chips;
  final From from;

  const AllChipWidget({
    super.key,
    required this.comicId,
    required this.type,
    required this.chips,
    required this.from,
  });

  @override
  State<AllChipWidget> createState() => _AllChipWidgetState();
}

class _AllChipWidgetState extends State<AllChipWidget> {
  List<String> get items => widget.chips;

  String get title {
    switch (widget.type) {
      case 'author':
        return '作者';
      case 'chineseTeam':
        return '汉化组';
      case 'tags':
        return '标签';
      case 'categories':
        return '分类';
      case 'actors':
        return '角色';
      case 'works':
        return '原作';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 10,
          children: List.generate(items.length + 1, (index) {
            if (index == 0) {
              return Chip(
                backgroundColor: context.backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                side: BorderSide(color: context.textColor),
                label: Text(
                  title,
                  style: TextStyle(fontSize: 12, color: context.textColor),
                ),
              );
            }
            return GestureDetector(
              onTap: () => goToSearch(index),
              onLongPress: () {
                Clipboard.setData(
                  ClipboardData(text: processText(items[index - 1])),
                );
                showSuccessToast("已将${items[index - 1].let(t2s)}复制到剪贴板");
              },
              child: Chip(
                backgroundColor: context.backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                label: Text(
                  processText(items[index - 1]).let(t2s),
                  style: TextStyle(
                    fontSize: 12,
                    color: context.theme.colorScheme.primary,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  String processText(String text) {
    if (text.contains('\r')) {
      text = text.replaceAll('\r', '');
    }

    if (text.contains(' ')) {
      text = text.replaceAll(' ', '');
    }

    return text;
  }

  void goToSearch(int index) {
    if (widget.from == From.bika) {
      if (title == "分类") {
        AutoRouter.of(context).push(
          SearchResultRoute(
            searchEnter: SearchEnter.initial().copyWith(
              from: "bika",
              type: title,
              categories: [items[index - 1]],
            ),
          ),
        );
      } else if (title == "标签" || title == "作者" || title == "汉化组") {
        AutoRouter.of(context).push(
          SearchResultRoute(
            searchEnter: SearchEnter.initial().copyWith(
              from: "bika",
              type: title,
              keyword: items[index - 1],
            ),
          ),
        );
      }
    } else if (widget.from == From.jm) {
      context.pushRoute(
        JmSearchResultRoute(
          event: JmSearchResultEvent(keyword: items[index - 1]),
        ),
      );
    }
  }
}
