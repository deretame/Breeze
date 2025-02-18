import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:zephyr/page/search_result/models/models.dart';
import 'package:zephyr/util/router/router.gr.dart';

import '../../../config/global.dart';
import '../../../main.dart';
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

    return Column(
      children: <Widget>[
        SizedBox(height: (screenHeight / 10) * 0.1),
        GestureDetector(
          onTap: () {
            AutoRouter.of(context).push(
              SearchResultRoute(
                searchEnterConst: SearchEnterConst(
                  from: "bika",
                  url:
                      "https://picaapi.picacomic.com/comics?ca=${user.id}&s=ld&page=1",
                  type: "creator",
                  keyword: user.name,
                ),
              ),
            );
          },
          child: Observer(
            builder: (context) {
              return Container(
                height: 75,
                width: screenWidth * (48 / 50),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(width: 15),
                    CreatorPictureWidget(
                      fileServer: user.avatar.fileServer,
                      path: user.avatar.path,
                      pictureType: "creator",
                    ),
                    const SizedBox(width: 15),
                    Flexible(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            user.name,
                            style: TextStyle(
                              color: materialColorScheme.tertiary,
                            ),
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
              );
            },
          ),
        ),
      ],
    );
  }
}
