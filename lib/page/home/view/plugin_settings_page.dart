import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/cubit/plugin_registry_cubit.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/plugin/plugin_registry_service.dart';
import 'package:zephyr/page/setting/common/plugin_user_info_card.dart';
import 'package:zephyr/page/setting/common/setting_ui.dart';
import 'package:zephyr/util/json/json_value.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/util/sundry.dart';
import 'package:zephyr/widgets/multi_choice_list_dialog.dart';
import 'package:zephyr/widgets/toast.dart';

class PluginSettingsPage extends StatefulWidget {
  const PluginSettingsPage({
    super.key,
    required this.from,
    required this.pluginUuid,
    required this.pluginRuntimeName,
    required this.pluginDisplayName,
  });

  final String from;
  final String pluginUuid;
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
  Map<String, dynamic> _userInfo = const {};
  bool _canShowUserInfo = false;
  bool _loadingUserInfo = false;
  String _userInfoError = '';

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
      final canShowUserInfo = settingsEnvelope.data['canShowUserInfo'] == true;

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
        _userInfo = const <String, dynamic>{};
        _canShowUserInfo = canShowUserInfo;
        _userInfoError = '';
        _actions = actions;
        _loading = false;
      });
      if (canShowUserInfo) {
        _loadUserInfo();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadUserInfo() async {
    if (_loadingUserInfo) {
      return;
    }
    setState(() {
      _loadingUserInfo = true;
      _userInfoError = '';
    });
    try {
      final response = await callUnifiedComicPlugin(
        from: widget.from,
        fnPath: 'getUserInfoBundle',
        core: const <String, dynamic>{},
        extern: const <String, dynamic>{},
      );
      final envelope = UnifiedPluginEnvelope.fromMap(response);
      if (!mounted) return;
      setState(() {
        _userInfo = asMap(envelope.data);
        _loadingUserInfo = false;
        _userInfoError = '';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingUserInfo = false;
        _userInfoError = '用户信息加载失败';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pluginState = context
        .watch<PluginRegistryCubit>()
        .state[widget.pluginUuid];
    final debugEnabled = pluginState?.debug ?? false;
    final debugUrl = pluginState?.debugUrl ?? '';
    final deleted = pluginState?.isDeleted == true;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.pluginDisplayName} 设置'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SchemeSectionCard(
                  title: '插件管理',
                  colorScheme: colorScheme,
                  children: [
                    _FieldRow(
                      title: '调试模式',
                      subtitle: debugEnabled ? '已开启' : '已关闭',
                      trailing: Switch(
                        value: debugEnabled,
                        thumbIcon: kSettingSwitchThumbIcon,
                        onChanged: deleted
                            ? null
                            : (next) => _updateDebugConfig(
                                enabled: next,
                                url: debugUrl,
                              ),
                      ),
                      onTap: deleted
                          ? null
                          : () => _updateDebugConfig(
                              enabled: !debugEnabled,
                              url: debugUrl,
                            ),
                    ),
                    _FieldRow(
                      title: '调试地址',
                      subtitle: debugEnabled
                          ? (debugUrl.isNotEmpty ? debugUrl : '未设置')
                          : '请先开启调试模式',
                      trailing: Icon(
                        debugEnabled ? Icons.edit_outlined : Icons.lock_outline,
                        size: 18,
                      ),
                      onTap: deleted || !debugEnabled
                          ? null
                          : () async {
                              final next = await _showInputDialog(
                                context,
                                title: '调试地址',
                                initialValue: debugUrl,
                                obscure: false,
                              );
                              if (next == null) return;
                              await _updateDebugConfig(
                                enabled: debugEnabled,
                                url: next.trim(),
                              );
                            },
                    ),
                    _FieldRow(
                      title: '删除插件',
                      subtitle: '彻底删除插件',
                      trailing: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: deleted
                            ? colorScheme.outline
                            : colorScheme.error,
                      ),
                      onTap: deleted ? null : _confirmDeletePlugin,
                    ),
                  ],
                ),
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _SchemeSectionCard(
                    title: '插件设置',
                    colorScheme: colorScheme,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_error),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: _load,
                              child: const Text('重试'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                if (_canShowUserInfo)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SchemeSectionCard(
                      title: _userInfo['title']?.toString() ?? '用户信息',
                      colorScheme: colorScheme,
                      children: _loadingUserInfo
                          ? const [
                              Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ]
                          : _userInfoError.isNotEmpty
                          ? [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Expanded(child: Text(_userInfoError)),
                                    OutlinedButton(
                                      onPressed: _loadUserInfo,
                                      child: const Text('重试'),
                                    ),
                                  ],
                                ),
                              ),
                            ]
                          : _userInfo.isNotEmpty
                          ? [
                              PluginUserInfoCard(
                                from: widget.from,
                                avatarUrl:
                                    asMap(
                                      _userInfo['avatar'],
                                    )['url']?.toString() ??
                                    '',
                                avatarPath:
                                    asMap(
                                      _userInfo['avatar'],
                                    )['path']?.toString() ??
                                    '',
                                lines: asJsonList(_userInfo['lines'])
                                    .map((item) => item?.toString() ?? '')
                                    .toList(),
                              ),
                            ]
                          : const [
                              Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('暂无用户信息'),
                              ),
                            ],
                    ),
                  ),
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateDebugConfig({
    required bool enabled,
    required String url,
  }) async {
    await PluginRegistryService.I.updateDebugConfig(
      widget.pluginUuid,
      debug: enabled,
      debugUrl: url,
    );
    if (!mounted) return;
    showSuccessToast('插件调试配置已更新');
  }

  Future<void> _confirmDeletePlugin() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除插件'),
        content: const Text('删除后将从插件列表彻底移除，并清理该插件的所有数据。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
    if (ok != true) {
      return;
    }
    try {
      await PluginRegistryService.I.deletePlugin(widget.pluginUuid);
    } catch (e) {
      if (!mounted) {
        return;
      }
      showErrorToast('删除失败: $e');
      return;
    }
    if (!mounted) {
      return;
    }
    showSuccessToast('插件已删除');
    Navigator.of(context).pop();
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
          await _commitField(field, picked.toList());
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
                if (fnPath == 'clearPluginSession') {
                  this.context.router.push(LoginRoute(from: widget.from));
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8, top: 16),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),
        ...children,
      ],
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
