import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:permission_guard/permission_guard.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/mobx/string_select.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/jm/jm_download/json/download_info_json.dart'
    show downloadInfoJsonFromJson;
import 'package:zephyr/page/jm/jm_comic_info/jm_comic_info.dart';
import 'package:zephyr/page/jm/jm_comic_info/json/jm_comic_info_json.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/widgets/toast.dart';

import '../../../../network/http/picture/picture.dart';
import '../../../../type/enum.dart';
import '../../../../util/router/router.dart';
import '../../../../widgets/picture_bloc/models/picture_info.dart';

@RoutePage()
class JmComicInfoPage extends StatelessWidget {
  final String comicId;
  final ComicEntryType type;

  const JmComicInfoPage({super.key, required this.comicId, required this.type});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) =>
              JmComicInfoBloc()..add(
                JmComicInfoEvent(
                  status: JmComicInfoStatus.initial,
                  comicId: comicId,
                ),
              ),
      child: _JmComicInfoPage(comicId: comicId, type: type),
    );
  }
}

class _JmComicInfoPage extends StatefulWidget {
  final String comicId;
  final ComicEntryType type;

  const _JmComicInfoPage({required this.type, required this.comicId});

  @override
  __JmComicInfoPageState createState() => __JmComicInfoPageState();
}

class __JmComicInfoPageState extends State<_JmComicInfoPage> {
  bool get isDownload => _type == ComicEntryType.download;

  late JmComicInfoState _state;
  bool _init = false;
  bool _hasHistory = false;
  JmHistory? jmHistory;
  JmDownload? jmDownload;
  late ComicEntryType _type;
  final store = StringSelectStore();

  @override
  void initState() {
    super.initState();
    _type = widget.type;
    jmHistory =
        objectbox.jmHistoryBox
            .query(JmHistory_.comicId.equals(widget.comicId))
            .build()
            .findFirst();
    _hasHistory = jmHistory?.deleted == false;

    if (_hasHistory) {
      store.setDate(
        '历史：'
        '${jmHistory!.epTitle.isNotEmpty ? jmHistory!.epTitle : "第1话"} / '
        '${jmHistory!.epPageCount - 1} / '
        '${jmHistory!.history.toLocal().toString().substring(0, 19)}',
      );
    }

    jmDownload =
        objectbox.jmDownloadBox
            .query(JmDownload_.comicId.equals(widget.comicId))
            .build()
            .findFirst();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          const SizedBox(width: 50),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => popToRoot(context),
          ),
          Expanded(child: Container()),
          if (isDownload)
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
                      exportComicAsZip(jmDownload!);
                    } else if (choice == ExportType.folder) {
                      showInfoToast('正在导出漫画...');
                      exportComicAsFolder(jmDownload!);
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
      ),
      body:
          !isDownload
              ? BlocBuilder<JmComicInfoBloc, JmComicInfoState>(
                builder: (context, state) {
                  switch (state.status) {
                    case JmComicInfoStatus.initial:
                      return const Center(child: CircularProgressIndicator());
                    case JmComicInfoStatus.failure:
                      return _failureWidget(state);
                    case JmComicInfoStatus.success:
                      return _comicEntry(state);
                  }
                },
              )
              : _comicEntry(null),
      floatingActionButton:
          _init
              ? SizedBox(
                width: 100,
                height: 56,
                child: FloatingActionButton(
                  onPressed: _navigateToReader,
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
              : null,
    );
  }

  Widget _failureWidget(JmComicInfoState state) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${state.result.toString()}\n加载失败',
          style: TextStyle(fontSize: 20),
        ),
        SizedBox(height: 10), // 添加间距
        ElevatedButton(onPressed: _onRefresh, child: Text('点击重试')),
      ],
    ),
  );

  Widget _comicEntry(JmComicInfoState? state) {
    if (!_init) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _init = true;
          if (!isDownload) {
            _state = state!;
          }
        });
      });
    }

    final JmComicInfoJson comicInfo = _prepareComicInfo(state);
    final id = comicInfo.id.toString();

    if (comicInfo.name.isEmpty) {
      return Center(
        child: Text('不存在id为$id的漫画', style: TextStyle(fontSize: 20)),
      );
    }

    List<Widget> comicInfoWidgets = []; // 先创建空列表

    // 1. 添加封面和基本信息
    comicInfoWidgets.addAll([
      const SizedBox(height: 10),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Cover(
            pictureInfo: PictureInfo(
              from: 'jm',
              url: getJmCoverUrl(id),
              path: '$id.jpg',
              cartoonId: id,
              pictureType: 'cover',
            ),
          ),
          SizedBox(width: context.screenWidth / 60),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  comicInfo.name,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 2),
                Text('更新时间：${_dataFormat(comicInfo.addtime)}'),
                const SizedBox(height: 2),
                InkWell(
                  onLongPress: () {
                    Clipboard.setData(
                      ClipboardData(text: comicInfo.id.toString()),
                    );
                    showSuccessToast('id已复制到剪贴板');
                  },
                  child: Text('禁漫车：JM${comicInfo.id}'),
                ),
                Observer(
                  builder:
                      (context) =>
                          store.date.isNotEmpty
                              ? Column(
                                children: [
                                  const SizedBox(height: 2),
                                  Text(store.date),
                                ],
                              )
                              : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
    ]);

    // 2. 添加操作按钮
    comicInfoWidgets.add(ComicOperationWidget(comicInfo: comicInfo));
    comicInfoWidgets.add(const SizedBox(height: 10));

    // 3. 动态添加标签（tags、author、actors、works）
    if (comicInfo.tags.isNotEmpty) {
      comicInfoWidgets.add(
        AllChipWidget(comicId: id, type: 'tags', chips: comicInfo.tags),
      );
    }
    if (comicInfo.author.isNotEmpty) {
      comicInfoWidgets.add(
        AllChipWidget(comicId: id, type: 'author', chips: comicInfo.author),
      );
    }
    if (comicInfo.actors.isNotEmpty) {
      comicInfoWidgets.add(
        AllChipWidget(comicId: id, type: 'actors', chips: comicInfo.actors),
      );
    }
    if (comicInfo.works.isNotEmpty) {
      comicInfoWidgets.add(
        AllChipWidget(comicId: id, type: 'works', chips: comicInfo.works),
      );
    }

    // 4. 添加描述（description）
    if (comicInfo.description.isNotEmpty) {
      comicInfoWidgets.addAll([
        const SizedBox(height: 3),
        Text(
          comicInfo.description,
          style: const TextStyle(fontSize: 16),
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
      ]);
    }

    // 5. 章节
    comicInfoWidgets.add(const SizedBox(height: 10));
    for (int i = 0; i < comicInfo.series.length; i++) {
      final series = comicInfo.series[i];
      comicInfoWidgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              SizedBox(width: 5),
              Expanded(
                child: EpWidget(
                  comicId: id,
                  series: series,
                  comicInfo: comicInfo,
                  epsNumber: comicInfo.series.length,
                  type: _type,
                  store: store,
                ),
              ),
              SizedBox(width: 5),
            ],
          ),
        ),
      );
    }

    // 6. 添加推荐（relatedList）
    if (comicInfo.relatedList.isNotEmpty) {
      comicInfoWidgets.addAll([
        const SizedBox(height: 10),
        Row(
          children: [
            SizedBox(width: 5),
            Expanded(child: RecommendWidget(comicInfo: comicInfo)),
            SizedBox(width: 5),
          ],
        ),
      ]);
    }

    // 7. 最后添加底部间距
    comicInfoWidgets.add(const SizedBox(height: 80));

    return RefreshIndicator(
      onRefresh: () async {
        _type = ComicEntryType.normal;

        context.read<JmComicInfoBloc>().add(
          JmComicInfoEvent(
            comicId: widget.comicId,
            status: JmComicInfoStatus.initial,
          ),
        );
        final query = objectbox.jmHistoryBox.query(
          JmHistory_.comicId.equals(widget.comicId),
        );
        setState(() {
          jmHistory = query.build().findFirst();
          _init = false;
        });
      },
      child: Row(
        children: [
          SizedBox(width: context.screenWidth / 50),
          Expanded(
            child: ListView.builder(
              itemCount: comicInfoWidgets.length,
              itemBuilder: (context, index) => comicInfoWidgets[index],
            ),
          ),
          SizedBox(width: context.screenWidth / 50),
        ],
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

  void _onRefresh() {
    context.read<JmComicInfoBloc>().add(
      JmComicInfoEvent(
        status: JmComicInfoStatus.initial,
        comicId: widget.comicId,
      ),
    );
  }

  String _dataFormat(String time) => time
      .let(toInt)
      .let(
        (timestamp) => DateTime.fromMillisecondsSinceEpoch(
          timestamp * 1000,
        ).toUtc().toString().let((str) => str.substring(0, str.length - 5)),
      );

  void _navigateToReader() {
    String comicIdVal;
    int orderVal;
    int epsNumberVal;
    From fromVal = From.jm;
    ComicEntryType typeVal = _type;
    dynamic comicInfoVal;

    if (isDownload) {
      comicIdVal = jmDownload!.comicId;
      epsNumberVal =
          jmDownload!.allInfo
              .let(downloadInfoJsonFromJson)
              .series
              .first
              .info
              .series
              .length;
      if (_hasHistory) {
        typeVal = ComicEntryType.historyAndDownload;
      }
      comicInfoVal = jmDownload!.allInfo.let(jmComicInfoJsonFromJson);
    } else {
      comicIdVal = widget.comicId;
      epsNumberVal = _state.comicInfo!.series.length;
      typeVal =
          store.date.isNotEmpty
              ? ComicEntryType.history
              : ComicEntryType.normal;
      comicInfoVal = _state.comicInfo!;
    }

    jmHistory =
        objectbox.jmHistoryBox
            .query(JmHistory_.comicId.equals(widget.comicId))
            .build()
            .findFirst();

    orderVal =
        store.date.isNotEmpty ? jmHistory!.order : widget.comicId.let(toInt);

    context.pushRoute(
      ComicReadRoute(
        comicId: comicIdVal,
        order: orderVal,
        epsNumber: epsNumberVal,
        from: fromVal,
        type: typeVal,
        comicInfo: comicInfoVal,
        store: store,
      ),
    );
  }

  JmComicInfoJson _prepareComicInfo(JmComicInfoState? blocState) {
    late JmComicInfoJson comicInfo;
    if (!isDownload) {
      comicInfo = blocState!.comicInfo!;
      if (comicInfo.series.isEmpty) {
        comicInfo = blocState.comicInfo!.copyWith(
          series: [
            Series(id: comicInfo.id.toString(), name: "第1话", sort: 'null'),
          ],
        );
      }
    } else {
      comicInfo = jmDownload!.allInfo.let(jmComicInfoJsonFromJson);

      final epsIds = jmDownload!.epsIds;
      final series = comicInfo.series;
      final newSeries =
          series.where((s) => epsIds.contains(s.id.toString())).toList();
      comicInfo = comicInfo.copyWith(series: newSeries);
    }
    return comicInfo;
  }
}
