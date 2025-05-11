import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/more/more.dart';
import 'package:zephyr/util/router/router.gr.dart';

import '../../../../widgets/full_screen_image_view.dart';
import '../../../../widgets/picture_bloc/bloc/picture_bloc.dart';
import '../../../../widgets/picture_bloc/models/picture_info.dart';
import '../../../config/global/global.dart';
import '../json/profile.dart';

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
                loadBikaProfile = false;
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${state.result.toString()}\n加载失败',
                          style: TextStyle(fontSize: 20),
                        ),
                        SizedBox(height: 10), // 添加间距
                        ElevatedButton(
                          onPressed: () {
                            context.read<UserProfileBloc>().add(
                              UserProfileEvent(),
                            );
                          },
                          child: Text('点击重试'),
                        ),
                      ],
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
            logger.d("哔咔设置");
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
                _UserAvatar(
                  pictureInfo: PictureInfo(
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

class _UserAvatar extends StatelessWidget {
  final PictureInfo pictureInfo;

  const _UserAvatar({required this.pictureInfo});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 75,
      width: 75,
      child: BlocProvider(
        create:
            (context) =>
                PictureBloc()..add(
                  GetPicture(
                    PictureInfo(
                      from: "bika",
                      url: pictureInfo.url,
                      path: pictureInfo.path,
                      cartoonId: pictureInfo.cartoonId,
                      pictureType: pictureInfo.pictureType,
                    ),
                  ),
                ),
        child: BlocBuilder<PictureBloc, PictureLoadState>(
          builder: (context, state) {
            switch (state.status) {
              case PictureLoadStatus.initial:
                loadBikaProfile = false;
                return Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: CircularProgressIndicator(),
                );
              case PictureLoadStatus.success:
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => FullScreenImagePage(
                              imagePath: state.imagePath!,
                            ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50.0),
                    child: Image.file(
                      File(state.imagePath!),
                      fit: BoxFit.cover,
                      width: 75,
                      height: 75,
                    ),
                  ),
                );
              case PictureLoadStatus.failure:
                loadBikaProfile = true;
                if (state.result.toString().contains('404')) {
                  return Image.asset('asset/image/error_image/404.png');
                } else {
                  return InkWell(
                    onTap: () {
                      context.read<PictureBloc>().add(
                        GetPicture(
                          PictureInfo(
                            from: "bika",
                            url: pictureInfo.url,
                            path: pictureInfo.path,
                            cartoonId: pictureInfo.cartoonId,
                            pictureType: pictureInfo.pictureType,
                          ),
                        ),
                      );
                    },
                    child: Icon(Icons.refresh),
                  );
                }
            }
          },
        ),
      ),
    );
  }
}
