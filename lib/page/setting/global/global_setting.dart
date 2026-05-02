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
  final List<String> splashPageList = ["书架", "发现"];
  final Map<String, int> splashPage = {"书架": 0, "发现": 1};
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
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final globalSettingCubit = context.watch<GlobalSettingCubit>();
    final state = globalSettingCubit.state;
    final configuredSync = isSyncServiceConfigured(state);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '全局设置',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 768),
          child: ListView(
            children: [
              _buildSectionTitle(context, '外观与显示', Icons.palette_outlined),
              _systemTheme(state, globalSettingCubit),
              _dynamicColor(state, globalSettingCubit),
              if (!state.dynamicColor) changeThemeColor(context),
              _comicReadTopContainer(state, globalSettingCubit),
              _isAMOLED(state, globalSettingCubit),

              const SizedBox(height: 8),
              const Divider(height: 1, thickness: 0.3),
              _buildSectionTitle(context, '内容与网络', Icons.tune_outlined),
              editMaskedKeywords(context),
              socks5ProxyEdit(context, state.socks5Proxy),
              _updateAccelerate(state, globalSettingCubit),

              const SizedBox(height: 8),
              const Divider(height: 1, thickness: 0.3),
              _buildSectionTitle(context, '同步', Icons.sync_outlined),
              _syncServiceType(state, globalSettingCubit),
              webdavSync(context, state.syncSetting.syncServiceType),
              if (configuredSync) _autoSync(state, globalSettingCubit),
              if (configuredSync && state.syncSetting.autoSync)
                _syncNotify(state, globalSettingCubit),
              if (configuredSync) _syncSettings(state, globalSettingCubit),
              if (configuredSync) _syncPlugins(state, globalSettingCubit),

              const SizedBox(height: 8),
              const Divider(height: 1, thickness: 0.3),
              _buildSectionTitle(context, '应用行为', Icons.settings_outlined),
              _splashPage(state, globalSettingCubit),
              _oldPageRollback(state, globalSettingCubit),

              const SizedBox(height: 8),
              const Divider(height: 1, thickness: 0.3),
              _buildSectionTitle(context, '调试', Icons.bug_report_outlined),
              _logAddress(state, globalSettingCubit),
              _enableMemoryDebug(state, globalSettingCubit),
              if (defaultTargetPlatform == TargetPlatform.android)
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
              ],

              const SizedBox(height: 8),
              const Divider(height: 1, thickness: 0.3),
              _buildSectionTitle(context, '关于与更多', Icons.info_outline),
              ListTile(
                leading: const Icon(Icons.history_outlined),
                title: const Text('更新日志'),
                subtitle: const Text('查看各个版本的更新记录'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => AutoRouter.of(context).push(ChangelogRoute()),
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('关于应用'),
                subtitle: const Text('关于 Breeze 的详细信息'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => AutoRouter.of(context).push(AboutRoute()),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
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
      value: state.syncSetting.autoSync,
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
          value: state.syncSetting.syncServiceType,
          icon: const Icon(Icons.expand_more),
          onChanged: (SyncServiceType? value) {
            if (value == null || value == state.syncSetting.syncServiceType) {
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
      value: state.syncSetting.syncNotify,
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
      value: state.syncSetting.syncSettings,
      onChanged: (bool value) {
        cubit.updateSyncSetting(
          (current) => current.copyWith(syncSettings: value),
        );
      },
    );
  }

  Widget _syncPlugins(GlobalSettingState state, GlobalSettingCubit cubit) {
    return SwitchListTile(
      secondary: const Icon(Icons.extension_outlined),
      title: const Text('同步插件'),
      subtitle: const Text('开启后同步插件配置与安装状态'),
      thumbIcon: kSettingSwitchThumbIcon,
      value: state.syncSetting.syncPlugins,
      onChanged: (bool value) {
        cubit.updateSyncSetting(
          (current) => current.copyWith(syncPlugins: value),
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
      value: state.readSetting.comicReadTopContainer,
      onChanged: (bool value) {
        cubit.updateReadSetting(
          (current) => current.copyWith(comicReadTopContainer: value),
        );
      },
    );
  }

  Widget _splashPage(GlobalSettingState state, GlobalSettingCubit cubit) {
    final selectedIndex = splashPageList.isEmpty
        ? 0
        : state.welcomePageNum.clamp(0, splashPageList.length - 1);

    return ListTile(
      leading: const Icon(Icons.rocket_launch_outlined),
      title: const Text('开屏页'),
      subtitle: const Text('选择启动页，打开应用直达目标'),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: splashPageList[selectedIndex],
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

  Widget _oldPageRollback(GlobalSettingState state, GlobalSettingCubit cubit) {
    return SwitchListTile(
      secondary: const Icon(Icons.restore_outlined),
      title: const Text('回退开关'),
      subtitle: const Text('开启后启用旧版页面入口'),
      thumbIcon: kSettingSwitchThumbIcon,
      value: state.oldPageRollbackEnabled,
      onChanged: (bool value) {
        cubit.updateState(
          (current) => current.copyWith(oldPageRollbackEnabled: value),
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

  Widget _logAddress(GlobalSettingState state, GlobalSettingCubit cubit) {
    final logAddress = state.logAddress.trim();
    return ListTile(
      leading: const Icon(Icons.link_outlined),
      title: const Text('调试日志地址'),
      subtitle: Text(
        logAddress.isEmpty ? '点击设置日志上传地址' : logAddress,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        var inputValue = logAddress;
        final result = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('设置日志地址'),
            content: TextFormField(
              initialValue: logAddress,
              autofocus: true,
              onChanged: (value) => inputValue = value.trim(),
              decoration: const InputDecoration(
                hintText: 'https://example.com/log',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                child: const Text('取消'),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text('确定'),
                onPressed: () => Navigator.pop(context, inputValue),
              ),
            ],
          ),
        );

        if (result != null && result != logAddress) {
          cubit.updateState((current) => current.copyWith(logAddress: result));
          showSuccessToast('设置成功');
        }
      },
    );
  }

  Widget _forceEnableImpeller(
    GlobalSettingState state,
    GlobalSettingCubit cubit,
  ) {
    return SwitchListTile(
      secondary: const Icon(Icons.auto_awesome_outlined),
      title: const Text('启用 Impeller'),
      subtitle: const Text('开启=启用，关闭=禁用；重启生效'),
      thumbIcon: kSettingSwitchThumbIcon,
      value: state.forceEnableImpeller,
      onChanged: (bool value) async {
        cubit.updateState(
          (current) => current.copyWith(forceEnableImpeller: value),
        );
        await ImpellerConfig.setForceEnableImpeller(value);
        showSuccessToast('设置成功，重启生效');
      },
    );
  }
}
