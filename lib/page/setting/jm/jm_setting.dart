import 'package:flutter/material.dart';
import 'package:zephyr/plugin/plugin_constants.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/jm/jm_setting.dart';
import 'package:zephyr/util/router/router.gr.dart';

import '../common/setting_ui.dart';
import '../common/plugin_scheme_widgets.dart';
import 'package:zephyr/type/enum.dart';

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
                    context.pushRoute(LoginRoute(from: kJmPluginUuid));
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('退出当前账号'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SettingSectionCard(
            title: '插件设置',
            icon: Icons.extension_outlined,
            children: [
              PluginSettingSchemeSection(
                from: kJmPluginUuid,
                pluginName: 'jmComic',
                onValueChanged: (key, value) async {
                  if (key == 'auth.account') {
                    jmCubit.updateAccount(value.toString());
                  }
                  if (key == 'auth.password') {
                    jmCubit.updatePassword(value.toString());
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          SettingSectionCard(
            title: '高级能力',
            icon: Icons.developer_mode_outlined,
            children: [PluginAdvancedActionSection(from: kJmPluginUuid)],
          ),
        ],
      ),
    );
  }
}
