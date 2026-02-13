import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/page/search_result/bloc/search_bloc.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/router/router.gr.dart';

import '../json/knight_leaderboard.dart';
import 'creator_picture.dart';

class CreatorEntryWidget extends StatefulWidget {
  final User user;

  const CreatorEntryWidget({super.key, required this.user});

  @override
  State<CreatorEntryWidget> createState() => _CreatorEntryWidgetState();
}

class _CreatorEntryWidgetState extends State<CreatorEntryWidget>
    with AutomaticKeepAliveClientMixin<CreatorEntryWidget> {
  User get user => widget.user;

  @override
  bool get wantKeepAlive => true; // 这将告诉Flutter保持这个页面状态

  @override
  Widget build(BuildContext context) {
    super.build(context); // 确保调用super.build

    final materialColorScheme = context.theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              AutoRouter.of(context).push(
                SearchResultRoute(
                  searchEvent: SearchEvent().copyWith(
                    searchStates: SearchStates.initial(
                      context,
                    ).copyWith(from: From.bika, searchKeyword: user.name),
                    url:
                        "https://picaapi.picacomic.com/comics?ca=${user.id}&s=ld&page=1",
                  ),
                ),
              );
            },
            child: Container(
              height: 75,
              width: context.screenWidth * (48 / 50),
              decoration: BoxDecoration(
                color: context.backgroundColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: materialColorScheme.secondaryFixedDim,
                    spreadRadius: 0,
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(width: 15),
                  CreatorPictureWidget(
                    fileServer: user.avatar.fileServer,
                    path: user.avatar.path,
                    pictureType: PictureType.creator,
                  ),
                  const SizedBox(width: 15),
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          user.name,
                          style: TextStyle(color: materialColorScheme.tertiary),
                        ),
                        Row(
                          children: <Widget>[
                            Text("等级：${user.level.toString()}"),
                            SizedBox(width: 30),
                            Text("总上传数：${user.comicsUploaded.toString()}"),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
