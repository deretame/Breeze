import 'package:flutter/material.dart';
import 'package:zephyr/page/plugin_store/models/cloud_plugin_item.dart';
import 'package:zephyr/plugin/plugin_registry_service.dart';

class CloudPluginCard extends StatelessWidget {
  const CloudPluginCard({
    super.key,
    required this.item,
    required this.installing,
    required this.onOpenHome,
    required this.onInstall,
  });

  final CloudPluginItem item;
  final bool installing;
  final ValueChanged<String> onOpenHome;
  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final manifest = item.manifest;
    final localState = manifest.uuid.isNotEmpty
        ? PluginRegistryService.I.getByUuid(manifest.uuid)
        : null;
    final isInstalled = localState != null && !localState.isDeleted;
    final isActive =
        localState != null && localState.isEnabled && !localState.isDeleted;
    final localVersion = localState?.version.trim() ?? '';
    final creatorText = manifest.creatorName.trim();
    final title = manifest.name.trim().isNotEmpty
        ? manifest.name.trim()
        : item.repo;

    return Container(
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
              _CloudPluginIcon(iconUrl: manifest.iconUrl),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        if (isInstalled) ...[
                          const SizedBox(width: 8),
                          const _InstalledChip(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isActive && localVersion.isNotEmpty
                          ? '云端 ${manifest.version}  ·  本地 $localVersion'
                          : '云端 ${manifest.version}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (manifest.describe.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        manifest.describe.trim(),
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
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _CloudMetaTag(label: '仓库', value: item.repo),
              if (creatorText.isNotEmpty)
                _CloudMetaTag(label: '作者', value: creatorText),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (manifest.home.trim().isNotEmpty) ...[
                OutlinedButton.icon(
                  onPressed: installing
                      ? null
                      : () => onOpenHome(manifest.home.trim()),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('主页'),
                ),
                const SizedBox(width: 8),
              ],
              OutlinedButton.icon(
                onPressed: installing ? null : onInstall,
                icon: const Icon(Icons.download_outlined, size: 16),
                label: Text(isInstalled ? '下载更新' : '下载'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InstalledChip extends StatelessWidget {
  const _InstalledChip();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 12,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 3),
          Text(
            '已安装',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CloudPluginIcon extends StatelessWidget {
  const _CloudPluginIcon({required this.iconUrl});

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

class _CloudMetaTag extends StatelessWidget {
  const _CloudMetaTag({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
