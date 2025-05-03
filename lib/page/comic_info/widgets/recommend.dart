import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../config/global/global.dart';
import '../../../main.dart';
import '../../../type/enum.dart';
import '../../../widgets/comic_simplify_entry/comic_simplify_entry.dart';
import '../../../widgets/comic_simplify_entry/comic_simplify_entry_info.dart';
import '../../../widgets/error_view.dart';
import '../bloc/bika/recommend/recommend_bloc.dart';

class RecommendWidget extends StatelessWidget {
  final String comicId;

  final ComicEntryType type;

  const RecommendWidget({super.key, required this.comicId, required this.type});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) =>
              RecommendBloc()
                ..add(RecommendEvent(comicId, RecommendStatus.initial)),
      child: _RecommendWidget(comicId: comicId, type: type),
    );
  }
}

class _RecommendWidget extends StatelessWidget {
  final String comicId;
  final ComicEntryType type;

  const _RecommendWidget({required this.comicId, required this.type});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecommendBloc, RecommendState>(
      builder: (context, state) {
        switch (state.status) {
          case RecommendStatus.initial:
            return Center(child: CircularProgressIndicator());
          case RecommendStatus.failure:
            return type == ComicEntryType.download
                ? SizedBox.shrink()
                : ErrorView(
                  errorMessage: '${state.result.toString()}\n加载失败，请重试。',
                  onRetry: () {
                    context.read<RecommendBloc>().add(
                      RecommendEvent(comicId, RecommendStatus.initial),
                    );
                  },
                );
          case RecommendStatus.success:
            return successWidget(state);
        }
      },
    );
  }

  Widget successWidget(RecommendState state) {
    // logger.d('RecommendWidget successWidget');
    if (state.comicList == null) {
      return SizedBox.shrink();
    }
    final comicInfoList =
        state.comicList!
            .map(
              (e) => ComicSimplifyEntryInfo(
                title: e.title,
                id: e.id,
                fileServer: e.thumb.fileServer,
                path: e.thumb.path,
                pictureType: "cover",
                from: "bika",
              ),
            )
            .toList();

    return Observer(
      builder: (context) {
        return Container(
          height: screenWidth * 0.3 / 0.75,
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
          child: ClipRRect(
            // 使用ClipRRect来裁剪子组件
            borderRadius: BorderRadius.circular(10),
            // 设置与外层Container相同的圆角
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(comicInfoList.length, (index) {
                  return ComicSimplifyEntry(
                    info: comicInfoList[index],
                    type: ComicEntryType.normal,
                    topPadding: false,
                    roundedCorner: false,
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}
