import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:zephyr/page/comic_info/bloc/bloc.dart';

import '../../../main.dart';
import '../../../object_box/model.dart';
import '../../../util/router/router.gr.dart';
import '../../../widgets/comic_entry/comic_entry.dart';
import '../../../widgets/error_view.dart';
import '../json/comic_info/comic_info.dart';
import '../json/eps/eps.dart';

class EpsWidget extends StatefulWidget {
  final Comic comicInfo;
  final BikaComicHistory? comicHistory;
  final List<Doc> epsInfo;
  final Function(List<Doc>, bool) onUpdateReadInfo; // 用来更新观看按钮信息
  final ComicEntryType type;

  const EpsWidget({
    super.key,
    required this.comicInfo,
    required this.comicHistory,
    required this.epsInfo,
    required this.onUpdateReadInfo,
    required this.type,
  });

  @override
  State<EpsWidget> createState() => _EpsWidgetState();
}

class _EpsWidgetState extends State<EpsWidget> {
  Comic get comicInfo => widget.comicInfo;

  BikaComicHistory? get comicHistory => widget.comicHistory;

  List<Doc> get epsInfo => widget.epsInfo;

  Function(List<Doc>, bool) get onUpdateReadInfo => widget.onUpdateReadInfo;

  ComicEntryType get type => widget.type;

  List<Doc> docs = [];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetComicEpsBloc()..add(GetComicEps(comicInfo)),
      child: type == ComicEntryType.download
          ? buildEpsList(null)
          : BlocBuilder<GetComicEpsBloc, GetComicEpsState>(
              builder: (context, state) {
                switch (state.status) {
                  case GetComicEpsStatus.initial:
                    return Center(child: CircularProgressIndicator());
                  case GetComicEpsStatus.failure:
                    return ErrorView(
                      errorMessage: '加载失败，请重试。',
                      onRetry: () {
                        context
                            .read<GetComicEpsBloc>()
                            .add(GetComicEps(comicInfo));
                      },
                    );
                  case GetComicEpsStatus.success:
                    return buildEpsList(state);
                }
              },
            ),
    );
  }

  Widget buildEpsList(GetComicEpsState? state) {
    if (state != null) {
      docs = state.eps;
    } else {
      docs = epsInfo;
    }
    onUpdateReadInfo(docs, true);
    return Column(
      children: [
        // 历史记录按钮
        if (comicHistory != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: EpButtonWidget(
              doc: Doc(
                id: "history",
                title: comicHistory!.epTitle,
                order: comicHistory!.order,
                updatedAt: comicHistory!.history,
                docId: (comicHistory!.epPageCount - 1).toString(),
              ),
              comicInfo: comicInfo,
              epsInfo: docs,
              isHistory: true,
              type: type == ComicEntryType.download
                  ? ComicEntryType.historyAndDownload
                  : ComicEntryType.history,
            ),
          ),
        ],
        // 使用 map 和 Padding 创建 EpButton 列表
        ...docs.map(
          (doc) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: EpButtonWidget(
              doc: doc,
              comicInfo: comicInfo,
              epsInfo: docs,
              isHistory: false,
              type:
                  type == ComicEntryType.history ? ComicEntryType.normal : type,
            ),
          ),
        ),
      ],
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
            epsInfo: epsInfo,
            doc: doc,
            comicId: comicInfo.id,
            type: type,
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
                    Expanded(
                      child: Container(),
                    ),
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
