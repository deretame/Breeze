import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/config/router/router.gr.dart';
import 'package:zephyr/i18n/i18n_helper.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/page/setting/common/setting_ui.dart';
import 'package:zephyr/page/setting/real_sr/service/real_sr_super_resolution.dart';

@RoutePage()
class GlobalSettingPage extends StatefulWidget {
  const GlobalSettingPage({super.key});

  @override
  State<GlobalSettingPage> createState() => _GlobalSettingPageState();
}

class _GlobalSettingPageState extends State<GlobalSettingPage> {
  late final Future<bool> _realSrAvailable;

  @override
  void initState() {
    super.initState();
    _realSrAvailable = RealSrSuperResolution.isDeviceSupported;
  }

  Future<void> _openSubPage(PageRouteInfo route) async {
    await context.pushRoute(route);
    if (mounted) setState(() {});
  }

  String _themeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => t.common.followSystem,
      ThemeMode.light => t.common.lightMode,
      ThemeMode.dark => t.common.darkMode,
    };
  }

  String _languageLabel(GlobalSettingState state) {
    if (state.localeFollowsSystem) return t.settings.followSystemLanguage;
    for (final appLocale in AppLocale.values) {
      if (I18nHelper.toFlutterLocale(appLocale) == state.locale) {
        return I18nHelper.displayName(appLocale);
      }
    }
    return state.locale.toLanguageTag();
  }

  String _syncServiceLabel(SyncServiceType type) {
    return switch (type) {
      SyncServiceType.none => t.settings.syncServiceNone,
      SyncServiceType.webdav => t.settings.syncServiceWebdav,
      SyncServiceType.s3 => t.settings.syncServiceS3,
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GlobalSettingCubit>().state;

    return SettingPageShell(
      title: t.settings.globalTitle,
      child: ListView(
        children: [
          settingCategoryTile(
            icon: Icons.palette_outlined,
            title: t.settings.appearance,
            subtitle:
                '${_languageLabel(state)} · ${_themeLabel(state.themeMode)}',
            onTap: () => _openSubPage(const AppearanceSettingRoute()),
          ),
          const Divider(height: 1, thickness: 0.3),
          settingCategoryTile(
            icon: Icons.tune_outlined,
            title: t.settings.contentAndNetwork,
            subtitle: '${t.settings.maskedKeywords} · ${t.settings.proxy}',
            onTap: () => _openSubPage(const ContentNetworkSettingRoute()),
          ),
          const Divider(height: 1, thickness: 0.3),
          settingCategoryTile(
            icon: Icons.sync_outlined,
            title: t.settings.sync,
            subtitle: _syncServiceLabel(state.syncSetting.syncServiceType),
            onTap: () => _openSubPage(const SyncSettingRoute()),
          ),
          const Divider(height: 1, thickness: 0.3),
          settingCategoryTile(
            icon: Icons.settings_outlined,
            title: t.settings.appBehavior,
            subtitle: state.appLockSetting.enabled
                ? t.settings.appLock
                : t.settings.splashPage,
            onTap: () => _openSubPage(const AppBehaviorSettingRoute()),
          ),
          const Divider(height: 1, thickness: 0.3),
          settingCategoryTile(
            icon: Icons.storage_outlined,
            title: t.settings.storage,
            subtitle: '${t.settings.cache} · ${t.settings.dataBackup}',
            onTap: () => _openSubPage(const StorageSettingRoute()),
          ),
          FutureBuilder<bool>(
            future: _realSrAvailable,
            builder: (context, snapshot) {
              if (snapshot.data != true) {
                return const SizedBox.shrink();
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(height: 1, thickness: 0.3),
                  settingCategoryTile(
                    icon: Icons.auto_fix_high_outlined,
                    title: t.settings.realSr,
                    subtitle: t.settings.realSrSubtitle,
                    onTap: () => _openSubPage(const RealSrSettingRoute()),
                  ),
                ],
              );
            },
          ),
          const Divider(height: 1, thickness: 0.3),
          settingCategoryTile(
            icon: Icons.bug_report_outlined,
            title: t.settings.debug,
            subtitle: t.settings.logAddress,
            onTap: () => _openSubPage(const DebugSettingRoute()),
          ),
          const Divider(height: 1, thickness: 0.3),
          settingSectionTitle(
            context,
            t.settings.aboutAndMore,
            icon: Icons.info_outline,
          ),
          ListTile(
            leading: const Icon(Icons.history_outlined),
            title: Text(t.settings.changelog),
            subtitle: Text(t.settings.changelogSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushRoute(ChangelogRoute()),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text(t.settings.aboutApp),
            subtitle: Text(t.settings.aboutAppSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushRoute(AboutRoute()),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
