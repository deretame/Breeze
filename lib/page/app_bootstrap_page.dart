import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/plugin/plugin_registry_service.dart';
import 'package:zephyr/src/rust/api/qjs.dart';
import 'package:zephyr/util/compatible/compatible.dart';
import 'package:zephyr/util/router/router.gr.dart' as app_router;
import 'package:zephyr/util/sundry.dart';
import 'package:zephyr/util/tools_register.dart';
import 'package:zephyr/widgets/gesture_lock.dart';
import 'package:zephyr/widgets/toast.dart';

@RoutePage()
class AppBootstrapPage extends StatelessWidget {
  const AppBootstrapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StringSelectCubit()..setDate("初始化中...."),
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

    await registerPersistentCallbacks();

    await registerDartTools();

    initRustFunctions();

    if (mounted) await ensureCompatibleMigration(context);

    updateStatus("初始化中....");
    await PluginRegistryService.I.init();
    await PluginRegistryService.I.warmupPluginInfos();
    PluginRegistryService.I.scheduleSilentCloudUpdate(
      delay: const Duration(minutes: 1),
    );
    unawaited(() async {
      try {
        await PluginRegistryService.I.initializeActivePluginRuntimes();
      } catch (e, st) {
        logger.w('后台初始化插件 runtime 失败', error: e, stackTrace: st);
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
      updateStatus("请验证手势密码");
      final unlockResult = await showGestureUnlockDialog(
        context,
        expectedHash: appLockSetting.gesturePasswordHash,
        title: '应用已锁定',
        hint: '请先完成手势验证',
        showForgotPassword: true,
      );
      if (!mounted) {
        return;
      }
      if (unlockResult == GestureUnlockResult.forgotPassword) {
        final verified = await showPinVerifyDialog(
          context,
          expectedHash: appLockSetting.resetPinHash,
          title: '重置手势密码',
          hint: '请输入设置时保存的重置 PIN',
        );
        if (!mounted) {
          return;
        }
        if (verified == true) {
          globalSettingCubit.updateState(
            (current) =>
                current.copyWith(appLockSetting: const AppLockSettingState()),
          );
          showSuccessToast('密码已清空，请重新设置');
          updateStatus("密码已清空，请重新设置");
          context.router.replace(const app_router.NavigationBar());
          return;
        }
        updateStatus("PIN 验证未通过");
        return;
      }
      if (unlockResult != GestureUnlockResult.success) {
        updateStatus("已取消解锁");
        return;
      }
      updateStatus("验证成功，正在进入应用");
    }

    context.router.replace(const app_router.NavigationBar());
  }
}
