import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/jm/jm_comic_info/jm_comic_info.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/widgets/toast.dart';

import '../../../../config/global/global.dart';
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
  late JmComicInfoState _state;
  bool _init = false;
  bool _hasHistory = false;
  JmHistory? jmHistory;

  @override
  void initState() {
    super.initState();
    jmHistory =
        objectbox.jmHistoryBox
            .query(JmHistory_.comicId.equals(widget.comicId))
            .build()
            .findFirst();
    _hasHistory = jmHistory?.deleted == false;
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
        ],
      ),
      body: BlocBuilder<JmComicInfoBloc, JmComicInfoState>(
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
      ),
      floatingActionButton:
          _init
              ? SizedBox(
                width: 100,
                height: 56,
                child: FloatingActionButton(
                  onPressed: () {
                    context.pushRoute(
                      ComicReadRoute(
                        comicId: widget.comicId,
                        order: _state.comicInfo!.id,
                        epsNumber: _state.comicInfo!.series.length,
                        from: From.jm,
                        type:
                            _hasHistory
                                ? ComicEntryType.history
                                : ComicEntryType.normal,
                        comicInfo: _state.comicInfo!,
                      ),
                    );
                  },
                  child: Text(
                    _hasHistory ? '继续阅读' : '开始阅读',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
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

  Widget _comicEntry(JmComicInfoState state) {
    if (!_init) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _init = true;
          _state = state;
        });
      });
    }

    final comicInfo = state.comicInfo!;
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
              path: '.jpg',
              cartoonId: id,
              pictureType: 'cover',
            ),
          ),
          SizedBox(width: screenWidth / 60),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comicInfo.name,
                  style: const TextStyle(fontSize: 18),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
                const SizedBox(height: 2),
                Text('上传时间：${_dataFormat(comicInfo.addtime)}'),
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
                if (_hasHistory) ...[
                  const SizedBox(height: 2),
                  Text(
                    '历史：${jmHistory!.epTitle}（${jmHistory!.epPageCount}）${jmHistory!.history.toLocal().toString().substring(0, 19)}',
                  ),
                ],
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

    // 5. 章节（每行两个）
    if (comicInfo.series.isNotEmpty) {
      comicInfoWidgets.add(const SizedBox(height: 10));
      for (int i = 0; i < comicInfo.series.length; i += 2) {
        final series1 = comicInfo.series[i];
        final series2 =
            (i + 1 < comicInfo.series.length) ? comicInfo.series[i + 1] : null;
        comicInfoWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                SizedBox(width: 5),
                Expanded(
                  child: EpWidget(
                    comicId: id,
                    series: series1,
                    comicInfo: comicInfo,
                    epsNumber: comicInfo.series.length,
                  ),
                ),
                if (series2 != null) const SizedBox(width: 8),
                if (series2 != null)
                  Expanded(
                    child: EpWidget(
                      comicId: id,
                      series: series2,
                      comicInfo: comicInfo,
                      epsNumber: comicInfo.series.length,
                    ),
                  ),
                SizedBox(width: 5),
              ],
            ),
          ),
        );
      }
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

    return Row(
      children: [
        SizedBox(width: screenWidth / 50),
        Expanded(
          child: ListView.builder(
            itemCount: comicInfoWidgets.length,
            itemBuilder: (context, index) => comicInfoWidgets[index],
          ),
        ),
        SizedBox(width: screenWidth / 50),
      ],
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
      .let(int.parse)
      .let(
        (timestamp) => DateTime.fromMillisecondsSinceEpoch(
          timestamp * 1000,
        ).toUtc().toString().let((str) => str.substring(0, str.length - 5)),
      );
}
