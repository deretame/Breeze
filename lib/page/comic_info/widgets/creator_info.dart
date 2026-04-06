import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart';
import 'package:zephyr/page/comic_info/models/comic_info_action.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/page/search_result/bloc/search_bloc.dart';
import '../../../util/router/router.gr.dart';
import '../../../widgets/creator_link_card.dart';

// 显示上传者信息
class CreatorInfoWidget extends StatelessWidget {
  final Creator creator;
  final String from;
  final String imageKey;
  final List<Widget> infoChildren;

  const CreatorInfoWidget({
    super.key,
    required this.creator,
    required this.from,
    required this.imageKey,
    this.infoChildren = const [],
  });

  @override
  Widget build(BuildContext context) {
    return CreatorLinkCard(
      creatorName: creator.name,
      avatarUrl: creator.avatar.url,
      avatarPath: creator.avatar.path,
      imageKey: imageKey,
      from: from,
      infoChildren: infoChildren,
      onTap: creator.onTap.isNotEmpty
          ? () => handleComicInfoAction(
              context,
              creator.onTap,
              fallbackPluginId: from,
            )
          : creator.id.isEmpty
          ? null
          : () {
              AutoRouter.of(context).push(
                SearchResultRoute(
                  searchEvent: SearchEvent().copyWith(
                    searchStates: SearchStates.initial().copyWith(
                      from: from,
                      searchKeyword: creator.name,
                      pluginExtern: {
                        'mode': 'creator',
                        'creatorId': creator.id,
                      },
                    ),
                  ),
                ),
              );
            },
      errorAssetPath: 'asset/image/assets/default_cover.png',
    );
  }
}
