import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/bika/bika_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/page/setting/bika/widgets.dart';
import 'package:zephyr/page/setting/common/setting_ui.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/json/json_value.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/util/sundry.dart';
import 'package:zephyr/widgets/toast.dart';

class PluginSettingsPage extends StatefulWidget {
  const PluginSettingsPage({
    super.key,
    required this.from,
    required this.pluginRuntimeName,
    required this.pluginDisplayName,
  });

  final From from;
  final String pluginRuntimeName;
  final String pluginDisplayName;

  @override
  State<PluginSettingsPage> createState() => _PluginSettingsPageState();
}

class _PluginSettingsPageState extends State<PluginSettingsPage> {
  bool _loading = true;
  String _error = '';
  List<Map<String, dynamic>> _sections = const [];
  List<Map<String, dynamic>> _actions = const [];
  Map<String, dynamic> _values = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final settingsResponse = await callUnifiedComicPlugin(
        from: widget.from,
        fnPath: 'getSettingsBundle',
        core: const <String, dynamic>{},
        extern: const <String, dynamic>{},
      );
      final settingsEnvelope = UnifiedPluginEnvelope.fromMap(settingsResponse);
      final settingsSections = asJsonList(
        settingsEnvelope.scheme['sections'],
      ).map((item) => asJsonMap(item)).toList();
      final values = asMap(settingsEnvelope.data['values']);

      List<Map<String, dynamic>> actions = const [];
      try {
        final capabilityResponse = await callUnifiedComicPlugin(
          from: widget.from,
          fnPath: 'getCapabilitiesBundle',
          core: const <String, dynamic>{},
          extern: const <String, dynamic>{},
        );
        final capabilityEnvelope = UnifiedPluginEnvelope.fromMap(
          capabilityResponse,
        );
        actions = asJsonList(capabilityEnvelope.scheme['actions'])
            .map((item) => asJsonMap(item))
            .where((item) => item['fnPath']?.toString() != 'dumpRuntimeInfo')
            .toList();
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _sections = settingsSections;
        _values = values;
        _actions = actions;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('${widget.pluginDisplayName} 设置')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: _load, child: const Text('重试')),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (widget.from == From.bika) ...[
                  _buildBikaAccountSection(context, colorScheme),
                  const SizedBox(height: 12),
                ],
                for (final section in _sections)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SchemeSectionCard(
                      title: section['title']?.toString() ?? '',
                      colorScheme: colorScheme,
                      children: asJsonList(section['fields'])
                          .map((item) => asJsonMap(item))
                          .map((field) => _buildField(context, field))
                          .toList(),
                    ),
                  ),
                if (_actions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _SchemeSectionCard(
                      title: '操作',
                      colorScheme: colorScheme,
                      children: _actions
                          .map((action) => _buildAction(context, action))
                          .toList(),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildBikaAccountSection(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return _SchemeSectionCard(
      title: '账号',
      colorScheme: colorScheme,
      children: [changeProfilePicture(context.router)],
    );
  }

  Widget _buildField(BuildContext context, Map<String, dynamic> field) {
    final key = field['key']?.toString() ?? '';
    final kind = field['kind']?.toString() ?? 'text';
    final label = field['label']?.toString() ?? key;
    final value = _values[key];

    if (kind == 'switch') {
      final current = value == true;
      return _FieldRow(
        title: label,
        subtitle: current ? '已开启' : '已关闭',
        trailing: Switch(
          value: current,
          thumbIcon: kSettingSwitchThumbIcon,
          onChanged: (next) => _commitField(field, next),
        ),
        onTap: () => _commitField(field, !current),
      );
    }

    if (kind == 'select' || kind == 'choice') {
      final options = _normalizeOptions(field['options']);
      final selected = value;
      final selectedLabel = options
          .firstWhere(
            (item) => item.value.toString() == selected?.toString(),
            orElse: () =>
                _OptionPair(label: selected?.toString() ?? '', value: selected),
          )
          .label;
      final triggerKey = GlobalKey();
      return _FieldRow(
        title: label,
        subtitle: '',
        trailing: _buildSelectTrigger(
          context,
          key: triggerKey,
          label: selectedLabel,
        ),
        onTap: () async {
          final picked = await _showChoiceMenu(
            context,
            triggerKey,
            options,
            selected,
          );
          if (picked == null) return;
          await _commitField(field, picked);
        },
      );
    }

    if (kind == 'multiChoice') {
      final options = _normalizeOptions(field['options']);
      final current = _asStringList(value);
      return _FieldRow(
        title: label,
        subtitle: current.isEmpty ? '未选择' : '已选 ${current.length} 项',
        trailing: const Icon(Icons.tune, size: 18),
        onTap: () async {
          final picked = await _showMultiChoiceDialog(
            context,
            label,
            options,
            current,
          );
          if (picked == null) return;
          await _commitField(field, picked);
        },
      );
    }

    final text = value?.toString() ?? '';
    final display = kind == 'password' && text.isNotEmpty
        ? '*' * text.length.clamp(6, 24)
        : text;
    return _FieldRow(
      title: label,
      subtitle: display,
      trailing: const Icon(Icons.edit_outlined, size: 18),
      onTap: () async {
        final next = await _showInputDialog(
          context,
          title: label,
          initialValue: text,
          obscure: kind == 'password',
        );
        if (next == null) return;
        await _commitField(field, next);
      },
    );
  }

  Widget _buildAction(BuildContext context, Map<String, dynamic> action) {
    final title = action['title']?.toString() ?? '未命名操作';
    final fnPath = action['fnPath']?.toString() ?? '';
    return _FieldRow(
      title: title,
      subtitle: fnPath,
      trailing: const Icon(Icons.play_arrow, size: 18),
      onTap: fnPath.isEmpty
          ? null
          : () async {
              try {
                final result = await callUnifiedComicPlugin(
                  from: widget.from,
                  fnPath: fnPath,
                  core: const <String, dynamic>{},
                  extern: const <String, dynamic>{},
                );
                final message = result['message']?.toString() ?? '执行成功';
                showSuccessToast(message);
                if (!mounted) return;
                if (fnPath == 'clearPluginSession' &&
                    widget.from == From.bika) {
                  this.context.router.push(LoginRoute(from: From.bika));
                }
              } catch (e) {
                showErrorToast('执行失败: $e');
              }
            },
    );
  }

  Widget _buildSelectTrigger(
    BuildContext context, {
    required GlobalKey key,
    required String label,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      key: key,
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.expand_more, size: 16),
        ],
      ),
    );
  }

  Future<dynamic> _showChoiceMenu(
    BuildContext context,
    GlobalKey triggerKey,
    List<_OptionPair> options,
    dynamic selected,
  ) async {
    final triggerContext = triggerKey.currentContext;
    if (triggerContext == null) return null;
    final box = triggerContext.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return null;

    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(Offset.zero, ancestor: overlay),
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    return showMenu<dynamic>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      constraints: const BoxConstraints(minWidth: 180),
      items: options
          .map(
            (option) => PopupMenuItem<dynamic>(
              value: option.value,
              child: Row(
                children: [
                  Expanded(child: Text(option.label)),
                  if (selected?.toString() == option.value?.toString())
                    Icon(
                      Icons.check,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Future<void> _commitField(Map<String, dynamic> field, dynamic value) async {
    final key = field['key']?.toString() ?? '';
    final fnPath = field['fnPath']?.toString().trim() ?? '';
    final persist = field['persist'] != false;

    if (fnPath.isNotEmpty) {
      await callUnifiedComicPlugin(
        from: widget.from,
        fnPath: fnPath,
        core: {'key': key, 'value': value},
        extern: const <String, dynamic>{},
      );
    }

    if (persist && key.isNotEmpty) {
      await savePluginConfigValue(widget.pluginRuntimeName, key, value);
    }

    await _saveFieldState(key, value);
  }

  Future<void> _saveFieldState(String key, dynamic value) async {
    if (!mounted) return;

    if (widget.from == From.bika) {
      final bikaCubit = context.read<BikaSettingCubit>();
      if (key == 'image.quality') {
        cacheInterceptor.clear();
        bikaCubit.updateImageQuality(value.toString());
      }
      if (key == 'network.proxy') {
        final parsed = int.tryParse(value.toString());
        if (parsed != null) {
          bikaCubit.updateProxy(parsed);
        }
      }
      if (key == 'download.slow') {
        bikaCubit.updateSlowDownload(value == true);
      }
      if (key == 'search.blockedCategories') {
        final list = _asStringList(value);
        bikaCubit.updateShieldCategoryMap({
          for (final item in categoryMap.keys) item: list.contains(item),
        });
      }
      if (key == 'home.blockedCategories') {
        final list = _asStringList(value);
        bikaCubit.updateShieldHomePageCategoriesMap({
          for (final item in homePageCategoriesMap.keys)
            item: list.contains(item),
        });
      }
    }

    setState(() {
      _values = Map<String, dynamic>.from(_values)..[key] = value;
    });
    showSuccessToast('已保存');
  }

  List<_OptionPair> _normalizeOptions(dynamic raw) {
    return asJsonList(raw).map((item) {
      if (item is Map) {
        final map = asJsonMap(item);
        return _OptionPair(
          label: map['label']?.toString() ?? map['value']?.toString() ?? '',
          value: map['value'],
        );
      }
      return _OptionPair(label: item.toString(), value: item);
    }).toList();
  }

  List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (value is Map) {
      return value.entries
          .where((entry) => entry.value == true)
          .map((entry) => entry.key.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  Future<List<String>?> _showMultiChoiceDialog(
    BuildContext context,
    String title,
    List<_OptionPair> options,
    List<String> initial,
  ) {
    final picked = initial.toSet();
    return showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 520,
          child: StatefulBuilder(
            builder: (context, setState) => SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options.map((item) {
                  final selected = picked.contains(item.value.toString());
                  return FilterChip(
                    label: Text(item.label),
                    selected: selected,
                    onSelected: (next) {
                      setState(() {
                        if (next) {
                          picked.add(item.value.toString());
                        } else {
                          picked.remove(item.value.toString());
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(picked.toList()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showInputDialog(
    BuildContext context, {
    required String title,
    required String initialValue,
    required bool obscure,
  }) {
    final controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: obscure,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

class _SchemeSectionCard extends StatelessWidget {
  const _SchemeSectionCard({
    required this.title,
    required this.colorScheme,
    required this.children,
  });

  final String title;
  final ColorScheme colorScheme;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
              child: Text(title, style: Theme.of(context).textTheme.labelLarge),
            ),
          ...children,
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyMedium),
                  if (subtitle.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _OptionPair {
  const _OptionPair({required this.label, required this.value});

  final String label;
  final dynamic value;
}
