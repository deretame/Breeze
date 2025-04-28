import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/global/global.dart';
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
                      context.read<CreatorListBloc>().add(
                        FetchCreatorList(GetInfo(type: 'creator')),
                      );
                    },
                    child: const Text('重新加载'),
                  ),
                ],
              ),
            );
          case CreatorListStatus.success:
            return RefreshIndicator(
              onRefresh: () async {
                context.read<CreatorListBloc>().add(
                  FetchCreatorList(GetInfo(type: 'creator')),
                );
              },
              child: ListView.builder(
                itemCount: state.userList!.length + 1, // 加1以包含底部留白
                itemBuilder: (context, index) {
                  if (index == state.userList!.length) {
                    return SizedBox(height: 10); // 底部留白
                  }
                  final user = state.userList![index];
                  return CreatorEntryWidget(user: user);
                },
                controller: scrollControllers['creator']!,
              ),
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
