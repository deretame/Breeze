import 'package:material_ui/material_ui.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/page/plugin_store/models/cloud_plugin_item.dart';
import 'package:zephyr/plugin/plugin_registry_service.dart';
import 'package:zephyr/widgets/plugin_icon.dart';

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
                          ? '${t.plugin.cloudVersion(version: manifest.version)}  ·  ${t.plugin.localVersion(version: localVersion)}'
                          : t.plugin.cloudVersion(version: manifest.version),
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
              _CloudMetaTag(label: t.plugin.repo, value: item.repo),
              if (creatorText.isNotEmpty)
                _CloudMetaTag(label: t.plugin.author, value: creatorText),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (manifest.home.trim().isNotEmpty)
                _CloudTextAction(
                  label: t.plugin.homepage,
                  onTap: installing
                      ? null
                      : () => onOpenHome(manifest.home.trim()),
                ),
              if (item.githubRepositoryUrl.isNotEmpty)
                _CloudTextAction(
                  label: t.plugin.githubRepo,
                  onTap: installing
                      ? null
                      : () => onOpenHome(item.githubRepositoryUrl),
                ),
              _CloudTextAction(
                label: isInstalled
                    ? t.plugin.downloadUpdate
                    : t.plugin.download,
                onTap: installing ? null : onInstall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 无图标的纯文本小按钮：保留边框、无阴影，对齐 `_ClickableChip` 手感。
/// `onTap` 为空时置灰且不响应，与禁用态按钮语义一致。
class _CloudTextAction extends StatefulWidget {
  const _CloudTextAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  State<_CloudTextAction> createState() => _CloudTextActionState();
}

class _CloudTextActionState extends State<_CloudTextAction> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;
    final enabled = widget.onTap != null;
    final foreground = enabled
        ? primary
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.5);
    final activeHover = enabled && _hovering;

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: activeHover
                ? primary.withValues(alpha: 0.08)
                : colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: enabled
                  ? primary.withValues(alpha: activeHover ? 0.9 : 0.55)
                  : colorScheme.outlineVariant,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            widget.label,
            style: TextStyle(fontSize: 12, color: foreground),
          ),
        ),
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
            t.plugin.installed,
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
        child: PluginIcon(
          url: iconUrl,
          placeholder: Icon(
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
