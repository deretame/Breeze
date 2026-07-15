import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/config/router/router.gr.dart' as app_router;
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/migration/compatible.dart';
import 'package:zephyr/plugin/bridge/dart_tools_bridge.dart';
import 'package:zephyr/plugin/bridge/plugin_config_bridge.dart';
import 'package:zephyr/plugin/plugin_cloud_update_service.dart';
import 'package:zephyr/plugin/plugin_registry_service.dart';
import 'package:zephyr/service/lifecycle/foreground_task/foreground_task_service.dart';
import 'package:zephyr/src/rust/api/qjs.dart';
import 'package:zephyr/widgets/gesture_lock.dart';
import 'package:zephyr/widgets/toast.dart';

@RoutePage()
class AppBootstrapPage extends StatelessWidget {
  const AppBootstrapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StringSelectCubit()..setDate(t.appBootstrap.initializing),
      child: const AppBootstrapView(),
    );
  }
}

class AppBootstrapView extends StatefulWidget {
  const AppBootstrapView({super.key});

  @override
  State<AppBootstrapView> createState() => _AppBootstrapViewState();
}

class _AppBootstrapViewState extends State<AppBootstrapView> {
  @override
  void initState() {
    super.initState();
    _goNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 14),
            BlocBuilder<StringSelectCubit, String>(
              builder: (context, state) {
                return Text(state, style: const TextStyle(fontSize: 24));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _goNext() async {
    void updateStatus(String msg) {
      if (mounted) context.read<StringSelectCubit>().setDate(msg);
    }

    final stopwatch = Stopwatch()..start();

    registerPersistentCallbacks();

    registerDartTools();

    initRustFunctions();

    ForegroundTaskService.instance.listenEvents();

    if (mounted) await ensureCompatibleMigration(context);

    updateStatus(t.appBootstrap.initializing);
    await PluginRegistryService.I.init();
    await PluginRegistryService.I.warmupPluginInfos();
    PluginCloudUpdateService.I.scheduleSilentCloudUpdate(
      delay: const Duration(minutes: 1),
    );
    unawaited(() async {
      try {
        await PluginRegistryService.I.initializeActivePluginRuntimes();
      } catch (e, st) {
        logger.w(
          'Background plugin runtime init failed',
          error: e,
          stackTrace: st,
        );
      }
    }());

    stopwatch.stop();
    final int delayTime = (200 - stopwatch.elapsedMilliseconds).clamp(0, 200);

    if (delayTime > 0) {
      await Future.delayed(Duration(milliseconds: delayTime));
    }

    if (!mounted) return;

    final globalSettingCubit = context.read<GlobalSettingCubit>();
    final globalSetting = globalSettingCubit.state;
    final appLockSetting = globalSetting.appLockSetting;
    if (appLockSetting.enabled && appLockSetting.isReady) {
      updateStatus(t.appBootstrap.verifyGesture);
      final unlockResult = await showGestureUnlockDialog(
        context,
        expectedHash: appLockSetting.gesturePasswordHash,
        title: t.gestureLock.appLocked,
        hint: t.gestureLock.verifyToUnlock,
        showForgotPassword: true,
      );
      if (!mounted) {
        return;
      }
      if (unlockResult == GestureUnlockResult.forgotPassword) {
        final verified = await showPinVerifyDialog(
          context,
          expectedHash: appLockSetting.resetPinHash,
          title: t.gestureLock.resetGesturePassword,
          hint: t.gestureLock.resetPinHint,
        );
        if (!mounted) {
          return;
        }
        if (verified == true) {
          globalSettingCubit.updateState(
            (current) =>
                current.copyWith(appLockSetting: const AppLockSettingState()),
          );
          showSuccessToast(t.gestureLock.passwordCleared);
          updateStatus(t.gestureLock.passwordCleared);
          context.router.replace(const app_router.NavigationBar());
          return;
        }
        updateStatus(t.appBootstrap.pinVerifyFailed);
        return;
      }
      if (unlockResult != GestureUnlockResult.success) {
        updateStatus(t.appBootstrap.unlockCancelled);
        return;
      }
      updateStatus(t.appBootstrap.enteringApp);
    }

    context.router.replace(const app_router.NavigationBar());
  }
}
