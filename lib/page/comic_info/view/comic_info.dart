import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:permission_guard/permission_guard.dart';
import 'package:zephyr/mobx/string_select.dart';
import 'package:zephyr/page/comic_info/comic_info.dart';

import '../../../config/global/global.dart';
import '../../../main.dart';
import '../../../object_box/model.dart';
import '../../../object_box/objectbox.g.dart';
import '../../../type/enum.dart';
import '../../../util/router/router.dart';
import '../../../util/router/router.gr.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/toast.dart';
import '../../download/json/comic_all_info_json/comic_all_info_json.dart'
    as comic_all_info_json;
import '../json/bika/comic_info/comic_info.dart';
import 'package:zephyr/page/comic_info/json/bika/recommend/recommend_json.dart'
    as recommend_json;
import '../json/bika/eps/eps.dart';

@RoutePage()
class ComicInfoPage extends StatelessWidget {
  final String comicId;
  final ComicEntryType type;

  const ComicInfoPage({super.key, required this.comicId, required this.type});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) => GetComicInfoBloc()..add(GetComicInfoEvent(comicId: comicId)),
      child: _ComicInfo(comicId: comicId, type: type),
    );
  }
}

class _ComicInfo extends StatefulWidget {
  final String comicId;
  final ComicEntryType type;

  const _ComicInfo({required this.comicId, required this.type});

  @override
  _ComicInfoState createState() => _ComicInfoState();
}

class _ComicInfoState extends State<_ComicInfo>
    with AutomaticKeepAliveClientMixin {
  ComicEntryType get type => widget.type;

  @override
  bool get wantKeepAlive => true;

  BikaComicHistory? comicHistory;
  BikaComicDownload? comicDownload;
  comic_all_info_json.ComicAllInfoJson? comicAllInfo;
  late AllInfo allInfo; // 用来存储漫画信息
  late Comic comicInfo;
  List<Doc> epsInfo = [];
  List<recommend_json.Comic> comicList = [];

  late ComicEntryType _type;
  bool _loadingComplete = false;
  final store = StringSelectStore();

  @override
  void initState() {
    super.initState();
    _type = type;
    // 首先查询一下有没有记录
    comicHistory =
        objectbox.bikaHistoryBox
            .query(BikaComicHistory_.comicId.equals(widget.comicId))
            .build()
            .findFirst();

    if (comicHistory?.deleted == true) {
      comicHistory = null;
    }

    if (comicHistory != null) {
      store.setDate(
        '历史：${comicHistory!.epTitle}（${comicHistory!.epPageCount - 1}）'
        '${comicHistory!.history.toLocal().toString().substring(0, 19)}',
      );
    }

    _initDownloadInfo();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: <Widget>[
          const SizedBox(width: 50),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => popToRoot(context),
          ),
          Expanded(child: Container()),
          if (_type == ComicEntryType.download) ...[
            IconButton(
              icon: const Icon(Icons.upload),
              onPressed: () async {
                try {
                  if (!await Permission.manageExternalStorage
                      .request()
                      .isGranted) {
                    showErrorToast("请授予存储权限！");
                    return;
                  }
                  if (mounted) {
                    var choice = await showExportTypeDialog();
                    if (choice == ExportType.zip) {
                      showInfoToast('正在导出漫画...');
                      exportComicAsZip(comicAllInfo!);
                    } else if (choice == ExportType.folder) {
                      showInfoToast('正在导出漫画...');
                      exportComicAsFolder(comicAllInfo!);
                    } else {
                      return;
                    }
                  }
                } catch (e) {
                  showErrorToast(
                    "导出失败，请重试。\n${e.toString()}",
                    duration: const Duration(seconds: 5),
                  );
                }
              },
            ),
          ],
        ],
      ),
      body:
          _type == ComicEntryType.download
              ? _infoView()
              : BlocBuilder<GetComicInfoBloc, GetComicInfoState>(
                builder: (context, state) {
                  switch (state.status) {
                    case GetComicInfoStatus.initial:
                      return Center(child: CircularProgressIndicator());
                    case GetComicInfoStatus.failure:
                      if (state.result.contains("under review") &&
                          state.result.contains("1014")) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('此漫画已下架', style: TextStyle(fontSize: 20)),
                              SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () => context.pop(),
                                child: Text('返回'),
                              ),
                            ],
                          ),
                        );
                      }
                      return ErrorView(
                        errorMessage: '${state.result.toString()}\n加载失败，请重试。',
                        onRetry: () {
                          context.read<GetComicInfoBloc>().add(
                            GetComicInfoEvent(comicId: widget.comicId),
                          );
                        },
                      );
                    case GetComicInfoStatus.success:
                      allInfo = state.allInfo!;
                      comicInfo = allInfo.comicInfo;
                      epsInfo = allInfo.eps;
                      comicList = allInfo.recommendJson;
                      return _infoView();
                  }
                },
              ),
      floatingActionButton:
          _loadingComplete // 条件显示按钮
              ? SizedBox(
                width: 100, // 设置容器宽度，以容纳更长的文本
                height: 56, // 设置容器高度，与默认的FloatingActionButton高度一致
                child: FloatingActionButton(
                  onPressed: () {
                    if (store.date.isNotEmpty) {
                      comicHistory =
                          objectbox.bikaHistoryBox
                              .query(
                                BikaComicHistory_.comicId.equals(
                                  widget.comicId,
                                ),
                              )
                              .build()
                              .findFirst();
                      context.pushRoute(
                        ComicReadRoute(
                          comicInfo: allInfo,
                          comicId: comicInfo.id,
                          type:
                              _type == ComicEntryType.download
                                  ? ComicEntryType.historyAndDownload
                                  : ComicEntryType.history,
                          order: comicHistory!.order,
                          epsNumber: comicInfo.epsCount,
                          from: From.bika,
                          store: store,
                        ),
                      );
                    } else {
                      context.pushRoute(
                        ComicReadRoute(
                          comicInfo: allInfo,
                          comicId: comicInfo.id,
                          type: _type,
                          order: 1,
                          epsNumber: comicInfo.epsCount,
                          from: From.bika,
                          store: store,
                        ),
                      );
                    }
                  },
                  child: Observer(
                    builder:
                        (context) => Text(
                          store.date.isNotEmpty ? '继续阅读' : '开始阅读',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                  ),
                ),
              )
              : null, // 如果为false，则隐藏// 如果为false，则隐藏
    );
  }

  Widget _infoView() {
    if (!_loadingComplete) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => setState(() => _loadingComplete = true),
      );
    }

    var widgets = [
      const SizedBox(height: 10),
      ComicParticularsWidget(comicInfo: comicInfo, store: store),
      const SizedBox(height: 10),
      TagsAndCategoriesWidget(comicInfo: comicInfo, type: 'categories'),
      // const SizedBox(height: 3),
      if (comicInfo.tags.isNotEmpty) ...[
        TagsAndCategoriesWidget(comicInfo: comicInfo, type: 'tags'),
        // const SizedBox(height: 3),
      ],
      if (comicInfo.description != '') ...[
        const SizedBox(height: 3),
        Text(comicInfo.description),
      ],
      const SizedBox(height: 10),
      CreatorInfoWidget(comicInfo: comicInfo),
      const SizedBox(height: 10),
      const SizedBox(height: 10),
      ComicOperationWidget(comicInfo: comicInfo, epsInfo: epsInfo),
    ];

    for (var e in epsInfo) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: EpButtonWidget(
            doc: e,
            allInfo: allInfo,
            epsInfo: epsInfo,
            isHistory: false,
            type:
                _type == ComicEntryType.history ? ComicEntryType.normal : _type,
            store: store,
          ),
        ),
      );
    }

    widgets.addAll([
      const SizedBox(height: 10),
      RecommendWidget(comicList: comicList),
      const SizedBox(height: 180),
    ]);

    return RefreshIndicator(
      onRefresh: () async {
        _type = ComicEntryType.normal;

        context.read<GetComicInfoBloc>().add(
          GetComicInfoEvent(comicId: widget.comicId),
        );
        final query = objectbox.bikaHistoryBox.query(
          BikaComicHistory_.comicId.equals(widget.comicId),
        );
        setState(() {
          comicHistory = query.build().findFirst();
          _loadingComplete = false;
        });
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: screenWidth / 50),
        itemCount: widgets.length,
        itemBuilder: (context, index) => widgets[index],
      ),
    );
  }

  // 弹出选择对话框，让用户选择导出为压缩包还是文件夹
  Future<ExportType?> showExportTypeDialog() async {
    return await showDialog<ExportType>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('选择导出方式'),
          content: Text('请选择将漫画导出为压缩包还是文件夹：'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null);
              },
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(ExportType.folder); // 返回文件夹选项
              },
              child: Text('文件夹'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(ExportType.zip); // 返回压缩包选项
              },
              child: Text('压缩包'),
            ),
          ],
        );
      },
    );
  }

  void _initDownloadInfo() {
    if (_type == ComicEntryType.download) {
      comicDownload =
          objectbox.bikaDownloadBox
              .query(BikaComicDownload_.comicId.equals(widget.comicId))
              .build()
              .findFirst();

      if (comicDownload != null) {
        comicAllInfo = comic_all_info_json.comicAllInfoJsonFromJson(
          comicDownload!.comicInfoAll,
        );
        comicInfo = comicAllInfo2Comic(comicAllInfo!);
      }

      var epsDoc = comicAllInfo!.eps.docs;
      for (var epDoc in epsDoc) {
        epsInfo.add(
          Doc(
            id: epDoc.id,
            title: epDoc.title,
            order: epDoc.order,
            updatedAt: epDoc.updatedAt,
            docId: epDoc.docId,
          ),
        );
      }

      allInfo = AllInfo(
        comicInfo: comicInfo,
        eps: epsInfo,
        recommendJson: comicList,
      );
    }
  }
}
