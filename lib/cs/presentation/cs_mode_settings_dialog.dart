import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:zephyr/cs/application/cs_mode_cubit.dart';
import 'package:zephyr/cs/domain/cs_connection_settings.dart';

Future<void> showCsModeSettingsDialog(BuildContext context) async {
  final requestedMode = await showDialog<CsRunMode>(
    context: context,
    builder: (_) => const _CsModeSettingsDialog(),
  );
  if (requestedMode != null && context.mounted) {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(requestedMode == CsRunMode.cs ? 'CS 模式已启用' : '已请求关闭 CS 模式'),
        content: const Text('配置将在重启应用后完整生效。'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}

class _CsModeSettingsDialog extends StatefulWidget {
  const _CsModeSettingsDialog();

  @override
  State<_CsModeSettingsDialog> createState() => _CsModeSettingsDialogState();
}

class _CsModeSettingsDialogState extends State<_CsModeSettingsDialog> {
  late final TextEditingController _serverController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late CsDownloadMode _downloadMode;
  bool _register = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final settings = context.read<CsModeCubit>().state;
    _serverController = TextEditingController(text: settings.serverUrl);
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _downloadMode = settings.downloadMode;
  }

  @override
  void dispose() {
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final serverUrl = _serverController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (serverUrl.isEmpty || username.isEmpty || password.isEmpty) {
      setState(() => _error = '请输入服务端地址、用户名和密码');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final cubit = context.read<CsModeCubit>();
      await cubit.configure(serverUrl: serverUrl, downloadMode: _downloadMode);
      await cubit.login(
        username: username,
        password: password,
        register: _register,
      );
      if (!mounted) return;

      final migrateData = await _askMigrationChoice(
        context,
        title: '迁移本地数据',
        content:
            '是否将本地收藏、历史、追更、文件夹、插件和设置迁移到服务端？\n\n'
            '选择不迁移时，本地数据会保留且不会上传。',
        acceptLabel: '迁移数据',
        rejectLabel: '暂不迁移',
      );
      if (migrateData == null) return;

      var migrateDownloads = false;
      if (migrateData) {
        if (!mounted) return;
        final downloadChoice = await _askMigrationChoice(
          context,
          title: '迁移下载数据',
          content:
              '是否将已下载漫画的记录和文件迁移到服务端？\n\n'
              '不迁移时，下载仍保存并使用当前设备上的本地文件。',
          acceptLabel: '迁移下载',
          rejectLabel: '保留本地下载',
        );
        if (downloadChoice == null) return;
        migrateDownloads = downloadChoice;
      }

      await cubit.enableCsMode(
        migrateData: migrateData,
        migrateDownloads: migrateDownloads,
      );
      if (mounted) Navigator.of(context).pop(CsRunMode.cs);
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _switchToLocal() async {
    final settings = context.read<CsModeCubit>().state;
    final overwriteRemoteData = await _askMigrationChoice(
      context,
      title: '关闭 CS 模式',
      content: settings.downloadDataMigrated
          ? '是否使用服务端数据覆盖本地数据？\n\n'
                '这会覆盖本地收藏、历史、追更、文件夹、插件、插件配置和设置，'
                '并按照进入 CS 模式时的选择覆盖已迁移的下载漫画文件。'
          : '是否使用服务端数据覆盖本地数据？\n\n'
                '这会覆盖本地收藏、历史、追更、文件夹、插件、插件配置和设置。\n'
                '本地下载未迁移到服务端，因此会保留本地下载文件。',
      acceptLabel: '覆盖本地数据',
      rejectLabel: '保留本地数据',
    );
    if (overwriteRemoteData == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await context.read<CsModeCubit>().closeCsMode(
        overwriteRemoteData: overwriteRemoteData,
      );
      if (mounted) Navigator.of(context).pop(CsRunMode.local);
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<CsModeCubit>().state;
    return AlertDialog(
      title: const Text('CS 模式'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _serverController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: '服务端地址',
                  hintText: 'http://127.0.0.1:8787',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: '用户名'),
                autofillHints: const [AutofillHints.username],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: '密码'),
                autofillHints: const [AutofillHints.password],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<CsDownloadMode>(
                initialValue: _downloadMode,
                decoration: const InputDecoration(labelText: '下载位置'),
                items: const [
                  DropdownMenuItem(
                    value: CsDownloadMode.client,
                    child: Text('客户端下载（保持本地文件）'),
                  ),
                  DropdownMenuItem(
                    value: CsDownloadMode.server,
                    child: Text('服务端下载（远程存储）'),
                  ),
                ],
                onChanged: _busy
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _downloadMode = value);
                        }
                      },
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('注册新账号'),
                value: _register,
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _register = value),
              ),
              if (settings.isCsMode)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('当前已连接到 CS 服务端'),
                ),
              if (settings.pendingMode == CsRunMode.cs)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('CS 模式将在重启应用后生效'),
                ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _error!,
                    style: TextStyle(color: ThemeData().colorScheme.error),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (settings.isCsMode)
          TextButton(
            onPressed: _busy ? null : _switchToLocal,
            child: const Text('切回本地模式'),
          ),
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _busy ? null : _connect,
          child: _busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('连接并启用'),
        ),
      ],
    );
  }
}

Future<bool?> _askMigrationChoice(
  BuildContext context, {
  required String title,
  required String content,
  required String acceptLabel,
  required String rejectLabel,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(rejectLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(acceptLabel),
        ),
      ],
    ),
  );
}
