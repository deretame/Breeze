import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../main.dart';
import '../../../object_box/model.dart';
import '../../../type/enum.dart';
import '../../../util/router/router.gr.dart';
import '../json/bika/comic_info/comic_info.dart';
import '../json/bika/eps/eps.dart';

class EpsWidget extends StatefulWidget {
  final Comic comicInfo;
  final BikaComicHistory? comicHistory;
  final List<Doc> epsInfo;
  final ComicEntryType type;

  const EpsWidget({
    super.key,
    required this.comicInfo,
    required this.comicHistory,
    required this.epsInfo,
    required this.type,
  });

  @override
  State<EpsWidget> createState() => _EpsWidgetState();
}

class _EpsWidgetState extends State<EpsWidget> {
  Comic get comicInfo => widget.comicInfo;

  BikaComicHistory? get comicHistory => widget.comicHistory;

  List<Doc> get epsInfo => widget.epsInfo;

  ComicEntryType get type => widget.type;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      cacheExtent: 0,
      physics: const NeverScrollableScrollPhysics(),
      // 禁止内部滚动，交由外层处理
      shrinkWrap: true,
      // 让 ListView 根据内容调整高度
      itemCount: epsInfo.length + (comicHistory != null ? 1 : 0),
      // 总数量 = eps数量 + 历史记录按钮
      itemBuilder: (context, index) {
        // 如果是历史记录按钮
        if (comicHistory != null && index == 0) {
          return Padding(
            padding: const EdgeInsets.all(5.0),
            child: EpButtonWidget(
              doc: Doc(
                id: "history",
                title: comicHistory!.epTitle,
                order: comicHistory!.order,
                updatedAt: comicHistory!.history,
                docId: (comicHistory!.epPageCount - 1).toString(),
              ),
              comicInfo: comicInfo,
              epsInfo: epsInfo,
              isHistory: true,
              type:
                  type == ComicEntryType.download
                      ? ComicEntryType.historyAndDownload
                      : ComicEntryType.history,
            ),
          );
        }

        // 调整索引，排除历史记录按钮
        final adjustedIndex = comicHistory != null ? index - 1 : index;
        final doc = epsInfo[adjustedIndex];

        return Padding(
          padding: const EdgeInsets.all(5.0),
          child: EpButtonWidget(
            doc: doc,
            comicInfo: comicInfo,
            epsInfo: epsInfo,
            isHistory: false,
            type: type == ComicEntryType.history ? ComicEntryType.normal : type,
          ),
        );
      },
    );
  }
}

class EpButtonWidget extends StatelessWidget {
  final Doc doc;
  final Comic comicInfo;
  final List<Doc> epsInfo;
  final bool? isHistory;
  final ComicEntryType type;

  const EpButtonWidget({
    super.key,
    required this.doc,
    required this.comicInfo,
    required this.epsInfo,
    required this.isHistory,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        AutoRouter.of(context).push(
          ComicReadRoute(
            comicInfo: comicInfo,
            comicId: comicInfo.id,
            type: type,
            order: doc.order,
            epsNumber: epsInfo.length,
            from: From.bika,
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
