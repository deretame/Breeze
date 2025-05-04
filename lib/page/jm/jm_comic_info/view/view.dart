import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/jm/jm_comic_info/jm_comic_info.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/widgets/toast.dart';

import '../../../../config/global/global.dart';
import '../../../../network/http/jm/picture.dart';
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
  @override
  void initState() {
    super.initState();
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
      floatingActionButton: SizedBox(
        width: 100,
        height: 56,
        child: FloatingActionButton(
          onPressed: () {},
          child: Text('开始阅读', overflow: TextOverflow.ellipsis, maxLines: 1),
        ),
      ),
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
    final comicInfo = state.comicInfo!;
    final id = comicInfo.id.toString();

    if (comicInfo.name.isEmpty) {
      return Center(
        child: Text('不存在id为$id的漫画', style: TextStyle(fontSize: 20)),
      );
    }

    List<Widget> comicInfoWidgets = [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start, // 让Row内部元素顶部对齐
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
                  style: TextStyle(fontSize: 18),
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
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      ComicOperationWidget(comicInfo: comicInfo),
      const SizedBox(height: 10),
      if (comicInfo.tags.isNotEmpty)
        AllChipWidget(comicId: id, type: 'tags', chips: comicInfo.tags),
      if (comicInfo.author.isNotEmpty)
        AllChipWidget(comicId: id, type: 'author', chips: comicInfo.author),
      if (comicInfo.actors.isNotEmpty)
        AllChipWidget(comicId: id, type: 'actors', chips: comicInfo.actors),
      if (comicInfo.works.isNotEmpty)
        AllChipWidget(comicId: id, type: 'works', chips: comicInfo.works),
      if (comicInfo.description.isNotEmpty) ...[
        const SizedBox(height: 3),
        Text(
          comicInfo.description,
          style: TextStyle(fontSize: 16),
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
      ],
      if (comicInfo.series.isNotEmpty) ...[
        const SizedBox(height: 10),
        EpsWidget(comicId: id, seriesList: comicInfo.series),
      ],
    ];

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: screenWidth / 50),
      child: ListView.builder(
        itemCount: comicInfoWidgets.length,
        itemBuilder: (context, index) => comicInfoWidgets[index],
      ),
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
