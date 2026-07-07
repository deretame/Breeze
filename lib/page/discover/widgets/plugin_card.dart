import 'package:flutter/material.dart';
import 'package:zephyr/plugin/plugin_registry_service.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/json/json_value.dart';
import 'package:zephyr/util/text/chinese_convert.dart';

import '../cubit/discover_cubit.dart';

class PluginCard extends StatelessWidget {
  const PluginCard({
    super.key,
    required this.pluginUuid,
    required this.pluginState,
    required this.infoState,
    required this.isToggling,
    required this.onSearch,
    required this.onSettings,
    required this.onToggleEnabled,
    required this.onRetry,
    required this.onAction,
  });

  final String pluginUuid;
  final PluginRuntimeState pluginState;
  final DiscoverPluginInfoState infoState;
  final bool isToggling;
  final VoidCallback onSearch;
  final void Function(String title) onSettings;
  final ValueChanged<bool> onToggleEnabled;
  final VoidCallback onRetry;
  final Future<void> Function(Map<String, dynamic> action) onAction;

  @override
  Widget build(BuildContext context) {
    if (infoState.loading) {
      return _buildLoading(context);
    }
    if (infoState.error != null || infoState.data == null) {
      return _buildError(context, infoState.error);
    }
    return _buildLoaded(context, infoState.data!);
  }

  Widget _buildLoading(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          const SizedBox(width: 16),
          const Text('加载中...'),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String? error) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '插件信息加载失败: $error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, Map<String, dynamic> info) {
    final isEnabled = pluginState.isEnabled;
    final colorScheme = Theme.of(context).colorScheme;

    final rawFunctions = asJsonList(
      info['functions'] ?? info['function'] ?? const <dynamic>[],
    ).map((item) => asJsonMap(item)).toList();
    final creator = asJsonMap(info['creator']);
    final pluginName = info['name']?.toString().trim() ?? '';
    final creatorName = creator['name']?.toString().trim() ?? '';
    final title = pluginName.isNotEmpty
        ? pluginName
        : (creatorName.isNotEmpty ? creatorName : '插件能力');
    final iconUrl =
        info['iconUrl']?.toString().trim() ??
        creator['coverUrl']?.toString().trim() ??
        '';
    final pluginDescribe = info['describe']?.toString().trim() ?? '';
    final creatorDescribe = creator['describe']?.toString().trim() ?? '';
    final description = pluginDescribe.isNotEmpty
        ? pluginDescribe
        : creatorDescribe;

    final iconWidget = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: iconUrl.isNotEmpty
          ? Image.network(
              iconUrl,
              key: ValueKey(iconUrl),
              fit: BoxFit.cover,
              headers: const {'User-Agent': 'Breeze/1.0'},
              errorBuilder: (context, error, stackTrace) {
                return ColoredBox(
                  color: colorScheme.surfaceContainerHighest,
                  child: const Center(child: Icon(Icons.extension_outlined)),
                );
              },
            )
          : ColoredBox(
              color: colorScheme.surfaceContainerHighest,
              child: const Center(child: Icon(Icons.extension_outlined)),
            ),
    );

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            isThreeLine: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: SizedBox(width: 48, height: 48, child: iconWidget),
            title: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            subtitle: Text(
              isEnabled ? description : '已关闭',
              softWrap: true,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: '搜索',
                  icon: const Icon(Icons.search, size: 20),
                  onPressed: isEnabled ? onSearch : null,
                ),
                IconButton(
                  tooltip: '设置',
                  icon: const Icon(Icons.settings_outlined, size: 20),
                  onPressed: () => onSettings(title),
                ),
                isToggling
                    ? const SizedBox(
                        width: 48,
                        height: 24,
                        child: Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : Switch(
                        value: isEnabled,
                        onChanged: onToggleEnabled,
                      ),
              ],
            ),
          ),
          if (rawFunctions.isNotEmpty && isEnabled)
            Padding(
              padding: const EdgeInsets.only(left: 84, right: 20, bottom: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: rawFunctions.map((function) {
                  final id = function['id']?.toString().trim() ?? '';
                  final text = function['title']?.toString().trim() ?? '未命名';
                  var action = asJsonMap(function['action']);
                  if (action.isEmpty && id.isNotEmpty) {
                    action = {
                      'type': 'openPluginFunction',
                      'payload': {
                        'id': id,
                        'title': text,
                        'presentation': 'page',
                      },
                    };
                  }
                  final enabled = action.isNotEmpty;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: enabled ? () => onAction(action) : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.6,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        text.let(convertChineseForDisplay),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: enabled
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
