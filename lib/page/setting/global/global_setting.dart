import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/sync/sync_service.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/impeller_config.dart';
import 'package:zephyr/widgets/toast.dart';

import '../../../util/event/event.dart';
import '../../../util/router/router.gr.dart';
import '../common/setting_ui.dart';
import 'widgets.dart';

@RoutePage()
class GlobalSettingPage extends StatefulWidget {
  const GlobalSettingPage({super.key});

  @override
  State<GlobalSettingPage> createState() => _GlobalSettingPageState();
}

class _GlobalSettingPageState extends State<GlobalSettingPage> {
  final List<String> systemThemeList = ["跟随系统", "浅色模式", "深色模式"];
  final Map<String, int> systemTheme = {"跟随系统": 0, "浅色模式": 1, "深色模式": 2};
  final List<String> splashPageList = ["首页", "排行", "书架", "更多"];
  final Map<String, int> splashPage = {"首页": 0, "排行": 1, "书架": 2, "更多": 3};
  bool _impellerForceEnableSupported = false;

  @override
  void initState() {
    super.initState();
    _loadImpellerConfig();
  }

  Future<void> _loadImpellerConfig() async {
    final supported = await ImpellerConfig.isForceEnableSupported();
    final forceEnableImpeller = supported
        ? await ImpellerConfig.getForceEnableImpeller()
        : false;

    if (!mounted) return;

    final cubit = context.read<GlobalSettingCubit>();
    if (cubit.state.forceEnableImpeller != forceEnableImpeller) {
      cubit.updateState(
        (current) => current.copyWith(forceEnableImpeller: forceEnableImpeller),
      );
    }

    setState(() {
      _impellerForceEnableSupported = supported;
    });
  }

  @override
  Widget build(BuildContext context) {
    final globalSettingCubit = context.watch<GlobalSettingCubit>();
    final state = globalSettingCubit.state;
    final configuredSync = isSyncServiceConfigured(state);

    return Scaffold(
      appBar: AppBar(title: const Text('全局设置')),
      body: ListView(
        padding: kSettingPagePadding,
        children: [
          SettingSectionCard(
            title: '外观与显示',
            icon: Icons.palette_outlined,
            children: [
              _systemTheme(state, globalSettingCubit),
              _dynamicColor(state, globalSettingCubit),
              if (!state.dynamicColor) changeThemeColor(context),
              _comicReadTopContainer(state, globalSettingCubit),
              _isAMOLED(state, globalSettingCubit),
            ],
          ),
          const SizedBox(height: 12),
          SettingSectionCard(
            title: '内容与网络',
            icon: Icons.tune_outlined,
            children: [
              editMaskedKeywords(context),
              socks5ProxyEdit(context, state.socks5Proxy),
              _updateAccelerate(state, globalSettingCubit),
            ],
          ),
          const SizedBox(height: 12),
          SettingSectionCard(
            title: '同步',
            icon: Icons.sync_outlined,
            children: [
              _syncServiceType(state, globalSettingCubit),
              webdavSync(context, state.syncServiceType),
              if (configuredSync) _autoSync(state, globalSettingCubit),
              if (configuredSync && state.autoSync)
                _syncNotify(state, globalSettingCubit),
              if (configuredSync) _syncSettings(state, globalSettingCubit),
            ],
          ),
          const SizedBox(height: 12),
          SettingSectionCard(
            title: '应用行为',
            icon: Icons.settings_outlined,
            children: [
              _splashPage(state, globalSettingCubit),
              _disableBika(state, globalSettingCubit),
            ],
          ),

          const SizedBox(height: 12),
          SettingSectionCard(
            title: '调试',
            icon: Icons.bug_report_outlined,
            children: [
              _enableMemoryDebug(state, globalSettingCubit),
              _forceEnableImpeller(state, globalSettingCubit),
              if (kDebugMode) ...[
                ListTile(
                  leading: const Icon(Icons.colorize_outlined),
                  title: const Text('整点颜色看看'),
                  subtitle: const Text('打开调色页，快速预览主题色'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    AutoRouter.of(context).push(ShowColorRoute());
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.login_outlined),
                  title: const Text('测试禁漫登录'),
                  subtitle: const Text('进入登录流程，验证账号状态'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    // jmSetting.deleteUserInfo();
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _systemTheme(GlobalSettingState state, GlobalSettingCubit cubit) {
    String currentTheme = "";
    switch (state.themeMode) {
      case ThemeMode.system:
        currentTheme = "跟随系统";
        break;
      case ThemeMode.light:
        currentTheme = "浅色模式";
        break;
      case ThemeMode.dark:
        currentTheme = "深色模式";
        break;
    }

    return ListTile(
      leading: const Icon(Icons.dark_mode_outlined),
      title: const Text('主题模式'),
      subtitle: const Text('选择策略，切换明暗主题'),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentTheme,
          icon: const Icon(Icons.expand_more),
          onChanged: (String? value) {
            if (value != null) {
              switch (value) {
                case "跟随系统":
                  cubit.updateState(
                    (current) => current.copyWith(themeMode: ThemeMode.system),
                  );
                  break;
                case "浅色模式":
                  cubit.updateState(
                    (current) => current.copyWith(themeMode: ThemeMode.light),
                  );
                  break;
                case "深色模式":
                  cubit.updateState(
                    (current) => current.copyWith(themeMode: ThemeMode.dark),
                  );
                  break;
              }
            }
          },
          items: systemThemeList.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          style: TextStyle(color: context.textColor, fontSize: 15),
        ),
      ),
    );
  }

  Widget _dynamicColor(GlobalSettingState state, GlobalSettingCubit cubit) {
    return SwitchListTile(
      secondary: const Icon(Icons.color_lens_outlined),
      title: const Text('动态取色'),
      subtitle: const Text('开启后自动提取内容主色'),
      thumbIcon: kSettingSwitchThumbIcon,
      value: state.dynamicColor,
      onChanged: (bool value) {
        cubit.updateState((current) => current.copyWith(dynamicColor: value));
      },
    );
  }

  Widget _isAMOLED(GlobalSettingState state, GlobalSettingCubit cubit) {
    return SwitchListTile(
      secondary: const Icon(Icons.contrast_outlined),
      title: const Text('纯黑模式'),
      subtitle: const Text('开启后使用纯黑背景，适配 AMOLED'),
      thumbIcon: kSettingSwitchThumbIcon,
      value: state.isAMOLED,
      onChanged: (bool value) {
        cubit.updateState((current) => current.copyWith(isAMOLED: value));
      },
    );
  }

  Widget _autoSync(GlobalSettingState state, GlobalSettingCubit cubit) {
    return SwitchListTile(
      secondary: const Icon(Icons.cloud_sync_outlined),
      title: const Text('自动同步'),
      subtitle: const Text('开启后在后台定期同步配置'),
      thumbIcon: kSettingSwitchThumbIcon,
      value: state.autoSync,
      onChanged: (bool value) {
        cubit.updateSyncSetting((current) => current.copyWith(autoSync: value));
        if (value) {
          eventBus.fire(NoticeSync());
        }
      },
    );
  }

  Widget _updateAccelerate(GlobalSettingState state, GlobalSettingCubit cubit) {
    return SwitchListTile(
      secondary: const Icon(Icons.rocket_launch_outlined),
      title: const Text('更新下载加速'),
      subtitle: const Text('开启后优先使用代理加速 GitHub 更新链接'),
      thumbIcon: kSettingSwitchThumbIcon,
      value: state.updateAccelerate,
      onChanged: (bool value) {
        cubit.updateState(
          (current) => current.copyWith(updateAccelerate: value),
        );
      },
    );
  }

  Widget _syncServiceType(GlobalSettingState state, GlobalSettingCubit cubit) {
    return ListTile(
      leading: const Icon(Icons.storage_outlined),
      title: const Text('同步服务'),
      subtitle: const Text('选择服务，统一管理同步策略'),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<SyncServiceType>(
          value: state.syncServiceType,
          icon: const Icon(Icons.expand_more),
          onChanged: (SyncServiceType? value) {
            if (value == null || value == state.syncServiceType) {
              return;
            }

            cubit.updateSyncSetting(
              (current) => current.copyWith(
                syncServiceType: value,
                syncSettings: value == SyncServiceType.none
                    ? false
                    : current.syncSettings,
              ),
            );
          },
          items: SyncServiceType.values
              .map(
                (value) => DropdownMenuItem<SyncServiceType>(
                  value: value,
                  child: Text(value.label),
                ),
              )
              .toList(),
          style: TextStyle(color: context.textColor, fontSize: 15),
        ),
      ),
    );
  }

  Widget _syncNotify(GlobalSettingState state, GlobalSettingCubit cubit) {
    return SwitchListTile(
      secondary: const Icon(Icons.notifications_active_outlined),
      title: const Text('自动同步通知'),
      subtitle: const Text('开启后在同步开始与完成时提醒'),
      thumbIcon: kSettingSwitchThumbIcon,
      value: state.syncNotify,
      onChanged: (bool value) {
        cubit.updateSyncSetting(
          (current) => current.copyWith(syncNotify: value),
        );
      },
    );
  }

  Widget _syncSettings(GlobalSettingState state, GlobalSettingCubit cubit) {
    return SwitchListTile(
      secondary: const Icon(Icons.tune_outlined),
      title: const Text('同步设置'),
      subtitle: const Text('开启后使用云端设置覆盖本地设置'),
      thumbIcon: kSettingSwitchThumbIcon,
      value: state.syncSettings,
      onChanged: (bool value) {
        cubit.updateSyncSetting(
          (current) => current.copyWith(syncSettings: value),
        );
      },
    );
  }

  Widget _comicReadTopContainer(
    GlobalSettingState state,
    GlobalSettingCubit cubit,
  ) {
    return SwitchListTile(
      secondary: const Icon(Icons.smartphone_outlined),
      title: const Text('异形屏适配'),
      subtitle: const Text('开启后预留安全区，避免内容遮挡'),
      thumbIcon: kSettingSwitchThumbIcon,
      value: state.comicReadTopContainer,
      onChanged: (bool value) {
        cubit.updateReadSetting(
          (current) => current.copyWith(comicReadTopContainer: value),
        );
      },
    );
  }

  Widget _splashPage(GlobalSettingState state, GlobalSettingCubit cubit) {
    return ListTile(
      leading: const Icon(Icons.rocket_launch_outlined),
      title: const Text('开屏页'),
      subtitle: const Text('选择启动页，打开应用直达目标'),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: splashPageList[state.welcomePageNum],
          icon: const Icon(Icons.expand_more),
          onChanged: (String? value) {
            if (value != null) {
              showSuccessToast("设置成功，重启生效");
              cubit.updateState(
                (current) =>
                    current.copyWith(welcomePageNum: splashPage[value]!),
              );
            }
          },
          items: splashPageList.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          style: TextStyle(color: context.textColor, fontSize: 15),
        ),
      ),
    );
  }

  Widget _disableBika(GlobalSettingState state, GlobalSettingCubit cubit) {
    return SwitchListTile(
      secondary: const Icon(Icons.block_outlined),
      title: const Text('禁用哔咔相关功能'),
      subtitle: const Text('开启后隐藏相关入口，重启生效'),
      thumbIcon: kSettingSwitchThumbIcon,
      value: state.disableBika,
      onChanged: (bool value) {
        cubit.updateState(
          (current) => current.copyWith(disableBika: value, comicChoice: 2),
        );
        showSuccessToast("设置成功，重启生效");
      },
    );
  }

  Widget _enableMemoryDebug(
    GlobalSettingState state,
    GlobalSettingCubit cubit,
  ) {
    return SwitchListTile(
      secondary: const Icon(Icons.memory_outlined),
      title: const Text('启用内存调试'),
      subtitle: const Text('开启后记录内存信息，用于问题排查'),
      thumbIcon: kSettingSwitchThumbIcon,
      value: state.enableMemoryDebug,
      onChanged: (bool value) {
        cubit.updateState(
          (current) => current.copyWith(enableMemoryDebug: value),
        );
      },
    );
  }

  Widget _forceEnableImpeller(
    GlobalSettingState state,
    GlobalSettingCubit cubit,
  ) {
    final supported = _impellerForceEnableSupported;
    return SwitchListTile(
      secondary: const Icon(Icons.auto_awesome_outlined),
      title: const Text('强制开启 Impeller'),
      subtitle: Text(
        supported
            ? '仅对 Adreno 800 系列生效；开启后强制启用 Impeller，重启生效'
            : '当前设备不是 Adreno 800 系列，此开关无效',
      ),
      thumbIcon: kSettingSwitchThumbIcon,
      value: supported && state.forceEnableImpeller,
      onChanged: supported
          ? (bool value) async {
              cubit.updateState(
                (current) => current.copyWith(forceEnableImpeller: value),
              );
              await ImpellerConfig.setForceEnableImpeller(value);
              showSuccessToast('设置成功，重启生效');
            }
          : null,
    );
  }
}
