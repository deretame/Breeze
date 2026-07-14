import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/config/router/router.gr.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/page/setting/common/setting_ui.dart';
import 'package:zephyr/util/impeller_config.dart';
import 'package:zephyr/widgets/toast.dart';

@RoutePage()
class DebugSettingPage extends StatefulWidget {
  const DebugSettingPage({super.key});

  @override
  State<DebugSettingPage> createState() => _DebugSettingPageState();
}

class _DebugSettingPageState extends State<DebugSettingPage> {
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

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<GlobalSettingCubit>();
    final state = cubit.state;

    return SettingPageShell(
      title: t.settings.debug,
      child: ListView(
        children: [
          settingSectionTitle(
            context,
            t.settings.debug,
            icon: Icons.bug_report_outlined,
          ),
          _logAddress(state, cubit),
          _enableMemoryDebug(state, cubit),
          if (defaultTargetPlatform == TargetPlatform.android)
            _forceEnableImpeller(state, cubit),
          if (kDebugMode) ...[
            ListTile(
              leading: const Icon(Icons.colorize_outlined),
              title: Text(t.settings.colorPreview),
              subtitle: Text(t.settings.colorPreviewSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.pushRoute(const ShowColorRoute()),
            ),
            ListTile(
              leading: const Icon(Icons.developer_mode_outlined),
              title: Text(t.settings.qjsRuntimeDebug),
              subtitle: Text(t.settings.qjsRuntimeDebugSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.pushRoute(const QjsRuntimeDebugRoute()),
            ),
            ListTile(
              leading: const Icon(Icons.memory_outlined),
              title: Text(t.settings.coremlDebug),
              subtitle: Text(t.settings.coremlDebugSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.pushRoute(const CoreMLUpscaleDebugRoute()),
            ),
          ],
          const SizedBox(height: 32),
        ],
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
}
