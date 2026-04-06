import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/plugin/plugin_registry_service.dart';
import 'package:zephyr/src/rust/api/qjs.dart';
import 'package:zephyr/util/compatible/compatible.dart';
import 'package:zephyr/util/router/router.gr.dart' as app_router;
import 'package:zephyr/util/sundry.dart';
import 'package:zephyr/util/update/check_update.dart';

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

    await registerPersistentCallbacks();

    initRustFunctions();

    final appVersion = await getAppVersion();
    registerFunction(
      functionName: 'getAppVersion',
      dartCallback: (temp) async => appVersion,
    );

    if (mounted) await ensureCompatibleMigration(context);

    updateStatus("初始化中....");
    await PluginRegistryService.I.init();
    await PluginRegistryService.I.warmupPluginInfos();
    unawaited(() async {
      try {
        await PluginRegistryService.I.initializeActivePluginRuntimes();
      } catch (e, st) {
        logger.w('后台初始化插件 runtime 失败', error: e, stackTrace: st);
      }
    }());

    await Future.delayed(const Duration(milliseconds: 200));

    if (!mounted) return;
    context.router.replace(const app_router.NavigationBar());
  }
}
