import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:zephyr/mobx/string_select.dart';
import 'package:zephyr/page/comic_info/models/all_info.dart' show AllInfo;

import '../../../main.dart';
import '../../../type/enum.dart';
import '../../../util/router/router.gr.dart';
import '../json/bika/eps/eps.dart';

class EpButtonWidget extends StatelessWidget {
  final Doc doc;
  final AllInfo allInfo;
  final List<Doc> epsInfo;
  final bool? isHistory;
  final ComicEntryType type;
  final StringSelectStore store;

  const EpButtonWidget({
    super.key,
    required this.doc,
    required this.allInfo,
    required this.epsInfo,
    required this.isHistory,
    required this.type,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        AutoRouter.of(context).push(
          ComicReadRoute(
            comicInfo: allInfo,
            comicId: allInfo.comicInfo.id,
            type: type,
            order: doc.order,
            epsNumber: epsInfo.length,
            from: From.bika,
            store: store,
          ),
        );
      },
      child: Observer(
        builder: (context) {
          return Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 0),
            // Add horizontal margin
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: globalSetting.backgroundColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: materialColorScheme.secondaryFixedDim,
                  spreadRadius: 0,
                  blurRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  doc.id == 'history'
                      ? "${doc.title}（${doc.docId}）"
                      : doc.title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    Text(
                      doc.id == 'history'
                          ? timeDecode(doc.updatedAt, history: true)
                          : timeDecode(doc.updatedAt),
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Expanded(child: Container()),
                    doc.id == 'history'
                        ? Text("观看历史", style: TextStyle(fontSize: 14))
                        : Text(
                          "number : ${doc.order.toString()}",
                          style: TextStyle(
                            fontFamily: "Pacifico-Regular",
                            fontSize: 14,
                          ),
                        ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String timeDecode(DateTime originalTime, {bool history = false}) {
    DateTime newDateTime;

    if (history) {
      // 如果是历史记录，直接使用原始时间
      newDateTime = originalTime;
    } else {
      // 如果不是历史记录，获取当前设备的时区偏移量并调整时间
      Duration timeZoneOffset = DateTime.now().timeZoneOffset;
      newDateTime = originalTime.add(timeZoneOffset);
    }

    // 格式化时间
    String formattedTime =
        '${newDateTime.year}年${newDateTime.month}月${newDateTime.day}日 '
        '${newDateTime.hour.toString().padLeft(2, '0')}:'
        '${newDateTime.minute.toString().padLeft(2, '0')}:'
        '${newDateTime.second.toString().padLeft(2, '0')}';

    // 返回格式化后的时间
    return history ? "$formattedTime 观看" : "$formattedTime 更新";
  }
}
