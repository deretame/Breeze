import 'dart:convert';

import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/src/rust/api/qjs.dart';

@RoutePage()
class QjsRuntimeDebugPage extends StatefulWidget {
  const QjsRuntimeDebugPage({super.key});

  @override
  State<QjsRuntimeDebugPage> createState() => _QjsRuntimeDebugPageState();
}

class _QjsRuntimeDebugPageState extends State<QjsRuntimeDebugPage> {
  final TextEditingController _runtimeController = TextEditingController();

  bool _loading = false;
  String? _status;
  String _output = '';

  @override
  void dispose() {
    _runtimeController.dispose();
    super.dispose();
  }

  Future<void> _loadSnapshot() async {
    final runtimeName = _runtimeController.text.trim();
    if (runtimeName.isEmpty) {
      setState(() {
        _status = '请先输入运行时 ID';
      });
      return;
    }

    setState(() {
      _loading = true;
      _status = null;
    });

    try {
      final raw = await qjsDebugSnapshot(runtimeName: runtimeName);
      final decoded = jsonDecode(raw);
      const encoder = JsonEncoder.withIndent('  ');
      final pretty = encoder.convert(decoded);
      if (!mounted) return;
      setState(() {
        _output = pretty;
        _status = '已抓取 ${DateTime.now()}';
      });
    } catch (e, st) {
      logger.e('qjs runtime debug snapshot failed', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _status = '抓取失败: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _copyOutput() async {
    if (_output.isEmpty) {
      setState(() {
        _status = '当前没有可复制的内容';
      });
      return;
    }
    await Clipboard.setData(ClipboardData(text: _output));
    if (!mounted) return;
    setState(() {
      _status = '已复制到剪贴板';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('QJS 运行时调试')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '调试快照',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _runtimeController,
                    decoration: const InputDecoration(
                      labelText: '运行时 ID',
                      border: OutlineInputBorder(),
                      hintText: '例如 0a0e5858-a467-4702-994a-79e608a4589d',
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _loadSnapshot(),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: _loading ? null : _loadSnapshot,
                        icon: const Icon(Icons.play_arrow_outlined),
                        label: Text(_loading ? '抓取中' : '抓取快照'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _loading ? null : _copyOutput,
                        icon: const Icon(Icons.copy_all_outlined),
                        label: const Text('复制输出'),
                      ),
                    ],
                  ),
                  if (_status != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _status!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SelectableText(
            _output.isEmpty ? '暂无输出' : _output,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'JetBrainsMonoNL-Regular',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
