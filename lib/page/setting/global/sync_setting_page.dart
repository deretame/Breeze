import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/sync/sync_service.dart';
import 'package:zephyr/page/setting/common/setting_ui.dart';
import 'package:zephyr/page/setting/global/widgets.dart';
import 'package:zephyr/util/event/event.dart';
import 'package:zephyr/widgets/fluent_dropdown.dart';

@RoutePage()
class SyncSettingPage extends StatelessWidget {
  const SyncSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<GlobalSettingCubit>();
    final state = cubit.state;
    final configuredSync = isSyncServiceConfigured(state);

    return SettingPageShell(
      title: t.settings.sync,
      child: ListView(
        children: [
          settingSectionTitle(
            context,
            t.settings.sync,
            icon: Icons.sync_outlined,
          ),
          _syncServiceType(state, cubit),
          webdavSync(context, state.syncSetting.syncServiceType),
          if (configuredSync) _autoSync(state, cubit),
          if (configuredSync && state.syncSetting.autoSync)
            _syncNotify(state, cubit),
          if (configuredSync) _syncSettings(state, cubit),
          if (configuredSync) _syncPlugins(state, cubit),
          const SizedBox(height: 32),
        ],
      ),
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
}
