import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/more/more.dart';
import 'package:zephyr/page/more/widgets/user_avatar.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/router/router.gr.dart';

import '../../../../widgets/picture_bloc/models/picture_info.dart';
import '../json/bika/profile.dart';

class RefreshEvent {}

class BikaUserInfoWidget extends StatelessWidget {
  const BikaUserInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UserProfileBloc()..add(UserProfileEvent()),
      child: _BikaUserInfoWidget(),
    );
  }
}

class _BikaUserInfoWidget extends StatefulWidget {
  @override
  State<_BikaUserInfoWidget> createState() => _BikaUserInfoWidgetState();
}

class _BikaUserInfoWidgetState extends State<_BikaUserInfoWidget> {
  @override
  void initState() {
    super.initState();
    eventBus.on<RefreshEvent>().listen((event) {
      _onRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocBuilder<UserProfileBloc, UserProfileState>(
          builder: (context, state) {
            switch (state.status) {
              case UserProfileStatus.initial:
                return SizedBox(
                  height: 130,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              case UserProfileStatus.failure:
                return SizedBox(
                  height: 130,
                  child: Center(
                    child: IconButton(
                      icon: Icon(Icons.refresh),
                      onPressed: () {
                        context.read<UserProfileBloc>().add(UserProfileEvent());
                      },
                    ),
                  ),
                );
              case UserProfileStatus.success:
                return Center(child: _BikaWidget(profile: state.profile!));
            }
          },
        ),
        GestureDetector(
          onTap: () {
            context.pushRoute(BikaSettingRoute());
            // logger.d("哔咔设置");
          },
          behavior: HitTestBehavior.opaque, // 使得所有透明区域也可以响应点击
          child: SizedBox(
            width: context.screenWidth - 16 - 16,
            height: 40, // 设置固定高度
            child: SizedBox(
              width: context.screenWidth - 16 - 16,
              height: 40, // 设置固定高度
              child: Row(
                children: [
                  Icon(Icons.person),
                  SizedBox(width: 10),
                  Text("哔咔设置", style: TextStyle(fontSize: 22)),
                  Spacer(), // 填充剩余空间，但不影响点击
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onRefresh() {
    context.read<UserProfileBloc>().add(UserProfileEvent());
  }
}

class _BikaWidget extends StatelessWidget {
  final Profile profile;

  const _BikaWidget({required this.profile});

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
                    from: "bika",
                    url: profile.data.user.avatar.fileServer,
                    path: profile.data.user.avatar.path,
                    chapterId: "",
                    pictureType: "avatar",
                  ),
                ),
                SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "${profile.data.user.name}  (${profile.data.user.slogan})",
                      ),
                      Text(
                        "level: ${profile.data.user.level.toString()}  (${profile.data.user.title})",
                      ),
                      Observer(
                        builder: (context) {
                          return Text(
                            "经验值: ${profile.data.user.exp.toString()} (${bikaSetting.signIn ? "已签到" : "未签到"})",
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 5),
          buildCommentWidget(context),
        ],
      ),
    );
  }
}
