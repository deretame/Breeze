import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/ranking_list/models/get_info.dart';

import '../../../config/global/global.dart';
import '../bloc/bloc.dart';
import '../widgets/widgets.dart';

class ComicRanking extends StatefulWidget {
  final String type;

  const ComicRanking({super.key, required this.type});

  @override
  State<ComicRanking> createState() => _ComicRankingState();
}

class _ComicRankingState extends State<ComicRanking>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  ScrollController get _scrollController {
    if (widget.type == 'H24') return scrollControllers['day']!;

    if (widget.type == 'D7') return scrollControllers['week']!;

    return scrollControllers['month']!;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocBuilder<ComicListBloc, ComicListState>(
      builder: (context, state) {
        switch (state.status) {
          case ComicListStatus.failure:
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(state.result!),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ComicListBloc>().add(
                        FetchComicList(
                          GetInfo(days: widget.type, type: 'comic'),
                        ),
                      );
                    },
                    child: const Text('重新加载'),
                  ),
                ],
              ),
            );
          case ComicListStatus.success:
            return RefreshIndicator(
              onRefresh: () async {
                context.read<ComicListBloc>().add(
                  FetchComicList(GetInfo(days: widget.type, type: 'comic')),
                );
              },
              child: ListView.builder(
                itemCount: state.comicList!.length + 1, // 加1为底部的空白部分（可选）
                itemBuilder: (context, index) {
                  if (index == state.comicList!.length) {
                    // 显示底部的空白部分
                    return SizedBox(height: 10);
                  }
                  final comic = state.comicList![index];
                  return ComicEntryWidget(comic: comic, type: widget.type);
                },
                controller: _scrollController,
              ),
            );
          case ComicListStatus.initial:
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(30.0),
                child: CircularProgressIndicator(),
              ),
            );
        }
      },
    );
  }
}
