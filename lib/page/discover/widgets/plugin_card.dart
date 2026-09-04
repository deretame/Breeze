import 'package:material_ui/material_ui.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/page/discover/cubit/discover_cubit.dart';
import 'package:zephyr/page/setting/common/setting_ui.dart';
import 'package:zephyr/plugin/plugin_registry_service.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/json/json_value.dart';
import 'package:zephyr/util/text/chinese_convert.dart';
import 'package:zephyr/widgets/plugin_icon.dart';

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
          Text(t.common.loading),
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
              t.discover.pluginInfoLoadFailed(error: error ?? ''),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          TextButton(onPressed: onRetry, child: Text(t.common.retry)),
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
        : (creatorName.isNotEmpty ? creatorName : t.discover.pluginCapability);
    final iconUrl =
        info['iconUrl']?.toString().trim() ??
        creator['coverUrl']?.toString().trim() ??
        '';
    final iconWidget = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: PluginIcon(
        url: iconUrl,
        placeholder: ColoredBox(
          color: colorScheme.surfaceContainerHighest,
          child: const Center(child: Icon(Icons.extension_outlined)),
        ),
      ),
    );

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            isThreeLine: false,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 6,
            ),
            leading: SizedBox(width: 48, height: 48, child: iconWidget),
            title: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            subtitle: isEnabled
                ? null
                : Text(
                    t.discover.disabled,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: t.common.search,
                  icon: const Icon(Icons.search, size: 20),
                  onPressed: isEnabled ? onSearch : null,
                ),
                IconButton(
                  tooltip: t.discover.settings,
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
                        thumbIcon: kSettingSwitchThumbIcon,
                        onChanged: onToggleEnabled,
                      ),
              ],
            ),
          ),
          if (rawFunctions.isNotEmpty && isEnabled)
            Padding(
              padding: const EdgeInsets.only(
                left: 20,
                top: 2,
                right: 20,
                bottom: 12,
              ),
              child: _buildFunctionButtons(context, rawFunctions, colorScheme),
            ),
        ],
      ),
    );
  }

  Widget _buildFunctionButtons(
    BuildContext context,
    List<Map<String, dynamic>> rawFunctions,
    ColorScheme colorScheme,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: rawFunctions.map((function) {
        final id = function['id']?.toString().trim() ?? '';
        final text = function['title']?.toString().trim() ?? t.discover.unnamed;
        var action = asJsonMap(function['action']);
        if (action.isEmpty && id.isNotEmpty) {
          action = {
            'type': 'openPluginFunction',
            'payload': {'id': id, 'title': text, 'presentation': 'page'},
          };
        }
        final enabled = action.isNotEmpty;
        return ActionChip(
          label: Text(text.let(convertChineseForDisplay)),
          onPressed: enabled ? () => onAction(action) : null,
          backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.16),
          disabledColor: colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.35,
          ),
          side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.1)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colorScheme.primary.withValues(alpha: 0.78),
            fontWeight: FontWeight.w500,
          ),
        );
      }).toList(),
    );
  }
}
