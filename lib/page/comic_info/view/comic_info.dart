import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:zephyr/util/router/router.gr.dart';

import '../../../config/global.dart';
import '../../../widgets/error_view.dart';
import '../comic_info.dart';
import '../json/comic_info/comic_info.dart';

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

class _ComicInfoState extends State<_ComicInfo> {
  @override
  void initState() {
    EasyLoading.instance.animationStyle = EasyLoadingAnimationStyle.offset;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              AutoRouter.of(context).pushAndPopUntil(
                MainRoute(),
                predicate: (Route<dynamic> route) {
                  return false; // 只要不是 MainRoute，就会被移除
                },
              );
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
              return ErrorView(
                errorMessage: '加载失败，请重试。',
                onRetry: () {
                  context
                      .read<GetComicInfoBloc>()
                      .add(GetComicInfo(widget.comicId));
                },
              );
            case GetComicInfoStatus.success:
              return _InfoView(comicInfo: state.comicInfo!);
          }
        },
      ),
    );
  }
}

class _InfoView extends StatelessWidget {
  final Comic comicInfo;

  const _InfoView({required this.comicInfo});

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
                  EpsWidget(comicInfo: comicInfo),
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
