import 'package:auto_route/auto_route.dart';
import 'package:zephyr/util/ui/fluent_compat.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/bika/bika_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/more/more.dart';
import 'package:zephyr/page/more/widgets/user_avatar.dart';
import 'package:zephyr/type/enum.dart';
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
      child: const _BikaUserInfoWidget(),
    );
  }
}

class _BikaUserInfoWidget extends StatefulWidget {
  const _BikaUserInfoWidget();

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
                      icon: const Icon(Icons.refresh),
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
        ListTile(
          leading: const Icon(Icons.manage_accounts_outlined),
          title: const Text('哔咔设置'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            context.pushRoute(BikaSettingRoute());
          },
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
    context.read<BikaSettingCubit>().updateSignIn(profile.data.user.isPunched);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
          child: Row(
            children: <Widget>[
              UserAvatar(
                pictureInfo: PictureInfo(
                  from: From.bika,
                  url: profile.data.user.avatar.fileServer,
                  path: profile.data.user.avatar.path,
                  chapterId: '',
                  pictureType: PictureType.avatar,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${profile.data.user.name} (${profile.data.user.slogan})',
                    ),
                    Text(
                      'Lv.${profile.data.user.level} ${profile.data.user.title}',
                    ),
                    Text(
                      '经验值: ${profile.data.user.exp} (${profile.data.user.isPunched ? '已签到' : '未签到'})',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        buildCommentWidget(context),
      ],
    );
  }
}


