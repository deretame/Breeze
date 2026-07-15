import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_socks_proxy/socks_proxy.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/config/router/router.gr.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/page/setting/common/setting_ui.dart';
import 'package:zephyr/src/rust/api/qjs.dart';
import 'package:zephyr/widgets/toast.dart';

Widget changeThemeColor(BuildContext context) {
  return ListTile(
    leading: const Icon(Icons.palette_outlined),
    title: Text(t.settings.themeColor),
    subtitle: Text(t.settings.themeColorSubtitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: () {
      AutoRouter.of(context).push(const ThemeColorRoute());
    },
  );
}

Widget socks5ProxyToggle(
  BuildContext context, {
  required bool enabled,
  required String currentProxy,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SwitchListTile(
        secondary: const Icon(Icons.router_outlined),
        title: Text(t.settings.proxy),
        subtitle: Text(t.settings.proxyEnabledSubtitle),
        thumbIcon: kSettingSwitchThumbIcon,
        value: enabled,
        onChanged: (value) async {
          final globalSettingCubit = context.read<GlobalSettingCubit>();
          globalSettingCubit.updateState(
            (current) => current.copyWith(socks5ProxyEnabled: value),
          );

          if (!value) {
            try {
              await setSocks5Proxy(proxy: '');
            } catch (_) {}
            SocksProxy.setProxy('DIRECT');
          }

          showSuccessToast(t.common.restartToTakeEffect);
        },
      ),
      if (enabled) socks5ProxyEdit(context, currentProxy),
    ],
  );
}

Widget socks5ProxyEdit(BuildContext context, String currentProxy) {
  return ListTile(
    leading: const Icon(Icons.link_outlined),
    title: Text(t.settings.proxyAddress),
    subtitle: Text(
      currentProxy.isEmpty
          ? t.settings.proxySubtitle
          : t.settings.proxyCurrent(currentProxy: currentProxy),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    trailing: const Icon(Icons.chevron_right),
    onTap: () async {
      final globalSettingCubit = context.read<GlobalSettingCubit>();
      var inputValue = currentProxy;

      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(t.settings.proxyAddress),
          content: TextFormField(
            initialValue: currentProxy,
            autofocus: true,
            onChanged: (value) => inputValue = value.trim(),
            decoration: InputDecoration(
              hintText: t.settings.proxyHint,
              border: const OutlineInputBorder(),
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

      if (result != null && result != currentProxy) {
        globalSettingCubit.updateState(
          (current) => current.copyWith(socks5Proxy: result),
        );
        showSuccessToast(t.common.restartToTakeEffect);
      }
    },
  );
}

Widget webdavSync(BuildContext context, SyncServiceType syncServiceType) {
  final title = switch (syncServiceType) {
    SyncServiceType.none => t.settings.syncConfig,
    _ => t.webdavSync.serviceTitle(
      service: switch (syncServiceType) {
        SyncServiceType.webdav => t.settings.syncServiceWebdav,
        SyncServiceType.s3 => t.settings.syncServiceS3,
        SyncServiceType.none => '',
      },
    ),
  };

  return ListTile(
    leading: const Icon(Icons.cloud_outlined),
    title: Text(title),
    subtitle: Text(t.settings.syncConfigSubtitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: () {
      AutoRouter.of(context).push(const WebDavSyncRoute());
    },
  );
}

Widget editMaskedKeywords(BuildContext context) {
  return ListTile(
    leading: const Icon(Icons.shield_outlined),
    title: Text(t.settings.maskedKeywords),
    subtitle: Text(t.settings.maskedKeywordsSubtitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: () {
      showDialog(
        context: context,
        builder: (context) => const _KeywordManagementDialog(),
      );
    },
  );
}

class _KeywordManagementDialog extends StatefulWidget {
  const _KeywordManagementDialog();

  @override
  State<_KeywordManagementDialog> createState() =>
      _KeywordManagementDialogState();
}

class _KeywordManagementDialogState extends State<_KeywordManagementDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 只需要在这里获取 Cubit
    final globalSettingCubit = context.read<GlobalSettingCubit>();

    return BlocBuilder<GlobalSettingCubit, GlobalSettingState>(
      builder: (context, state) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.settings.maskedKeywords,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t.settings.maskedKeywordsSubtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(
                    minHeight: 120,
                    maxHeight: 240,
                  ),
                  width: double.infinity,
                  child: SingleChildScrollView(
                    child: state.maskedKeywords.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 36),
                              child: Text(
                                t.settings.maskedKeywordsEmpty,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(
                              state.maskedKeywords.length,
                              (index) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  constraints: const BoxConstraints(
                                    maxWidth: 280,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          state.maskedKeywords[index],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: GestureDetector(
                                          onTap: () {
                                            final newList = List<String>.from(
                                              state.maskedKeywords,
                                            );
                                            newList.removeAt(index);
                                            globalSettingCubit.updateState(
                                              (current) => current.copyWith(
                                                maskedKeywords: newList,
                                              ),
                                            );
                                          },
                                          child: Icon(
                                            Icons.close,
                                            size: 14,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: t.settings.maskedKeywordsInputHint,
                          hintStyle: const TextStyle(fontSize: 14),
                          filled: true,
                          fillColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) =>
                            _addKeyword(globalSettingCubit, state),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: () => _addKeyword(globalSettingCubit, state),
                      icon: const Icon(Icons.add, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(t.common.done),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _addKeyword(GlobalSettingCubit cubit, GlobalSettingState state) {
    final text = _controller.text.trim();
    if (text.isNotEmpty && !state.maskedKeywords.contains(text)) {
      final newList = [...state.maskedKeywords, text];
      cubit.updateState((current) => current.copyWith(maskedKeywords: newList));
      _controller.clear();
    }
  }
}
