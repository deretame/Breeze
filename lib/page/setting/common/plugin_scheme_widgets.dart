import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/plugin/bridge/plugin_config_bridge.dart';
import 'package:zephyr/widgets/fluent_dropdown.dart';
import 'package:zephyr/widgets/toast.dart';

class PluginSettingSchemeSection extends StatefulWidget {
  const PluginSettingSchemeSection({
    super.key,
    required this.from,
    required this.pluginName,
    this.onValueChanged,
  });

  final String from;
  final String pluginName;
  final Future<void> Function(String key, dynamic value)? onValueChanged;

  @override
  State<PluginSettingSchemeSection> createState() =>
      _PluginSettingSchemeSectionState();
}

class _PluginSettingSchemeSectionState
    extends State<PluginSettingSchemeSection> {
  late Future<UnifiedPluginEnvelope> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<UnifiedPluginEnvelope> _load() async {
    final response = await callUnifiedComicPlugin(
      from: widget.from,
      fnPath: 'getSettingsBundle',
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
          return ListTile(title: Text(t.plugin.pluginSettingsLoading));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return ListTile(
            title: Text(t.plugin.pluginSettingsLoadFailed),
            subtitle: Text(snapshot.error.toString()),
            trailing: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() => _future = _load()),
            ),
          );
        }

        final envelope = snapshot.data!;
        final sections = asList(
          envelope.scheme['sections'],
        ).map((item) => asMap(item)).toList();
        final values = asMap(envelope.data['values']);
        final widgets = <Widget>[];

        for (final section in sections) {
          final title = section['title']?.toString() ?? '';
          if (title.isNotEmpty) {
            widgets.add(
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(title, style: const TextStyle(fontSize: 13)),
              ),
            );
          }
          final fields = asList(section['fields']).map((item) => asMap(item));
          for (final field in fields) {
            widgets.add(_buildField(field, values));
          }
        }

        return Column(children: widgets);
      },
    );
  }

  Widget _buildField(Map<String, dynamic> field, Map<String, dynamic> values) {
    final key = field['key']?.toString() ?? '';
    final label = field['label']?.toString() ?? key;
    final kind = field['kind']?.toString() ?? 'text';
    final value = values[key];

    if (kind == 'select') {
      final options = asList(
        field['options'],
      ).map((e) => e.toString()).toList();
      final current =
          value?.toString() ?? (options.isNotEmpty ? options.first : '');
      final effectiveValue = options.contains(current)
          ? current
          : (options.isEmpty ? '' : options.first);
      return ListTile(
        title: Text(label),
        trailing: FluentDropdown<String>(
          value: effectiveValue,
          displayValue: effectiveValue,
          items: {for (final option in options) option: option},
          onChanged: options.isEmpty
              ? null
              : (next) async {
                  await _persistField(key, next);
                },
        ),
      );
    }

    if (kind == 'switch') {
      final current = value == true;
      return SwitchListTile(
        title: Text(label),
        value: current,
        onChanged: (next) async {
          await _persistField(key, next);
        },
      );
    }

    return ListTile(
      title: Text(label),
      subtitle: Text(value?.toString() ?? ''),
      trailing: const Icon(Icons.edit_outlined),
      onTap: () async {
        final next = await _showInputDialog(
          context,
          title: label,
          initialValue: value?.toString() ?? '',
          obscure: kind == 'password',
        );
        if (next == null) return;
        await _persistField(key, next);
      },
    );
  }

  Future<void> _persistField(String key, dynamic value) async {
    await savePluginConfigValue(widget.pluginName, key, value);
    if (widget.onValueChanged != null) {
      await widget.onValueChanged!(key, value);
    }
    if (!mounted) return;
    showSuccessToast(t.plugin.saved);
    setState(() => _future = _load());
  }
}

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

Future<String?> _showInputDialog(
  BuildContext context, {
  required String title,
  required String initialValue,
  required bool obscure,
}) async {
  final controller = TextEditingController(text: initialValue);
  final value = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        obscureText: obscure,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.common.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: Text(t.common.save),
        ),
      ],
    ),
  );
  controller.dispose();
  return value;
}
