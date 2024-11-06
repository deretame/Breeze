import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/ranking_list/models/get_info.dart';

import '../bloc/bloc.dart';
import '../widgets/widgets.dart';

class ComicRanking extends StatefulWidget {
  final String type;

  const ComicRanking({
    super.key,
    required this.type,
  });

  @override
  State<ComicRanking> createState() => _ComicRankingState();
}

class _ComicRankingState extends State<ComicRanking>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

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
                      context.read<ComicListBloc>().add(FetchComicList(
                          GetInfo(days: widget.type, type: 'comic')));
                    },
                    child: const Text('重新加载'),
                  ),
                ],
              ),
            );
          case ComicListStatus.success:
            return Column(
              children: [
                // 使用 map 和 Padding 创建 ComicEntryWidget 列表
                ...state.comicList!.map(
                  (comic) => ComicEntryWidget(
                    comic: comic,
                    type: widget.type,
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
              ],
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
