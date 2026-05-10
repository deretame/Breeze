import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/plugin_settings/cubit/plugin_settings_cubit.dart';
import 'package:zephyr/page/plugin_settings/widgets/plugin_settings_sections.dart';
import 'package:zephyr/page/setting/common/plugin_user_info_card.dart';
import 'package:zephyr/page/setting/common/setting_ui.dart';
import 'package:zephyr/util/json/json_value.dart';
import 'package:zephyr/widgets/multi_choice_list_dialog.dart';

class PluginSettingsContent extends StatelessWidget {
  const PluginSettingsContent({
    super.key,
    required this.from,
    required this.pluginRuntimeName,
    required this.state,
    required this.debugEnabled,
    required this.debugUrl,
    required this.deleted,
    required this.colorScheme,
    required this.onUpdateDebugConfig,
    required this.onConfirmDeletePlugin,
    required this.onCommitField,
    required this.onRunAction,
  });

  final String from;
  final String pluginRuntimeName;
  final PluginSettingsState state;
  final bool debugEnabled;
  final String debugUrl;
  final bool deleted;
  final ColorScheme colorScheme;
  final Future<void> Function({required bool enabled, required String url})
  onUpdateDebugConfig;
  final Future<void> Function() onConfirmDeletePlugin;
  final Future<void> Function(Map<String, dynamic> field, dynamic value)
  onCommitField;
  final Future<void> Function(Map<String, dynamic> action) onRunAction;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        _buildManagementSection(context),
        ..._buildBodySections(context),
      ],
    );
  }

  Widget _buildManagementSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PluginSettingsSectionCard(
        title: '插件管理',
        colorScheme: colorScheme,
        children: _buildManagementRows(context),
      ),
    );
  }

  List<Widget> _buildManagementRows(BuildContext context) {
    final rows = <Widget>[
      _buildDebugModeRow(),
      if (debugEnabled) _buildDebugUrlRow(context),
      _buildDeletePluginRow(),
    ];
    return rows;
  }

  Widget _buildDebugModeRow() {
    return PluginSettingsFieldRow(
      title: '调试模式',
      subtitle: debugEnabled ? '已开启' : '已关闭',
      trailing: Switch(
        value: debugEnabled,
        thumbIcon: kSettingSwitchThumbIcon,
        onChanged: deleted
            ? null
            : (next) => onUpdateDebugConfig(enabled: next, url: debugUrl),
      ),
      onTap: deleted
          ? null
          : () => onUpdateDebugConfig(enabled: !debugEnabled, url: debugUrl),
    );
  }

  Widget _buildDebugUrlRow(BuildContext context) {
    return PluginSettingsFieldRow(
      title: '调试地址',
      subtitle: debugUrl.isNotEmpty ? debugUrl : '未设置',
      trailing: const Icon(Icons.edit_outlined, size: 18),
      onTap: deleted
          ? null
          : () async {
              final next = await _showInputDialog(
                context,
                title: '调试地址',
                initialValue: debugUrl,
                obscure: false,
              );
              if (next == null) return;
              await onUpdateDebugConfig(
                enabled: debugEnabled,
                url: next.trim(),
              );
            },
    );
  }

  Widget _buildDeletePluginRow() {
    return PluginSettingsFieldRow(
      title: '删除插件',
      subtitle: '彻底删除插件，并删除相关数据',
      trailing: Icon(
        Icons.delete_outline,
        size: 18,
        color: deleted ? colorScheme.outline : colorScheme.error,
      ),
      onTap: deleted ? null : onConfirmDeletePlugin,
    );
  }

  List<Widget> _buildBodySections(BuildContext context) {
    if (state.loading) {
      return [_buildLoadingSection()];
    }
    if (state.error.isNotEmpty) {
      return [_buildErrorSection(context)];
    }

    final sections = <Widget>[];
    final userInfoSection = _buildUserInfoSection(context);
    if (userInfoSection != null) {
      sections.add(userInfoSection);
    }
    sections.addAll(_buildSettingSections(context));
    final actionsSection = _buildActionsSection(context);
    if (actionsSection != null) {
      sections.add(actionsSection);
    }
    return sections;
  }

  Widget _buildLoadingSection() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: PluginSettingsSectionCard(
        title: '插件设置',
        colorScheme: colorScheme,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(state.error),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () =>
                      context.read<PluginSettingsCubit>().load(from),
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildUserInfoSection(BuildContext context) {
    if (!state.canShowUserInfo) {
      return null;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PluginSettingsSectionCard(
        title: state.userInfo['title']?.toString() ?? '用户信息',
        colorScheme: colorScheme,
        children: _buildUserInfoChildren(context),
      ),
    );
  }

  List<Widget> _buildUserInfoChildren(BuildContext context) {
    if (state.loadingUserInfo) {
      return const [
        Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (state.userInfoError.isNotEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: Text(state.userInfoError)),
              OutlinedButton(
                onPressed: () =>
                    context.read<PluginSettingsCubit>().loadUserInfo(from),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ];
    }
    if (state.userInfo.isNotEmpty) {
      return [_buildUserInfoCard()];
    }
    return const [Padding(padding: EdgeInsets.all(16), child: Text('暂无用户信息'))];
  }

  Widget _buildUserInfoCard() {
    return PluginUserInfoCard(
      from: from,
      avatarUrl: asJsonMap(state.userInfo['avatar'])['url']?.toString() ?? '',
      avatarPath: asJsonMap(state.userInfo['avatar'])['path']?.toString() ?? '',
      lines: asJsonList(
        state.userInfo['lines'],
      ).map((item) => item?.toString() ?? '').toList(),
    );
  }

  List<Widget> _buildSettingSections(BuildContext context) {
    return state.sections
        .map(
          (section) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PluginSettingsSectionCard(
              title: section['title']?.toString() ?? '',
              colorScheme: colorScheme,
              children: asJsonList(section['fields'])
                  .map((item) => asJsonMap(item))
                  .map((field) => _buildField(context, field))
                  .toList(),
            ),
          ),
        )
        .toList();
  }

  Widget? _buildActionsSection(BuildContext context) {
    if (state.actions.isEmpty) {
      return null;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: PluginSettingsSectionCard(
        title: '操作',
        colorScheme: colorScheme,
        children: state.actions
            .map((action) => _buildAction(context, action))
            .toList(),
      ),
    );
  }

  Widget _buildField(BuildContext context, Map<String, dynamic> field) {
    final key = field['key']?.toString() ?? '';
    final kind = field['kind']?.toString() ?? 'text';
    final label = field['label']?.toString() ?? key;
    final value = state.values[key];

    if (kind == 'switch') {
      return _buildSwitchField(field, label, value);
    }
    if (kind == 'select' || kind == 'choice') {
      return _buildSelectField(context, field, label, value);
    }
    if (kind == 'multiChoice') {
      return _buildMultiChoiceField(context, field, label, value);
    }
    return _buildTextField(context, field, label, value, kind);
  }

  Widget _buildSwitchField(
    Map<String, dynamic> field,
    String label,
    dynamic value,
  ) {
    final current = value == true;
    return PluginSettingsFieldRow(
      title: label,
      subtitle: current ? '已开启' : '已关闭',
      trailing: Switch(
        value: current,
        thumbIcon: kSettingSwitchThumbIcon,
        onChanged: (next) => onCommitField(field, next),
      ),
      onTap: () => onCommitField(field, !current),
    );
  }

  Widget _buildSelectField(
    BuildContext context,
    Map<String, dynamic> field,
    String label,
    dynamic value,
  ) {
    final options = _normalizeOptions(field['options']);
    final selectedLabel = options
        .firstWhere(
          (item) => item.value.toString() == value?.toString(),
          orElse: () => PluginSettingsOptionPair(
            label: value?.toString() ?? '',
            value: value,
          ),
        )
        .label;
    final triggerKey = GlobalKey();

    return PluginSettingsFieldRow(
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
          value,
        );
        if (picked == null) return;
        await onCommitField(field, picked);
      },
    );
  }

  Widget _buildMultiChoiceField(
    BuildContext context,
    Map<String, dynamic> field,
    String label,
    dynamic value,
  ) {
    final options = _normalizeOptions(field['options']);
    final current = _asStringList(value);
    return PluginSettingsFieldRow(
      title: label,
      subtitle: current.isEmpty ? '未选择' : '已选 ${current.length} 项',
      trailing: const Icon(Icons.tune, size: 18),
      onTap: () async {
        final picked = await showMultiChoiceListDialog(
          context,
          title: label,
          options: options
              .map(
                (item) => MultiChoiceDialogOption(
                  label: item.label,
                  value: item.value.toString(),
                ),
              )
              .toList(),
          initialSelected: current,
          confirmText: '保存',
        );
        if (picked == null) return;
        await onCommitField(field, picked.toList());
      },
    );
  }

  Widget _buildTextField(
    BuildContext context,
    Map<String, dynamic> field,
    String label,
    dynamic value,
    String kind,
  ) {
    final text = value?.toString() ?? '';
    return PluginSettingsFieldRow(
      title: label,
      subtitle: _buildTextFieldDisplay(kind, text),
      trailing: const Icon(Icons.edit_outlined, size: 18),
      onTap: () async {
        final next = await _showInputDialog(
          context,
          title: label,
          initialValue: text,
          obscure: kind == 'password',
        );
        if (next == null) return;
        await onCommitField(field, next);
      },
    );
  }

  String _buildTextFieldDisplay(String kind, String text) {
    if (kind == 'password' && text.isNotEmpty) {
      return '*' * text.length.clamp(6, 24);
    }
    return text;
  }

  Widget _buildAction(BuildContext context, Map<String, dynamic> action) {
    final title = action['title']?.toString() ?? '未命名操作';
    final fnPath = action['fnPath']?.toString() ?? '';
    return PluginSettingsFieldRow(
      title: title,
      subtitle: fnPath,
      trailing: const Icon(Icons.play_arrow, size: 18),
      onTap: fnPath.isEmpty ? null : () => onRunAction(action),
    );
  }

  Widget _buildSelectTrigger(
    BuildContext context, {
    required GlobalKey key,
    required String label,
  }) {
    final localColorScheme = Theme.of(context).colorScheme;
    return Container(
      key: key,
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: localColorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: localColorScheme.outlineVariant),
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
    List<PluginSettingsOptionPair> options,
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

  List<PluginSettingsOptionPair> _normalizeOptions(dynamic raw) {
    return asJsonList(raw).map((item) {
      if (item is Map) {
        final map = asJsonMap(item);
        return PluginSettingsOptionPair(
          label: map['label']?.toString() ?? map['value']?.toString() ?? '',
          value: map['value'],
        );
      }
      return PluginSettingsOptionPair(label: item.toString(), value: item);
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
