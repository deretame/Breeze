import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/plugin_store/cubit/plugin_store_cubit.dart';
import 'package:zephyr/plugin/plugin_registry_service.dart';

/// 「已安装」插件卡片：展示主页 / 更新 / 启用开关。
///
/// 主页与更新 URL 来自插件脚本 getInfo()（fetchPluginInfo），
/// 与网络安装配置同源；updateUrl 为空则不显示更新按钮（走顶部「本地安装」覆盖）。
class InstalledPluginCard extends StatefulWidget {
  const InstalledPluginCard({
    super.key,
    required this.pluginUuid,
    required this.isEnabled,
    required this.version,
    required this.installSource,
    required this.installing,
    required this.onOpenHome,
  });

  final String pluginUuid;
  final bool isEnabled;
  final String version;
  final String installSource;
  final bool installing;
  final ValueChanged<String> onOpenHome;

  @override
  State<InstalledPluginCard> createState() => _InstalledPluginCardState();
}

class _InstalledPluginCardState extends State<InstalledPluginCard> {
  Future<Map<String, dynamic>>? _infoFuture;

  @override
  void initState() {
    super.initState();
    _infoFuture = PluginRegistryService.I.fetchPluginInfo(
      uuid: widget.pluginUuid,
      runtimeName: widget.pluginUuid,
    );
  }

  @override
  void didUpdateWidget(covariant InstalledPluginCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 列表变化时防止 State 复用导致 uuid 与缓存 info 错位
    if (oldWidget.pluginUuid != widget.pluginUuid) {
      _infoFuture = PluginRegistryService.I.fetchPluginInfo(
        uuid: widget.pluginUuid,
        runtimeName: widget.pluginUuid,
      );
    }
  }

  // 仅本地安装插件提示：网络更新会覆盖本地脚本，本地更新请走顶部「本地安装」
  Future<void> _triggerNetworkUpdate(String updateUrl) async {
    if (widget.installSource == 'local') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          content: const Text('使用网络更新，本地更新请使用「本地安装」覆盖'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确定'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    await context.read<PluginStoreCubit>().updateFromUrl(updateUrl);
  }

  Future<void> _confirmUninstall() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text('确认卸载该插件？将同时移除其数据。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('卸载'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await PluginRegistryService.I.deletePlugin(widget.pluginUuid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FutureBuilder<Map<String, dynamic>>(
      future: _infoFuture,
      builder: (context, snapshot) {
        final info = snapshot.data ?? const <String, dynamic>{};
        final name = info['name']?.toString().trim() ?? '';
        final iconUrl = info['iconUrl']?.toString().trim() ?? '';
        final describe = info['describe']?.toString().trim() ?? '';
        final home = info['home']?.toString().trim() ?? '';
        final updateUrl = info['updateUrl']?.toString().trim() ?? '';
        final title = name.isNotEmpty ? name : widget.pluginUuid;

        return Opacity(
          opacity: widget.isEnabled ? 1.0 : 0.6,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: colorScheme.surface.withValues(alpha: 0.85),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InstalledIcon(iconUrl: iconUrl),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '版本 ${widget.version}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          if (describe.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              describe,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (home.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: widget.installing
                            ? null
                            : () => widget.onOpenHome(home),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('主页'),
                      ),
                    if (home.isNotEmpty) const SizedBox(width: 8),
                    if (updateUrl.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: widget.installing
                            ? null
                            : () => _triggerNetworkUpdate(updateUrl),
                        icon: const Icon(Icons.download_outlined, size: 16),
                        label: const Text('更新'),
                      ),
                    if (updateUrl.isNotEmpty) const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: widget.installing ? null : _confirmUninstall,
                      icon: Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: colorScheme.error,
                      ),
                      label: Text(
                        '卸载',
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: widget.isEnabled,
                      onChanged: widget.installing
                          ? null
                          : (val) => PluginRegistryService.I.setEnabled(
                              widget.pluginUuid,
                              val,
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InstalledIcon extends StatelessWidget {
  const _InstalledIcon({required this.iconUrl});

  final String iconUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 40,
        height: 40,
        color: colorScheme.surfaceContainerHigh,
        alignment: Alignment.center,
        child: iconUrl.trim().isEmpty
            ? Icon(
                Icons.extension_outlined,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              )
            : Image.network(
                iconUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(
                  Icons.extension_outlined,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
      ),
    );
  }
}
