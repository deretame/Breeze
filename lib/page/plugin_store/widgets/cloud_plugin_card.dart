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
    final installed = localState != null;
    final localVersion = localState?.version.trim() ?? '';
    final creatorText = manifest.creatorName.trim().isNotEmpty
        ? manifest.creatorName.trim()
        : manifest.creatorDescribe.trim();
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
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      localVersion.isNotEmpty
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
              if (manifest.uuid.trim().isNotEmpty)
                _CloudMetaTag(label: 'UUID', value: manifest.uuid.trim()),
              if (creatorText.isNotEmpty)
                _CloudMetaTag(label: '作者', value: creatorText),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (installed) _InstalledPill(colorScheme: colorScheme),
              if (installed) const SizedBox(width: 8),
              if (manifest.home.trim().isNotEmpty)
                OutlinedButton.icon(
                  onPressed: installing
                      ? null
                      : () => onOpenHome(manifest.home.trim()),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('主页'),
                ),
              if (manifest.home.trim().isNotEmpty) const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: installing ? null : onInstall,
                icon: const Icon(Icons.download_outlined, size: 16),
                label: Text(installed ? '下载更新' : '下载'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InstalledPill extends StatelessWidget {
  const _InstalledPill({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: colorScheme.primaryContainer,
      ),
      child: Text(
        '已安装',
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: colorScheme.onPrimaryContainer),
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
