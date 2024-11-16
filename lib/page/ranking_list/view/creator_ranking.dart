import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/creator_list/creator_list_bloc.dart';
import '../models/get_info.dart';
import '../widgets/widgets.dart';

class CreatorRankingsWidget extends StatefulWidget {
  const CreatorRankingsWidget({super.key});

  @override
  State<CreatorRankingsWidget> createState() => _CreatorRankingsWidgetState();
}

class _CreatorRankingsWidgetState extends State<CreatorRankingsWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // 确保状态保持

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocBuilder<CreatorListBloc, CreatorListState>(
      builder: (context, state) {
        switch (state.status) {
          case CreatorListStatus.failure:
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(state.result!),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<CreatorListBloc>()
                          .add(FetchCreatorList(GetInfo(type: 'comic')));
                    },
                    child: const Text('重新加载'),
                  ),
                ],
              ),
            );
          case CreatorListStatus.success:
            return Column(
              children: <Widget>[
                // 使用 map 和 Padding 创建 ComicEntryWidget 列表
                ...state.userList!.map(
                  (user) => CreatorEntryWidget(
                    user: user,
                  ),
                ),
                SizedBox(
                  height: 80,
                ),
              ],
            );
          case CreatorListStatus.initial:
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
