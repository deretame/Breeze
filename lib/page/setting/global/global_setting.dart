import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/sync/sync_service.dart';
import 'package:zephyr/page/font_setting/view/font_setting_page.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/desktop/window_logic.dart';
import 'package:zephyr/util/get_path.dart';
import 'package:zephyr/util/impeller_config.dart';
import 'package:zephyr/util/real_sr/real_sr_super_resolution.dart';
import 'package:zephyr/widgets/gesture_lock.dart';
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

  int? _cacheSizeBytes;
  bool _cacheCalculating = false;
  DesktopCloseBehavior _desktopCloseBehavior = DesktopCloseBehavior.ask;
  late final Future<bool> _realSrAvailable;

  @override
  void initState() {
    super.initState();
    _loadImpellerConfig();
    _loadCacheSize();
    _loadDesktopCloseBehavior();
    // iOS / macOS / Windows / Linux 支持下载模型，所以始终显示入口；
    // Android 只在设备支持（arm64-v8a）时显示，不依赖模型是否已下载。
    _realSrAvailable = RealSrSuperResolution.isDeviceSupported;
  }

  Future<void> _loadDesktopCloseBehavior() async {
    if (!isDesktop) return;
    final value = await WindowLogic.loadCloseBehavior();
    if (!mounted) return;
    setState(() => _desktopCloseBehavior = value);
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

  Future<void> _loadCacheSize() async {
    if (_cacheCalculating) return;
    setState(() => _cacheCalculating = true);

    try {
      final cachePath = await getCachePath();
      final directory = Directory(cachePath);
      if (!await directory.exists()) {
        if (!mounted) return;
        setState(() {
          _cacheSizeBytes = 0;
          _cacheCalculating = false;
        });
        return;
      }

      int totalSize = 0;
      final entities = directory.listSync(recursive: true);
      for (final entity in entities) {
        final isSentry = entity.path
            .split(Platform.pathSeparator)
            .contains('sentry');
        if (entity is File && !isSentry) {
          try {
            totalSize += await entity.length();
          } on FileSystemException {
            continue;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _cacheSizeBytes = totalSize;
        _cacheCalculating = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cacheSizeBytes = null;
        _cacheCalculating = false;
      });
    }
  }

  String _formatCacheSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes == 0) return '0 B';

    const gb = 1 << 30;
    const mb = 1 << 20;
    const kb = 1 << 10;

    if (bytes >= gb) {
      return '${(bytes / gb).toStringAsFixed(2)} GB';
    } else if (bytes >= mb) {
      return '${(bytes / mb).toStringAsFixed(1)} MB';
    } else if (bytes >= kb) {
      return '${(bytes / kb).toStringAsFixed(1)} KB';
    } else {
      return '$bytes B';
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
              _fontSettings(context),

              const SizedBox(height: 8),
              const Divider(height: 1, thickness: 0.3),
              _buildSectionTitle(context, '内容与网络', Icons.tune_outlined),
              editMaskedKeywords(context),
              socks5ProxyEdit(context, state.socks5Proxy),
              if (!Platform.isIOS) _customExportPath(state, globalSettingCubit),
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
              if (isDesktop) _desktopCloseBehaviorTile(),
              _appLockSetting(state, globalSettingCubit),
              _oldPageRollback(state, globalSettingCubit),

              const SizedBox(height: 8),
              const Divider(height: 1, thickness: 0.3),
              _buildSectionTitle(context, '存储', Icons.storage_outlined),
              _cacheSettings(context),

              FutureBuilder<bool>(
                future: _realSrAvailable,
                builder: (context, snapshot) {
                  // 当前平台不支持超分时，隐藏“图片处理”区块
                  if (snapshot.data != true) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      const Divider(height: 1, thickness: 0.3),
                      _buildSectionTitle(context, '图片处理', Icons.image_outlined),
                      _realSrSettings(context),
                    ],
                  );
                },
              ),

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
                  onTap: () async {
                    AutoRouter.of(context).push(const ShowColorRoute());
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.developer_mode_outlined),
                  title: const Text('QJS 运行时调试'),
                  subtitle: const Text('手动输入运行时 ID，抓取调试快照'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    context.pushRoute(const QjsRuntimeDebugRoute());
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.memory_outlined),
                  title: const Text('CoreML 超分调试'),
                  subtitle: const Text('使用绝对路径模型测试 CoreML 超分'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    context.pushRoute(const CoreMLUpscaleDebugRoute());
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

  Widget _fontSettings(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.font_download_outlined),
      title: const Text('字体设置'),
      subtitle: const Text('自定义显示字体'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const FontSettingPage()));
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

  Widget _desktopCloseBehaviorTile() {
    return ListTile(
      leading: const Icon(Icons.close_fullscreen_outlined),
      title: const Text('关闭按钮行为'),
      subtitle: const Text('设置点击窗口关闭按钮时的默认动作'),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<DesktopCloseBehavior>(
          value: _desktopCloseBehavior,
          icon: const Icon(Icons.expand_more),
          onChanged: (DesktopCloseBehavior? value) async {
            if (value == null || value == _desktopCloseBehavior) {
              return;
            }
            await WindowLogic.saveCloseBehavior(value);
            if (!mounted) return;
            setState(() => _desktopCloseBehavior = value);
            showSuccessToast('设置成功');
          },
          items: DesktopCloseBehavior.values
              .map(
                (value) => DropdownMenuItem<DesktopCloseBehavior>(
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

  Widget _customExportPath(GlobalSettingState state, GlobalSettingCubit cubit) {
    final exportPath = state.customExportPath.trim();
    return ListTile(
      leading: const Icon(Icons.folder_outlined),
      title: const Text('自定义导出路径'),
      subtitle: Text(
        exportPath.isEmpty ? '未设置，默认导出到下载目录' : exportPath,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (exportPath.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 20),
              tooltip: '清除',
              onPressed: () {
                cubit.updateState(
                  (current) => current.copyWith(customExportPath: ''),
                );
                showSuccessToast('已清除自定义导出路径');
              },
            ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () async {
        final selected = await getDirectoryPath();
        if (selected != null && selected.trim().isNotEmpty) {
          cubit.updateState(
            (current) => current.copyWith(customExportPath: selected),
          );
          showSuccessToast('自定义导出路径已设置');
        }
      },
    );
  }

  Widget _appLockSetting(GlobalSettingState state, GlobalSettingCubit cubit) {
    final lockSetting = state.appLockSetting;
    final isReady = lockSetting.isReady;

    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.lock_outline),
          title: const Text('启动手势解锁'),
          subtitle: Text('进入应用后先验证手势密码'),
          thumbIcon: kSettingSwitchThumbIcon,
          value: lockSetting.enabled,
          onChanged: (bool value) async {
            if (value && !isReady) {
              final nextSetting = await _configureAppLock();
              if (nextSetting == null) {
                return;
              }
              cubit.updateState(
                (current) => current.copyWith(appLockSetting: nextSetting),
              );
              showSuccessToast('手势解锁已开启');
              return;
            }

            cubit.updateState(
              (current) => current.copyWith(
                appLockSetting: current.appLockSetting.copyWith(enabled: value),
              ),
            );
            showSuccessToast(value ? '手势解锁已开启' : '手势解锁已关闭');
          },
        ),
        ListTile(
          leading: const Icon(Icons.gesture_outlined),
          title: const Text('设置手势密码与重置 PIN'),
          subtitle: Text('重新设置手势密码和重置 PIN'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final nextSetting = await _configureAppLock();
            if (nextSetting == null) {
              return;
            }
            cubit.updateState(
              (current) => current.copyWith(appLockSetting: nextSetting),
            );
            showSuccessToast('手势密码与重置 PIN 已更新');
          },
        ),
        if (isReady)
          ListTile(
            leading: const Icon(Icons.pin_outlined),
            title: const Text('修改重置 PIN'),
            subtitle: const Text('修改重置 PIN'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final pin = await showPinCodeSetupDialog(
                context,
                title: '设置重置 PIN',
                confirmTitle: '确认重置 PIN',
              );
              if (pin == null) {
                return;
              }
              cubit.updateState(
                (current) => current.copyWith(
                  appLockSetting: current.appLockSetting.copyWith(
                    resetPinHash: hashPinCode(pin),
                  ),
                ),
              );
              showSuccessToast('重置 PIN 已更新');
            },
          ),
        if (isReady)
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('清除手势密码与 PIN'),
            subtitle: const Text('清除手势密码与 PIN'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final shouldDelete = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('清除手势密码与 PIN'),
                  content: const Text('清除后，进入应用时将不再验证手势密码。'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('清除'),
                    ),
                  ],
                ),
              );
              if (shouldDelete != true) {
                return;
              }
              cubit.updateState(
                (current) => current.copyWith(
                  appLockSetting: const AppLockSettingState(),
                ),
              );
              showSuccessToast('手势密码与 PIN 已清除');
            },
          ),
      ],
    );
  }

  Widget _realSrSettings(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.auto_fix_high_outlined),
      title: const Text('图片超分（实验性）'),
      subtitle: const Text('试验性功能,可能不稳定'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => AutoRouter.of(context).push(const RealSrSettingRoute()),
    );
  }

  Widget _cacheSettings(BuildContext context) {
    final sizeText = _cacheCalculating
        ? '计算中…'
        : _formatCacheSize(_cacheSizeBytes);

    return ListTile(
      leading: const Icon(Icons.cleaning_services_outlined),
      title: const Text('缓存管理'),
      subtitle: Text(sizeText.isEmpty ? '查看缓存大小，设置缓存上限与自动清理' : sizeText),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => AutoRouter.of(context).push(const CacheSettingRoute()),
    );
  }

  Future<AppLockSettingState?> _configureAppLock() async {
    final pattern = await showGesturePasswordSetupDialog(
      context,
      title: '设置手势密码',
      confirmTitle: '确认手势密码',
    );
    if (pattern == null) {
      return null;
    }

    if (!mounted) {
      return null;
    }

    final pin = await showPinCodeSetupDialog(
      context,
      title: '设置重置 PIN',
      confirmTitle: '确认重置 PIN',
    );
    if (pin == null) {
      return null;
    }

    return AppLockSettingState(
      enabled: true,
      gesturePasswordHash: hashGesturePattern(pattern),
      resetPinHash: hashPinCode(pin),
    );
  }
}
