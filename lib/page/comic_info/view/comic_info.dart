import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../../../config/global.dart';
import '../../../main.dart';
import '../../../object_box/model.dart';
import '../../../object_box/objectbox.g.dart';
import '../../../util/router/router.gr.dart';
import '../../../widgets/error_view.dart';
import '../comic_info.dart';
import '../json/comic_info/comic_info.dart';
import '../json/eps/eps.dart';

@RoutePage()
class ComicInfoPage extends StatelessWidget {
  final String comicId;

  const ComicInfoPage({
    super.key,
    required this.comicId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetComicInfoBloc()..add(GetComicInfo(comicId)),
      child: _ComicInfo(
        comicId: comicId,
      ),
    );
  }
}

class _ComicInfo extends StatefulWidget {
  final String comicId;

  const _ComicInfo({
    required this.comicId,
  });

  @override
  _ComicInfoState createState() => _ComicInfoState();
}

class _ComicInfoState extends State<_ComicInfo>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late BikaComicHistory? comicHistory;
  late Comic comicInfo; // 用来存储漫画信息

  bool epsCompleted = false; // 用来判断章节是不是加载完毕了
  late List<Doc> epsInfo;

  void _updateReadInfo(List<Doc> epsInfo, bool epsCompleted) {
    if (this.epsCompleted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          this.epsInfo = epsInfo;
          this.epsCompleted = epsCompleted;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    EasyLoading.instance.animationStyle = EasyLoadingAnimationStyle.offset;
    // 首先查询一下有没有记录
    final query = objectbox.bikaBox
        .query(BikaComicHistory_.comicId.equals(widget.comicId));
    comicHistory = query.build().findFirst();
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
            onPressed: () {
              context.router.popUntilRoot();
            },
          ),
          Expanded(child: Container()),
        ],
      ),
      body: BlocBuilder<GetComicInfoBloc, GetComicInfoState>(
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
                      Text(
                        '此漫画已下架',
                        style: TextStyle(fontSize: 20),
                      ),
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
                  context
                      .read<GetComicInfoBloc>()
                      .add(GetComicInfo(widget.comicId));
                },
              );
            case GetComicInfoStatus.success:
              comicInfo = state.comicInfo!;
              return _InfoView(
                comicInfo: state.comicInfo!,
                comicHistory: comicHistory,
                onUpdateReadInfo: _updateReadInfo,
              );
          }
        },
      ),
      floatingActionButton: epsCompleted // 条件显示按钮
          ? SizedBox(
              width: 100, // 设置容器宽度，以容纳更长的文本
              height: 56, // 设置容器高度，与默认的FloatingActionButton高度一致
              child: FloatingActionButton(
                onPressed: () {
                  if (comicHistory != null) {
                    AutoRouter.of(context).push(
                      ComicReadRoute(
                        comicInfo: comicInfo,
                        epsInfo: epsInfo,
                        doc: Doc(
                          id: "history",
                          title: comicHistory!.epTitle,
                          order: comicHistory!.order,
                          updatedAt: comicHistory!.history,
                          docId: (comicHistory!.epPageCount - 1).toString(),
                        ),
                        comicId: comicInfo.id,
                        isHistory: true,
                      ),
                    );
                  } else {
                    AutoRouter.of(context).push(
                      ComicReadRoute(
                        comicInfo: comicInfo,
                        epsInfo: epsInfo,
                        doc: epsInfo[0],
                        comicId: comicInfo.id,
                        isHistory: false,
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
}

class _InfoView extends StatelessWidget {
  final Comic comicInfo;
  final BikaComicHistory? comicHistory;
  final Function(List<Doc>, bool) onUpdateReadInfo; // 用来更新观看按钮信息

  const _InfoView({
    required this.comicInfo,
    required this.comicHistory,
    required this.onUpdateReadInfo,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: screenWidth,
      child: SingleChildScrollView(
        // 添加滚动视图包裹
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
                  const SizedBox(height: 3),
                  if (comicInfo.tags.isNotEmpty) ...[
                    TagsAndCategoriesWidget(
                      comicInfo: comicInfo,
                      type: 'tags',
                    ),
                    const SizedBox(height: 3),
                  ],
                  if (comicInfo.description != '') ...[
                    SynopsisWidget(comicInfo: comicInfo),
                  ],
                  const SizedBox(height: 10),
                  CreatorInfoWidget(comicInfo: comicInfo),
                  const SizedBox(height: 10),
                  const SizedBox(height: 10),
                  ComicOperationWidget(comicInfo: comicInfo),
                  const SizedBox(height: 10),
                  EpsWidget(
                    comicInfo: comicInfo,
                    comicHistory: comicHistory,
                    onUpdateReadInfo: onUpdateReadInfo,
                  ),
                  const SizedBox(height: 10),
                  RecommendWidget(comicId: comicInfo.id),
                  const SizedBox(height: 85),
                ],
              ),
            ),
            SizedBox(width: screenWidth / 50),
          ],
        ),
      ),
    );
  }
}
