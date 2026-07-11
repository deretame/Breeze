import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/config/router/router.gr.dart';
import 'package:zephyr/i18n/i18n_helper.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/i18n/system_locale_service.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/sync/sync_service.dart';
import 'package:zephyr/page/font_setting/view/font_setting_page.dart';
import 'package:zephyr/page/setting/real_sr/service/real_sr_super_resolution.dart';
import 'package:zephyr/platform/desktop/window_logic.dart';
import 'package:zephyr/util/get_path.dart';
import 'package:zephyr/util/impeller_config.dart';
import 'package:zephyr/widgets/fluent_dropdown.dart';
import 'package:zephyr/widgets/gesture_lock.dart';
import 'package:zephyr/widgets/toast.dart';

import '../../../util/event/event.dart';
import '../common/setting_ui.dart';
import 'widgets.dart';

@RoutePage()
class GlobalSettingPage extends StatefulWidget {
  const GlobalSettingPage({super.key});

  @override
  State<GlobalSettingPage> createState() => _GlobalSettingPageState();
}

class _GlobalSettingPageState extends State<GlobalSettingPage> {
  List<String> _splashPageList(bool oldPageRollbackEnabled) {
    if (oldPageRollbackEnabled) {
      return [
        t.navigation.home,
        t.navigation.rank,
        t.navigation.bookshelf,
        t.navigation.discover,
        t.navigation.more,
      ];
    }
    return [t.navigation.bookshelf, t.navigation.discover, t.navigation.more];
  }

  Map<String, int> _splashPageMap(bool oldPageRollbackEnabled) {
    if (oldPageRollbackEnabled) {
      return {
        t.navigation.home: 0,
        t.navigation.rank: 1,
        t.navigation.bookshelf: 2,
        t.navigation.discover: 3,
        t.navigation.more: 4,
      };
    }
    return {
      t.navigation.bookshelf: 0,
      t.navigation.discover: 1,
      t.navigation.more: 2,
    };
  }

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
        title: Text(
          t.settings.globalTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
              _buildSectionTitle(
                context,
                t.settings.appearance,
                Icons.palette_outlined,
              ),
              _languageTile(state, globalSettingCubit),
              _systemTheme(state, globalSettingCubit),
              _dynamicColor(state, globalSettingCubit),
              if (!state.dynamicColor) changeThemeColor(context),
              _comicReadTopContainer(state, globalSettingCubit),
              _isAMOLED(state, globalSettingCubit),
              _fontSettings(context),

              const SizedBox(height: 8),
              const Divider(height: 1, thickness: 0.3),
              _buildSectionTitle(
                context,
                t.settings.contentAndNetwork,
                Icons.tune_outlined,
              ),
              editMaskedKeywords(context),
              _chineseConvertMode(state, globalSettingCubit),
              socks5ProxyEdit(context, state.socks5Proxy),
              if (!Platform.isIOS) _customExportPath(state, globalSettingCubit),
              _updateAccelerate(state, globalSettingCubit),

              const SizedBox(height: 8),
              const Divider(height: 1, thickness: 0.3),
              _buildSectionTitle(context, t.settings.sync, Icons.sync_outlined),
              _syncServiceType(state, globalSettingCubit),
              webdavSync(context, state.syncSetting.syncServiceType),
              if (configuredSync) _autoSync(state, globalSettingCubit),
              if (configuredSync && state.syncSetting.autoSync)
                _syncNotify(state, globalSettingCubit),
              if (configuredSync) _syncSettings(state, globalSettingCubit),
              if (configuredSync) _syncPlugins(state, globalSettingCubit),

              const SizedBox(height: 8),
              const Divider(height: 1, thickness: 0.3),
              _buildSectionTitle(
                context,
                t.settings.appBehavior,
                Icons.settings_outlined,
              ),
              _splashPage(state, globalSettingCubit),
              if (isDesktop) _desktopCloseBehaviorTile(),
              _appLockSetting(state, globalSettingCubit),
              _oldPageRollback(state, globalSettingCubit),

              const SizedBox(height: 8),
              const Divider(height: 1, thickness: 0.3),
              _buildSectionTitle(
                context,
                t.settings.storage,
                Icons.storage_outlined,
              ),
              _cacheSettings(context),
              _dataBackupSettings(context),

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
                      _buildSectionTitle(
                        context,
                        t.settings.imageProcessing,
                        Icons.image_outlined,
                      ),
                      _realSrSettings(context),
                    ],
                  );
                },
              ),

              const SizedBox(height: 8),
              const Divider(height: 1, thickness: 0.3),
              _buildSectionTitle(
                context,
                t.settings.debug,
                Icons.bug_report_outlined,
              ),
              _logAddress(state, globalSettingCubit),
              _enableMemoryDebug(state, globalSettingCubit),
              if (defaultTargetPlatform == TargetPlatform.android)
                _forceEnableImpeller(state, globalSettingCubit),
              if (kDebugMode) ...[
                ListTile(
                  leading: const Icon(Icons.colorize_outlined),
                  title: Text(t.settings.colorPreview),
                  subtitle: Text(t.settings.colorPreviewSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    AutoRouter.of(context).push(const ShowColorRoute());
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.developer_mode_outlined),
                  title: Text(t.settings.qjsRuntimeDebug),
                  subtitle: Text(t.settings.qjsRuntimeDebugSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    context.pushRoute(const QjsRuntimeDebugRoute());
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.memory_outlined),
                  title: Text(t.settings.coremlDebug),
                  subtitle: Text(t.settings.coremlDebugSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    context.pushRoute(const CoreMLUpscaleDebugRoute());
                  },
                ),
              ],

              const SizedBox(height: 8),
              const Divider(height: 1, thickness: 0.3),
              _buildSectionTitle(
                context,
                t.settings.aboutAndMore,
                Icons.info_outline,
              ),
              ListTile(
                leading: const Icon(Icons.history_outlined),
                title: Text(t.settings.changelog),
                subtitle: Text(t.settings.changelogSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => AutoRouter.of(context).push(ChangelogRoute()),
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: Text(t.settings.aboutApp),
                subtitle: Text(t.settings.aboutAppSubtitle),
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

  Widget _languageTile(GlobalSettingState state, GlobalSettingCubit cubit) {
    final labels = {
      null: t.settings.followSystemLanguage,
      for (final appLocale in AppLocale.values)
        I18nHelper.toFlutterLocale(appLocale): I18nHelper.displayName(
          appLocale,
        ),
    };

    final currentValue = state.localeFollowsSystem ? null : state.locale;
    final currentLabel = labels[currentValue]!;

    return ListTile(
      leading: const Icon(Icons.language_outlined),
      title: Text(t.settings.language),
      subtitle: Text(t.settings.languageSubtitle),
      trailing: FluentDropdown<Locale?>(
        value: currentValue,
        displayValue: currentLabel,
        items: labels,
        onChanged: (value) async {
          if (value == currentValue) return;
          if (value == null) {
            final systemInfo = await SystemLocaleService.getInfo();
            await cubit.setSystemLocale(systemInfo.locale);
          } else {
            await cubit.setLocale(value, followsSystem: false);
          }
          if (mounted) {
            showInfoToast(t.settings.languageChangedRestartHint);
          }
        },
      ),
    );
  }

  Widget _systemTheme(GlobalSettingState state, GlobalSettingCubit cubit) {
    final themeItems = <ThemeMode, String>{
      ThemeMode.system: t.common.followSystem,
      ThemeMode.light: t.common.lightMode,
      ThemeMode.dark: t.common.darkMode,
    };

    return ListTile(
      leading: const Icon(Icons.dark_mode_outlined),
      title: Text(t.settings.theme),
      subtitle: Text(t.settings.themeSubtitle),
      trailing: FluentDropdown<ThemeMode>(
        value: state.themeMode,
        displayValue: themeItems[state.themeMode]!,
        items: themeItems,
        onChanged: (ThemeMode value) {
          cubit.updateState((current) => current.copyWith(themeMode: value));
        },
      ),
    );
  }

  Widget _dynamicColor(GlobalSettingState state, GlobalSettingCubit cubit) {
    return SwitchListTile(
      secondary: const Icon(Icons.color_lens_outlined),
      title: Text(t.settings.dynamicColor),
      subtitle: Text(t.settings.dynamicColorSubtitle),
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
      title: Text(t.settings.fontSettings),
      subtitle: Text(t.settings.fontSettingsSubtitle),
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
      title: Text(t.settings.amoled),
      subtitle: Text(t.settings.amoledSubtitle),
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
      title: Text(t.settings.autoSync),
      subtitle: Text(t.settings.autoSyncSubtitle),
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
      title: Text(t.settings.updateAccelerate),
      subtitle: Text(t.settings.updateAccelerateSubtitle),
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
    final syncServiceItems = <SyncServiceType, String>{
      SyncServiceType.none: t.settings.syncServiceNone,
      SyncServiceType.webdav: t.settings.syncServiceWebdav,
      SyncServiceType.s3: t.settings.syncServiceS3,
    };

    return ListTile(
      leading: const Icon(Icons.storage_outlined),
      title: Text(t.settings.syncService),
      subtitle: Text(t.settings.syncServiceSubtitle),
      trailing: FluentDropdown<SyncServiceType>(
        value: state.syncSetting.syncServiceType,
        displayValue: syncServiceItems[state.syncSetting.syncServiceType]!,
        items: syncServiceItems,
        onChanged: (SyncServiceType value) {
          if (value == state.syncSetting.syncServiceType) return;
          cubit.updateSyncSetting(
            (current) => current.copyWith(
              syncServiceType: value,
              syncSettings: value == SyncServiceType.none
                  ? false
                  : current.syncSettings,
            ),
          );
        },
      ),
    );
  }

  Widget _chineseConvertMode(
    GlobalSettingState state,
    GlobalSettingCubit cubit,
  ) {
    final chineseConvertItems = <ChineseConvertMode, String>{
      ChineseConvertMode.off: t.settings.chineseConvertOff,
      ChineseConvertMode.simplified: t.settings.chineseConvertSimplified,
      ChineseConvertMode.traditional: t.settings.chineseConvertTraditional,
    };

    return ListTile(
      leading: const Icon(Icons.translate_outlined),
      title: Text(t.settings.chineseConvert),
      subtitle: Text(t.settings.chineseConvertSubtitle),
      trailing: FluentDropdown<ChineseConvertMode>(
        value: state.chineseConvertMode,
        displayValue: chineseConvertItems[state.chineseConvertMode]!,
        items: chineseConvertItems,
        onChanged: (ChineseConvertMode value) {
          if (value == state.chineseConvertMode) return;
          cubit.updateState(
            (current) => current.copyWith(chineseConvertMode: value),
          );
        },
      ),
    );
  }

  Widget _syncNotify(GlobalSettingState state, GlobalSettingCubit cubit) {
    return SwitchListTile(
      secondary: const Icon(Icons.notifications_active_outlined),
      title: Text(t.settings.syncNotify),
      subtitle: Text(t.settings.syncNotifySubtitle),
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
      title: Text(t.settings.syncSettings),
      subtitle: Text(t.settings.syncSettingsSubtitle),
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
      title: Text(t.settings.syncPlugins),
      subtitle: Text(t.settings.syncPluginsSubtitle),
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
      title: Text(t.settings.notchAdaptation),
      subtitle: Text(t.settings.notchAdaptationSubtitle),
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
    final splashPageList = _splashPageList(state.oldPageRollbackEnabled);
    final splashPage = _splashPageMap(state.oldPageRollbackEnabled);
    final selectedIndex = splashPageList.isEmpty
        ? 0
        : state.welcomePageNum.clamp(0, splashPageList.length - 1);

    final splashPageItems = {for (final page in splashPageList) page: page};

    return ListTile(
      leading: const Icon(Icons.rocket_launch_outlined),
      title: Text(t.settings.splashPage),
      subtitle: Text(t.settings.splashPageSubtitle),
      trailing: FluentDropdown<String>(
        value: splashPageList[selectedIndex],
        displayValue: splashPageList[selectedIndex],
        items: splashPageItems,
        onChanged: (String value) {
          if (value == splashPageList[selectedIndex]) return;
          showSuccessToast(t.common.restartToTakeEffect);
          cubit.updateState(
            (current) => current.copyWith(welcomePageNum: splashPage[value]!),
          );
        },
      ),
    );
  }

  Widget _oldPageRollback(GlobalSettingState state, GlobalSettingCubit cubit) {
    return SwitchListTile(
      secondary: const Icon(Icons.restore_outlined),
      title: Text(t.settings.oldPageRollback),
      subtitle: Text(t.settings.oldPageRollbackSubtitle),
      thumbIcon: kSettingSwitchThumbIcon,
      value: state.oldPageRollbackEnabled,
      onChanged: (bool value) {
        cubit.updateState(
          (current) => current.copyWith(oldPageRollbackEnabled: value),
        );
        showSuccessToast(t.common.restartToTakeEffect);
      },
    );
  }

  Widget _desktopCloseBehaviorTile() {
    final closeBehaviorItems = <DesktopCloseBehavior, String>{
      DesktopCloseBehavior.ask: t.settings.desktopCloseAsk,
      DesktopCloseBehavior.hide: t.settings.desktopCloseHide,
      DesktopCloseBehavior.close: t.settings.desktopCloseClose,
    };

    return ListTile(
      leading: const Icon(Icons.close_fullscreen_outlined),
      title: Text(t.settings.desktopCloseBehavior),
      subtitle: Text(t.settings.desktopCloseBehaviorSubtitle),
      trailing: FluentDropdown<DesktopCloseBehavior>(
        value: _desktopCloseBehavior,
        displayValue: closeBehaviorItems[_desktopCloseBehavior]!,
        items: closeBehaviorItems,
        onChanged: (DesktopCloseBehavior value) async {
          if (value == _desktopCloseBehavior) return;
          await WindowLogic.saveCloseBehavior(value);
          if (!mounted) return;
          setState(() => _desktopCloseBehavior = value);
          showSuccessToast(t.common.settingSaved);
        },
      ),
    );
  }

  Widget _enableMemoryDebug(
    GlobalSettingState state,
    GlobalSettingCubit cubit,
  ) {
    return SwitchListTile(
      secondary: const Icon(Icons.memory_outlined),
      title: Text(t.settings.memoryDebug),
      subtitle: Text(t.settings.memoryDebugSubtitle),
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
      title: Text(t.settings.logAddress),
      subtitle: Text(
        logAddress.isEmpty ? t.settings.logAddressSubtitle : logAddress,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        var inputValue = logAddress;
        final result = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(t.settings.logAddress),
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
                child: Text(t.common.cancel),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: Text(t.common.ok),
                onPressed: () => Navigator.pop(context, inputValue),
              ),
            ],
          ),
        );

        if (result != null && result != logAddress) {
          cubit.updateState((current) => current.copyWith(logAddress: result));
          showSuccessToast(t.common.settingSaved);
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
      title: Text(t.settings.forceEnableImpeller),
      subtitle: Text(t.settings.forceEnableImpellerSubtitle),
      thumbIcon: kSettingSwitchThumbIcon,
      value: state.forceEnableImpeller,
      onChanged: (bool value) async {
        cubit.updateState(
          (current) => current.copyWith(forceEnableImpeller: value),
        );
        await ImpellerConfig.setForceEnableImpeller(value);
        showSuccessToast(t.common.restartToTakeEffect);
      },
    );
  }

  Widget _customExportPath(GlobalSettingState state, GlobalSettingCubit cubit) {
    final exportPath = state.customExportPath.trim();
    return ListTile(
      leading: const Icon(Icons.folder_outlined),
      title: Text(t.settings.customExportPath),
      subtitle: Text(
        exportPath.isEmpty ? t.settings.notSet : exportPath,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (exportPath.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 20),
              tooltip: t.common.clear,
              onPressed: () {
                cubit.updateState(
                  (current) => current.copyWith(customExportPath: ''),
                );
                showSuccessToast(t.common.settingSaved);
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
          showSuccessToast(t.common.settingSaved);
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
          title: Text(t.settings.appLock),
          subtitle: Text(t.settings.appLockSubtitle),
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
              showSuccessToast(t.common.settingSaved);
              return;
            }

            cubit.updateState(
              (current) => current.copyWith(
                appLockSetting: current.appLockSetting.copyWith(enabled: value),
              ),
            );
            showSuccessToast(t.common.settingSaved);
          },
        ),
        ListTile(
          leading: const Icon(Icons.gesture_outlined),
          title: Text(t.settings.appLock),
          subtitle: Text(t.settings.appLockSubtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final nextSetting = await _configureAppLock();
            if (nextSetting == null) {
              return;
            }
            cubit.updateState(
              (current) => current.copyWith(appLockSetting: nextSetting),
            );
            showSuccessToast(t.common.settingSaved);
          },
        ),
        if (isReady)
          ListTile(
            leading: const Icon(Icons.pin_outlined),
            title: Text(t.gestureLock.pinTitle),
            subtitle: Text(t.gestureLock.pinHint),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final pin = await showPinCodeSetupDialog(
                context,
                title: t.gestureLock.pinTitle,
                confirmTitle: t.gestureLock.pinHint,
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
              showSuccessToast(t.common.settingSaved);
            },
          ),
        if (isReady)
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: Text(t.common.delete),
            subtitle: Text(t.settings.appLock),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final shouldDelete = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(t.common.delete),
                  content: Text(t.settings.appLockSubtitle),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(t.common.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(t.common.delete),
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
              showSuccessToast(t.common.settingSaved);
            },
          ),
      ],
    );
  }

  Widget _realSrSettings(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.auto_fix_high_outlined),
      title: Text(t.settings.realSr),
      subtitle: Text(t.settings.realSrSubtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => AutoRouter.of(context).push(const RealSrSettingRoute()),
    );
  }

  Widget _cacheSettings(BuildContext context) {
    final sizeText = _cacheCalculating
        ? t.settings.calculatingCache
        : _formatCacheSize(_cacheSizeBytes);

    return ListTile(
      leading: const Icon(Icons.cleaning_services_outlined),
      title: Text(t.settings.cache),
      subtitle: Text(sizeText.isEmpty ? t.settings.cache : sizeText),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => AutoRouter.of(context).push(const CacheSettingRoute()),
    );
  }

  Widget _dataBackupSettings(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.import_export_outlined),
      title: Text(t.settings.dataBackup),
      subtitle: Text(t.settings.dataBackupSubtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => AutoRouter.of(context).push(const DataBackupRoute()),
    );
  }

  Future<AppLockSettingState?> _configureAppLock() async {
    final pattern = await showGesturePasswordSetupDialog(
      context,
      title: t.gestureLock.gestureTitle,
      confirmTitle: t.gestureLock.confirmGesture,
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
