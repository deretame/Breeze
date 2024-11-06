import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/global.dart';
import '../../../json/creator_ranking.dart';
import '../../../main.dart';
import '../../../type/search_enter.dart';
import '../../../util/router.dart';
import '../../../widgets/picture_bloc/bloc/picture_bloc.dart';
import '../../../widgets/picture_bloc/models/picture_info.dart';
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
        SizedBox(
          height: (screenHeight / 10) * 0.1,
        ),
        InkWell(
          onTap: () {
            navigateTo(
              context,
              '/search',
              extra: SearchEnter(
                  url:
                      "https://picaapi.picacomic.com/comics?ca=58f649a80a48790773c7017c&s=ld&page=1",
                  keyword: user.id.toString()),
            );
          },
          child: Container(
            height: 75,
            width: screenWidth * (48 / 50),
            decoration: BoxDecoration(
              color: globalSetting.backgroundColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: globalSetting.themeType
                      ? Colors.black.withOpacity(0.2)
                      : Colors.white.withOpacity(0.2),
                  spreadRadius: 2,
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
                BlocProvider(
                  create: (_) => PictureBloc()
                    ..add(
                      GetPicture(
                        PictureInfo(
                          from: "bika",
                          url: user.avatar.fileServer,
                          path: user.avatar.path,
                          pictureType: "cover",
                        ),
                      ),
                    ),
                  child: CreatorPictureWidget(
                    fileServer: user.avatar.fileServer,
                    path: user.avatar.path,
                    pictureType: "creator",
                  ),
                ),
                const SizedBox(width: 15),
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        user.name,
                        style: const TextStyle(
                          color: Colors.red,
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
          ),
        ),
      ],
    );
  }
}
