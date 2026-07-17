import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/page/setting/common/setting_ui.dart';
import 'package:zephyr/platform/desktop/window_logic.dart';
import 'package:zephyr/service/lifecycle/foreground_task/foreground_task_service.dart';
import 'package:zephyr/widgets/fluent_dropdown.dart';
import 'package:zephyr/widgets/gesture_lock.dart';
import 'package:zephyr/widgets/toast.dart';

@RoutePage()
class AppBehaviorSettingPage extends StatefulWidget {
  const AppBehaviorSettingPage({super.key});

  @override
  State<AppBehaviorSettingPage> createState() => _AppBehaviorSettingPageState();
}

class _AppBehaviorSettingPageState extends State<AppBehaviorSettingPage> {
  DesktopCloseBehavior _desktopCloseBehavior = DesktopCloseBehavior.ask;

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

  @override
  void initState() {
    super.initState();
    _loadDesktopCloseBehavior();
  }

  Future<void> _loadDesktopCloseBehavior() async {
    if (!isDesktop) return;
    final value = await WindowLogic.loadCloseBehavior();
    if (!mounted) return;
    setState(() => _desktopCloseBehavior = value);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<GlobalSettingCubit>();
    final state = cubit.state;

    return SettingPageShell(
      title: t.settings.appBehavior,
      child: ListView(
        children: [
          settingSectionTitle(
            context,
            t.settings.appBehavior,
            icon: Icons.settings_outlined,
          ),
          _splashPage(state, cubit),
          if (isDesktop) _desktopCloseBehaviorTile(),
          if (Platform.isAndroid) _androidKeepAlive(state, cubit),
          _appLockSetting(state, cubit),
          _oldPageRollback(state, cubit),
          const SizedBox(height: 32),
        ],
      ),
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

  Widget _androidKeepAlive(GlobalSettingState state, GlobalSettingCubit cubit) {
    return SwitchListTile(
      secondary: const Icon(Icons.battery_charging_full_outlined),
      title: Text(t.settings.androidKeepAlive),
      subtitle: Text(t.settings.androidKeepAliveSubtitle),
      thumbIcon: kSettingSwitchThumbIcon,
      value: state.androidKeepAliveEnabled,
      onChanged: (bool value) async {
        cubit.updateState(
          (current) => current.copyWith(androidKeepAliveEnabled: value),
        );
        try {
          if (value) {
            await ForegroundTaskService.instance.enableKeepAlive();
          } else {
            await ForegroundTaskService.instance.disableKeepAlive();
          }
          showSuccessToast(t.common.settingSaved);
        } catch (e) {
          cubit.updateState(
            (current) => current.copyWith(androidKeepAliveEnabled: !value),
          );
          showErrorToast(e.toString());
        }
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
