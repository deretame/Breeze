import 'dart:convert';

import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zephyr/i18n/strings.g.dart';
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
        _status = t.settings.qjsRuntimeFillId;
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
        _status = t.settings.qjsRuntimeCapturedAt(
          dateTime: DateTime.now().toString(),
        );
      });
    } catch (e, st) {
      logger.e('qjs runtime debug snapshot failed', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _status = t.settings.qjsRuntimeCaptureFailed(error: e);
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
        _status = t.settings.qjsRuntimeNoCopyContent;
      });
      return;
    }
    await Clipboard.setData(ClipboardData(text: _output));
    if (!mounted) return;
    setState(() {
      _status = t.settings.qjsRuntimeCopied;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.settings.qjsRuntimeDebug)),
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
                    t.settings.qjsRuntimeSnapshot,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _runtimeController,
                    decoration: InputDecoration(
                      labelText: t.settings.qjsRuntimeIdLabel,
                      border: const OutlineInputBorder(),
                      hintText: t.settings.qjsRuntimeIdHint,
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
                        label: Text(
                          _loading
                              ? t.settings.qjsRuntimeCapturing
                              : t.settings.qjsRuntimeCapture,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _loading ? null : _copyOutput,
                        icon: const Icon(Icons.copy_all_outlined),
                        label: Text(t.settings.qjsRuntimeCopyOutput),
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
            _output.isEmpty ? t.settings.qjsRuntimeNoOutput : _output,
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
