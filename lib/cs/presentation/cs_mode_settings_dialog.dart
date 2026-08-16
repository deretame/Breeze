import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:zephyr/cs/application/cs_mode_cubit.dart';
import 'package:zephyr/cs/domain/cs_connection_settings.dart';

Future<void> showCsModeSettingsDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (_) => const _CsModeSettingsDialog(),
  );
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
      await cubit.setMode(CsRunMode.cs);
      if (mounted) Navigator.of(context).pop();
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _switchToLocal() async {
    setState(() => _busy = true);
    try {
      await context.read<CsModeCubit>().setMode(CsRunMode.local);
      if (mounted) Navigator.of(context).pop();
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
