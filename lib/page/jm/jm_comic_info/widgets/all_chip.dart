import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:zephyr/widgets/toast.dart';

import '../../../../main.dart';
import '../../../../util/router/router.gr.dart';
import '../../jm_search_result/bloc/jm_search_result_bloc.dart';

class AllChipWidget extends StatefulWidget {
  final String comicId;
  final String type;
  final List<String> chips;

  const AllChipWidget({
    super.key,
    required this.comicId,
    required this.type,
    required this.chips,
  });

  @override
  State<AllChipWidget> createState() => _AllChipWidgetState();
}

class _AllChipWidgetState extends State<AllChipWidget> {
  List<String> get items => widget.chips;

  String get title {
    switch (widget.type) {
      case 'tags':
        return '标签';
      case 'author':
        return '作者';
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
    return Observer(
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 10,
              children: List.generate(items.length + 1, (index) {
                if (index == 0) {
                  return Chip(
                    backgroundColor: globalSetting.backgroundColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: BorderSide(color: globalSetting.textColor),
                    label: Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: globalSetting.textColor,
                      ),
                    ),
                  );
                }
                return GestureDetector(
                  onTap: () {
                    context.pushRoute(
                      JmSearchResultRoute(
                        event: JmSearchResultEvent(keyword: items[index - 1]),
                      ),
                    );
                  },
                  onLongPress: () {
                    Clipboard.setData(
                      ClipboardData(text: processText(items[index - 1])),
                    );
                    showSuccessToast("已将${items[index - 1]}复制到剪贴板");
                  },
                  child: Chip(
                    backgroundColor: globalSetting.backgroundColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    label: Text(
                      processText(items[index - 1]),
                      style: TextStyle(
                        fontSize: 12,
                        color: materialColorScheme.primary,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      },
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
}
