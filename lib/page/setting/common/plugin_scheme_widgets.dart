import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/widgets/toast.dart';

class PluginAdvancedActionSection extends StatefulWidget {
  const PluginAdvancedActionSection({super.key, required this.from});

  final String from;

  @override
  State<PluginAdvancedActionSection> createState() =>
      _PluginAdvancedActionSectionState();
}

class _PluginAdvancedActionSectionState
    extends State<PluginAdvancedActionSection> {
  late Future<UnifiedPluginEnvelope> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<UnifiedPluginEnvelope> _load() async {
    final response = await callUnifiedComicPlugin(
      from: widget.from,
      fnPath: 'getCapabilitiesBundle',
      core: const <String, dynamic>{},
      extern: const <String, dynamic>{},
    );
    return UnifiedPluginEnvelope.fromMap(response);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UnifiedPluginEnvelope>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const ListTile(title: Text('高级能力加载中...'));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final actions = asList(
          snapshot.data!.scheme['actions'],
        ).map((item) => asMap(item)).toList();
        if (actions.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: actions.map((action) {
            final title = action['title']?.toString() ?? t.plugin.unnamedAction;
            final fnPath = action['fnPath']?.toString() ?? '';
            return ListTile(
              leading: const Icon(Icons.extension_outlined),
              title: Text(title),
              subtitle: Text(fnPath),
              onTap: () async {
                if (fnPath.isEmpty) {
                  showInfoToast(t.plugin.actionNotExecutable);
                  return;
                }

                try {
                  final dialogContext = this.context;
                  final result = await callUnifiedComicPlugin(
                    from: widget.from,
                    fnPath: fnPath,
                    core: const <String, dynamic>{},
                    extern: const <String, dynamic>{},
                  );

                  if (!dialogContext.mounted) return;
                  await showDialog<void>(
                    context: dialogContext,
                    builder: (context) => AlertDialog(
                      title: Text(title),
                      content: SingleChildScrollView(
                        child: SelectableText(
                          const JsonEncoder.withIndent('  ').convert(result),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(t.common.close),
                        ),
                      ],
                    ),
                  );
                } catch (e) {
                  showInfoToast(t.plugin.executeFailed(error: e));
                }
              },
            );
          }).toList(),
        );
      },
    );
  }
}
