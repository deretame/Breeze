import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:zephyr/page/comic_info/bloc/bloc.dart';

import '../../../main.dart';
import '../../../object_box/model.dart';
import '../../../util/router/router.gr.dart';
import '../../../widgets/error_view.dart';
import '../json/comic_info/comic_info.dart';
import '../json/eps/eps.dart';

class EpsWidget extends StatefulWidget {
  final Comic comicInfo;
  final BikaComicHistory? comicHistory;

  const EpsWidget({
    super.key,
    required this.comicInfo,
    required this.comicHistory,
  });

  @override
  State<EpsWidget> createState() => _EpsWidgetState();
}

class _EpsWidgetState extends State<EpsWidget> {
  late Comic comicInfo;
  late BikaComicHistory? comicHistory;

  @override
  void initState() {
    super.initState();
    comicInfo = widget.comicInfo;
    comicHistory = widget.comicHistory;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetComicEpsBloc()..add(GetComicEps(comicInfo)),
      child: BlocBuilder<GetComicEpsBloc, GetComicEpsState>(
        builder: (context, state) {
          switch (state.status) {
            case GetComicEpsStatus.initial:
              return Center(child: CircularProgressIndicator());
            case GetComicEpsStatus.failure:
              return ErrorView(
                errorMessage: '加载失败，请重试。',
                onRetry: () {
                  context.read<GetComicEpsBloc>().add(GetComicEps(comicInfo));
                },
              );
            case GetComicEpsStatus.success:
              List<Doc> docs = state.eps;
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
                          docId: comicHistory!.epPageCount.toString(),
                        ),
                        comicInfo: comicInfo,
                        epsInfo: docs,
                        isHistory: true,
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
                      ),
                    ),
                  ),
                ],
              );
          }
        },
      ),
    );
  }
}

class EpButtonWidget extends StatelessWidget {
  final Doc doc;
  final Comic comicInfo;
  final List<Doc> epsInfo;
  final bool? isHistory;

  const EpButtonWidget({
    super.key,
    required this.doc,
    required this.comicInfo,
    required this.epsInfo,
    required this.isHistory,
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
            isHistory: isHistory,
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
                  color: globalSetting.themeType
                      ? Colors.black.withOpacity(0.2)
                      : Colors.white.withOpacity(0.2),
                  spreadRadius: 2,
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
    history
        ? newDateTime = originalTime
        : newDateTime = originalTime.add(const Duration(hours: 8));
    String formattedTime =
        '${newDateTime.year}年${newDateTime.month}月${newDateTime.day}日 ${newDateTime.hour.toString().padLeft(2, '0')}:${newDateTime.minute.toString().padLeft(2, '0')}:${newDateTime.second.toString().padLeft(2, '0')}';
    return history ? "$formattedTime 观看" : "$formattedTime 更新";
  }
}
