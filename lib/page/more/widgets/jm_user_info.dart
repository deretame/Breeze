import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:zephyr/config/global/global.dart';
import 'package:zephyr/config/jm/jm_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/page/more/json/jm/jm_user_info_json.dart';
import 'package:zephyr/page/more/widgets/user_avatar.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/widgets/picture_bloc/models/picture_info.dart';

class JMUserInfoWidget extends StatefulWidget {
  const JMUserInfoWidget({super.key});

  @override
  State<JMUserInfoWidget> createState() => _JMUserInfoWidgetState();
}

class _JMUserInfoWidgetState extends State<JMUserInfoWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Observer(
          builder: (_) {
            switch (jmSetting.loginStatus) {
              case LoginStatus.login:
                return _JMWidget(
                  key: ValueKey(jmSetting.userInfo),
                  jmUserInfoJson: jmSetting.userInfo.let(
                    jmUserInfoJsonFromJson,
                  ),
                );
              case LoginStatus.loggingIn:
                return SizedBox(
                  height: 90,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(10.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              case LoginStatus.logout:
                return SizedBox(
                  height: 90,
                  child: Center(
                    child: TextButton(
                      onPressed: () {
                        context.pushRoute(LoginRoute(from: From.jm));
                      },
                      child: Text("前往登录"),
                    ),
                  ),
                );
            }
          },
        ),
        GestureDetector(
          onTap: () {
            context.pushRoute(JMSettingRoute());
            // logger.d("禁漫设置");
          },
          behavior: HitTestBehavior.opaque, // 使得所有透明区域也可以响应点击
          child: SizedBox(
            width: screenWidth - 16 - 16,
            height: 40, // 设置固定高度
            child: SizedBox(
              width: screenWidth - 16 - 16,
              height: 40, // 设置固定高度
              child: Row(
                children: [
                  Icon(Icons.person),
                  SizedBox(width: 10),
                  Text("禁漫设置", style: TextStyle(fontSize: 22)),
                  Spacer(), // 填充剩余空间，但不影响点击
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _JMWidget extends StatelessWidget {
  final JmUserInfoJson jmUserInfoJson;

  const _JMWidget({required this.jmUserInfoJson, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // 添加此行以居中
        children: <Widget>[
          Center(
            child: Row(
              children: <Widget>[
                UserAvatar(
                  pictureInfo: PictureInfo(
                    from: "jm",
                    url: getUserCover(jmUserInfoJson.photo),
                    path: "${jmUserInfoJson.photo}.jpg",
                    chapterId: "",
                    pictureType: "avatar",
                  ),
                ),
                SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(jmUserInfoJson.username),
                      Text(
                        "level: ${jmUserInfoJson.level.toString()}  (${jmUserInfoJson.levelName})",
                      ),
                      Text(
                        "经验值: ${jmUserInfoJson.exp}/${jmUserInfoJson.nextLevelExp}",
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 5),
        ],
      ),
    );
  }
}
