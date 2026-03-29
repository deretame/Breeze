import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/bika/bika_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/router/router.gr.dart';

import '../common/setting_ui.dart';
import '../common/plugin_scheme_widgets.dart';
import 'widgets.dart';

@RoutePage()
class BikaSettingPage extends StatefulWidget {
  const BikaSettingPage({super.key});

  @override
  State<BikaSettingPage> createState() => _BikaSettingPageState();
}

class _BikaSettingPageState extends State<BikaSettingPage> {
  final List<String> shuntList = ["1", "2", "3"];
  final Map<String, String> shunt = {"1": "1", "2": "2", "3": "3"};
  final List<String> imageQualityList = ["low", "medium", "high", "original"];
  final Map<String, String> imageQuality = {
    "low": "低画质",
    "medium": "中画质",
    "high": "高画质",
    "original": "原图",
  };

  @override
  Widget build(BuildContext context) {
    var route = context.router;

    final bikaCubit = context.watch<BikaSettingCubit>();
    final state = bikaCubit.state;

    return Scaffold(
      appBar: AppBar(title: const Text('哔咔设置')),
      body: ListView(
        padding: kSettingPagePadding,
        children: [
          SettingSectionCard(
            title: '账号',
            icon: Icons.person_outline,
            children: [
              changeProfilePicture(route),
              changeBriefIntroduction(context),
              changePassword(context),
            ],
          ),
          const SizedBox(height: 12),
          SettingSectionCard(
            title: '浏览与下载',
            icon: Icons.tune_outlined,
            children: [
              _shuntWidget(state, bikaCubit),
              _imageQualityWidget(state, bikaCubit),
              _brevityWidget(state, bikaCubit),
              _slowDownloadWidget(state, bikaCubit),
            ],
          ),
          const SizedBox(height: 12),
          SettingSectionCard(
            title: '插件设置',
            icon: Icons.extension_outlined,
            children: [
              PluginSettingSchemeSection(
                from: From.bika,
                pluginName: 'bikaComic',
                onValueChanged: (key, value) async {
                  if (key == 'image.quality') {
                    cacheInterceptor.clear();
                    bikaCubit.updateImageQuality(value.toString());
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          SettingSectionCard(
            title: '屏蔽设置',
            icon: Icons.visibility_off_outlined,
            children: [
              changeShieldedCategories(context, "home"),
              changeShieldedCategories(context, "categories"),
            ],
          ),
          const SizedBox(height: 12),
          SettingSectionCard(
            title: '高级能力',
            icon: Icons.developer_mode_outlined,
            children: [PluginAdvancedActionSection(from: From.bika)],
          ),
          const SizedBox(height: 12),
          SettingSectionCard(
            title: '账号操作',
            icon: Icons.manage_accounts_outlined,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  style: settingDangerButtonStyle(context),
                  onPressed: () async {
                    await callUnifiedComicPlugin(
                      from: From.bika,
                      fnPath: 'clearPluginSession',
                      core: const <String, dynamic>{},
                      extern: const <String, dynamic>{},
                    );
                    if (!mounted) return;
                    route.push(LoginRoute());
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

  Widget _shuntWidget(BikaSettingState state, BikaSettingCubit cubit) {
    return ListTile(
      leading: const Icon(Icons.route_outlined),
      title: const Text('分流设置'),
      subtitle: const Text('选择线路，优化访问稳定性'),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: state.proxy.toString(),
          icon: const Icon(Icons.expand_more),
          onChanged: (String? value) {
            if (value != null) {
              cubit.updateProxy(int.parse(value));
            }
          },
          items: shuntList.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(shunt[value]!),
            );
          }).toList(),
          style: TextStyle(color: context.textColor, fontSize: 15),
        ),
      ),
    );
  }

  Widget _imageQualityWidget(BikaSettingState state, BikaSettingCubit cubit) {
    return ListTile(
      leading: const Icon(Icons.image_outlined),
      title: const Text('图片质量'),
      subtitle: const Text('选择画质，切换时会清理缓存'),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: state.imageQuality,
          icon: const Icon(Icons.expand_more),
          onChanged: (String? value) {
            if (value != null) {
              cacheInterceptor.clear();
              cubit.updateImageQuality(value);
            }
          },
          items: imageQualityList.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(imageQuality[value]!),
            );
          }).toList(),
          style: TextStyle(color: context.textColor, fontSize: 15),
        ),
      ),
    );
  }

  Widget _brevityWidget(BikaSettingState state, BikaSettingCubit cubit) {
    return SwitchListTile(
      secondary: const Icon(Icons.view_agenda_outlined),
      title: const Text('漫画列表简略模式'),
      subtitle: const Text('开启后使用紧凑列表，提升浏览效率'),
      thumbIcon: kSettingSwitchThumbIcon,
      value: state.brevity,
      onChanged: (bool value) {
        cubit.updateBrevity(value);
      },
    );
  }

  Widget _slowDownloadWidget(BikaSettingState state, BikaSettingCubit cubit) {
    final theme = context.theme;
    return SwitchListTile(
      secondary: Icon(
        Icons.speed_outlined,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      title: const Text('慢速下载'),
      subtitle: const Text('开启后降低速度，减少卡顿与发热'),
      thumbIcon: kSettingSwitchThumbIcon,
      value: state.slowDownload,
      onChanged: (bool value) {
        cubit.updateSlowDownload(value);
      },
    );
  }
}
