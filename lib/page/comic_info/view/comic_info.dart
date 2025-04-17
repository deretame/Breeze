import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_guard/permission_guard.dart';
import 'package:zephyr/page/comic_info/comic_info.dart';

import '../../../config/global.dart';
import '../../../main.dart';
import '../../../object_box/model.dart';
import '../../../object_box/objectbox.g.dart';
import '../../../util/router/router.dart';
import '../../../util/router/router.gr.dart';
import '../../../widgets/comic_entry/comic_entry.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/toast.dart';
import '../../download/json/comic_all_info_json/comic_all_info_json.dart'
    as comic_all_info_json;
import '../json/comic_info/comic_info.dart';
import '../json/eps/eps.dart';

enum ExportType {
  zip, // 导出为压缩包
  folder, // 导出为文件夹
}

@RoutePage()
class ComicInfoPage extends StatelessWidget {
  final String comicId;
  final ComicEntryType? type;

  const ComicInfoPage({super.key, required this.comicId, this.type});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetComicInfoBloc()..add(GetComicInfo(comicId)),
      child: _ComicInfo(comicId: comicId, type: type),
    );
  }
}

class _ComicInfo extends StatefulWidget {
  final String comicId;
  final ComicEntryType? type;

  const _ComicInfo({required this.comicId, required this.type});

  @override
  _ComicInfoState createState() => _ComicInfoState();
}

class _ComicInfoState extends State<_ComicInfo>
    with AutomaticKeepAliveClientMixin {
  ComicEntryType? get type => widget.type;

  @override
  bool get wantKeepAlive => true;

  BikaComicHistory? comicHistory;
  BikaComicDownload? comicDownload;
  comic_all_info_json.ComicAllInfoJson? comicAllInfo;
  late Comic comicInfo; // 用来存储漫画信息

  bool _epsCompleted = false; // 用来判断章节是不是加载完毕了
  List<Doc> _epsInfo = [];
  late ComicEntryType _type;
  late Timer _historyCheckTimer;

  @override
  void initState() {
    super.initState();
    _type = type ?? ComicEntryType.normal;
    // 首先查询一下有没有记录
    comicHistory =
        objectbox.bikaHistoryBox
            .query(BikaComicHistory_.comicId.equals(widget.comicId))
            .build()
            .findFirst();

    if (comicHistory?.deleted == true) {
      comicHistory = null;
    }

    _historyCheckTimer = Timer.periodic(
      Duration(seconds: 1),
      _autoUpdateHistory,
    );

    _initDownloadInfo();
  }

  @override
  void dispose() {
    _historyCheckTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            AutoRouter.of(context).maybePop();
          },
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
                                onPressed: () {
                                  AutoRouter.of(context).maybePopTop();
                                },
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
                            GetComicInfo(widget.comicId),
                          );
                        },
                      );
                    case GetComicInfoStatus.success:
                      comicInfo = state.comicInfo!;
                      return _infoView();
                  }
                },
              ),
      floatingActionButton:
          _epsCompleted // 条件显示按钮
              ? SizedBox(
                width: 100, // 设置容器宽度，以容纳更长的文本
                height: 56, // 设置容器高度，与默认的FloatingActionButton高度一致
                child: FloatingActionButton(
                  onPressed: () {
                    if (comicHistory != null) {
                      comicHistory =
                          objectbox.bikaHistoryBox
                              .query(
                                BikaComicHistory_.comicId.equals(
                                  widget.comicId,
                                ),
                              )
                              .build()
                              .findFirst();
                      AutoRouter.of(context).push(
                        ComicReadRoute(
                          comicInfo: comicInfo,
                          epsInfo: _epsInfo,
                          doc: Doc(
                            id: "history",
                            title: comicHistory!.epTitle,
                            order: comicHistory!.order,
                            updatedAt: comicHistory!.history,
                            docId: (comicHistory!.epPageCount - 1).toString(),
                          ),
                          comicId: comicInfo.id,
                          type:
                              _type == ComicEntryType.download
                                  ? ComicEntryType.historyAndDownload
                                  : ComicEntryType.history,
                        ),
                      );
                    } else {
                      AutoRouter.of(context).push(
                        ComicReadRoute(
                          comicInfo: comicInfo,
                          epsInfo: _epsInfo,
                          doc: _epsInfo[0],
                          comicId: comicInfo.id,
                          type: _type,
                        ),
                      );
                    }
                  },
                  child: Text(
                    comicHistory != null ? '继续阅读' : '开始阅读',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              )
              : null, // 如果为false，则隐藏// 如果为false，则隐藏
    );
  }

  Widget _infoView() {
    return RefreshIndicator(
      onRefresh: () async {
        _epsCompleted = false;
        context.read<GetComicInfoBloc>().add(GetComicInfo(widget.comicId));
        final query = objectbox.bikaHistoryBox.query(
          BikaComicHistory_.comicId.equals(widget.comicId),
        );
        setState(() {
          comicHistory = query.build().findFirst();
          _type = ComicEntryType.normal;
        });
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        // 添加滚动视图包裹
        child: SizedBox(
          width: screenWidth,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(width: screenWidth / 50),
              Flexible(
                fit: FlexFit.loose,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: 10),
                    ComicParticularsWidget(comicInfo: comicInfo),
                    const SizedBox(height: 10),
                    TagsAndCategoriesWidget(
                      comicInfo: comicInfo,
                      type: 'categories',
                    ),
                    // const SizedBox(height: 3),
                    if (comicInfo.tags.isNotEmpty) ...[
                      TagsAndCategoriesWidget(
                        comicInfo: comicInfo,
                        type: 'tags',
                      ),
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
                    ComicOperationWidget(
                      comicInfo: comicInfo,
                      epsInfo: _epsInfo,
                    ),
                    const SizedBox(height: 10),
                    EpsWidget(
                      comicInfo: comicInfo,
                      comicHistory: comicHistory,
                      epsInfo: _epsInfo,
                      onUpdateReadInfo: _updateReadInfo,
                      type: _type,
                    ),
                    const SizedBox(height: 10),
                    RecommendWidget(comicId: comicInfo.id, type: _type),
                    const SizedBox(height: 85),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
              SizedBox(width: screenWidth / 50),
            ],
          ),
        ),
      ),
    );
  }

  void _updateReadInfo(List<Doc> epsInfo, bool epsCompleted) {
    if (_epsCompleted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _epsInfo = epsInfo;
          _epsCompleted = epsCompleted;
        });
      }
    });
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

  void _autoUpdateHistory(Timer timer) async {
    if (!mounted) {
      timer.cancel();
      return;
    }
    var temp =
        await objectbox.bikaHistoryBox
            .query(BikaComicHistory_.comicId.equals(widget.comicId))
            .build()
            .findFirstAsync();
    if (temp?.deleted == true) {
      temp = null;
    }
    if (mounted &&
        temp != null &&
        temp.toString() != comicHistory!.toString()) {
      setState(() => comicHistory = temp);
    }
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
        _epsInfo.add(
          Doc(
            id: epDoc.id,
            title: epDoc.title,
            order: epDoc.order,
            updatedAt: epDoc.updatedAt,
            docId: epDoc.docId,
          ),
        );
      }
    }
  }
}
