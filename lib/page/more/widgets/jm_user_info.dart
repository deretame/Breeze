import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/jm/jm_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/page/more/json/jm/jm_user_info_json.dart';
import 'package:zephyr/page/more/widgets/user_avatar.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/widgets/picture_bloc/models/picture_info.dart';

class JMUserInfoWidget extends StatelessWidget {
  const JMUserInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JmSettingCubit, JmSettingState>(
      buildWhen: (prev, curr) =>
          prev.loginStatus != curr.loginStatus ||
          prev.userInfo != curr.userInfo,
      builder: (context, jmState) {
        // logger.d('JM User Info Raw: ${jmState.userInfo}');

        Widget contentWidget;

        switch (jmState.loginStatus) {
          case LoginStatus.login:
            if (jmState.userInfo.isEmpty) {
              logger.w("LoginStatus is login, but userInfo is empty.");
              contentWidget = _buildLoginButton(context);
            } else {
              try {
                // 尝试解析 JSON
                final userInfo = jmUserInfoJsonFromJson(jmState.userInfo);
                contentWidget = _JMWidget(
                  key: ValueKey(jmState.userInfo),
                  jmUserInfoJson: userInfo,
                );
              } catch (e, stackTrace) {
                logger.e(
                  "Failed to parse JmUserInfoJson: ${jmState.userInfo}",
                  error: e,
                  stackTrace: stackTrace,
                );
                contentWidget = _buildLoginButton(
                  context,
                  errorText: "用户信息解析失败",
                );
              }
            }
            break;
          case LoginStatus.loggingIn:
            contentWidget = SizedBox(
              height: 90,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(10.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            );
            break;
          case LoginStatus.logout:
            contentWidget = _buildLoginButton(context);
            break;
        }

        return Column(
          children: [
            contentWidget,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GestureDetector(
                onTap: () {
                  context.pushRoute(JMSettingRoute());
                },
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: context.screenWidth - 16 - 16,
                  height: 40,
                  child: Row(
                    children: [
                      Icon(Icons.person),
                      SizedBox(width: 10),
                      Text("禁漫设置", style: TextStyle(fontSize: 22)),
                      Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoginButton(BuildContext context, {String? errorText}) {
    return SizedBox(
      height: 90,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (errorText != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(errorText, style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () {
                context.pushRoute(LoginRoute(from: From.jm));
              },
              child: Text("前往登录"),
            ),
          ],
        ),
      ),
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
                    from: From.jm,
                    url: getUserCover(jmUserInfoJson.photo),
                    path: "${jmUserInfoJson.photo}.jpg",
                    chapterId: "",
                    pictureType: PictureType.avatar,
                  ),
                ),
                SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "${jmUserInfoJson.username} (硬币：${jmUserInfoJson.coin})",
                      ),
                      Text(
                        "level: ${jmUserInfoJson.level}  (${jmUserInfoJson.levelName})",
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
