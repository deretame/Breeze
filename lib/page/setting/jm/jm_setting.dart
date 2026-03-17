import 'package:zephyr/util/ui/fluent_compat.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/jm/jm_setting.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/router/router.gr.dart';

import '../common/setting_ui.dart';

@RoutePage()
class JMSettingPage extends StatefulWidget {
  const JMSettingPage({super.key});

  @override
  State<JMSettingPage> createState() => _JMSettingPageState();
}

class _JMSettingPageState extends State<JMSettingPage> {
  @override
  Widget build(BuildContext context) {
    final jmCubit = context.read<JmSettingCubit>();

    return Scaffold(
      appBar: AppBar(title: const Text('禁漫设置')),
      body: ListView(
        padding: kSettingPagePadding,
        children: [
          SettingSectionCard(
            title: '账号管理',
            icon: Icons.person_outline,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  style: settingDangerButtonStyle(context),
                  onPressed: () {
                    jmCubit.resetUserInfo();
                    jmCubit.updateLoginStatus(LoginStatus.logout);
                    context.pushRoute(LoginRoute(from: From.jm));
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('退出当前账号'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


