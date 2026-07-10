import 'package:auto_route/auto_route.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/page/plugin_store/cubit/plugin_store_cubit.dart';
import 'package:zephyr/page/plugin_store/widgets/cloud_plugin_card.dart';
import 'package:zephyr/page/plugin_store/widgets/plugin_store_status_banner.dart';
import 'package:zephyr/widgets/toast.dart';

@RoutePage()
class PluginStorePage extends StatelessWidget {
  const PluginStorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PluginStoreCubit()..loadCloudPlugins(),
      child: const _PluginStorePageContent(),
    );
  }
}

class _PluginStorePageContent extends StatefulWidget {
  const _PluginStorePageContent();

  @override
  State<_PluginStorePageContent> createState() =>
      _PluginStorePageContentState();
}

class _PluginStorePageContentState extends State<_PluginStorePageContent> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BlocBuilder<PluginStoreCubit, PluginStoreState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: Text(t.plugin.store)),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSearchCard(colorScheme, state.installing),
                  const SizedBox(height: 14),
                  _buildInstallButtons(state.installing),
                  const SizedBox(height: 16),
                  _buildCloudPluginsSection(state),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchCard(ColorScheme colorScheme, bool installing) {
    return TextField(
      controller: _searchController,
      enabled: !installing,
      decoration: InputDecoration(
        hintText: t.plugin.searchHint,
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        isDense: true,
      ),
    );
  }

  Widget _buildInstallButtons(bool installing) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        OutlinedButton.icon(
          onPressed: installing ? null : _installFromLocal,
          icon: const Icon(Icons.folder_open_outlined, size: 18),
          label: Text(t.plugin.localInstall),
        ),
        OutlinedButton.icon(
          onPressed: installing ? null : _installFromNetwork,
          icon: const Icon(Icons.language_outlined, size: 18),
          label: Text(t.plugin.networkInstall),
        ),
      ],
    );
  }

  Widget _buildCloudPluginsSection(PluginStoreState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final query = _searchController.text.trim().toLowerCase();
    final displayPlugins = state.cloudPlugins.where((item) {
      if (query.isEmpty) return true;
      final name = item.manifest.name.toLowerCase();
      final creator = item.manifest.creatorName.toLowerCase();
      final repo = item.repo.toLowerCase();
      return name.contains(query) ||
          creator.contains(query) ||
          repo.contains(query);
    }).toList();

    final hasData = state.cloudPlugins.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.installing) ...[
          PluginStoreStatusBanner(message: state.installMessage),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            const Icon(Icons.cloud_outlined, size: 18),
            const SizedBox(width: 8),
            Text(
              t.plugin.cloudComponents,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            IconButton(
              tooltip: t.common.refresh,
              visualDensity: VisualDensity.compact,
              onPressed: state.cloudLoading
                  ? null
                  : context.read<PluginStoreCubit>().loadCloudPlugins,
              icon: state.cloudLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (state.cloudLoading && !hasData)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (state.cloudError.trim().isNotEmpty && !hasData)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.cloudError,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: state.cloudLoading
                      ? null
                      : context.read<PluginStoreCubit>().loadCloudPlugins,
                  icon: const Icon(Icons.refresh),
                  label: Text(t.common.retry),
                ),
              ],
            ),
          )
        else if (!hasData)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              t.plugin.noCloudPlugins,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            ),
          )
        else if (displayPlugins.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              t.plugin.noMatchingPlugins,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            ),
          )
        else
          Column(
            children: displayPlugins
                .map(
                  (item) => CloudPluginCard(
                    item: item,
                    installing: state.installing,
                    onOpenHome: _openExternalUrl,
                    onInstall: () =>
                        context.read<PluginStoreCubit>().installFromCloud(item),
                  ),
                )
                .toList(),
          ),
        if (state.cloudError.trim().isNotEmpty && hasData) ...[
          const SizedBox(height: 8),
          Text(
            state.cloudError,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
          ),
        ],
      ],
    );
  }

  Future<void> _openExternalUrl(String rawUrl) async {
    final resolved = rawUrl.trim();
    if (resolved.isEmpty) {
      return;
    }
    final uri = Uri.tryParse(resolved);
    if (uri == null) {
      showErrorToast(t.plugin.invalidLink(url: resolved));
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      showErrorToast(t.plugin.cannotOpenLink(url: resolved));
    }
  }

  Future<void> _installFromLocal() async {
    try {
      final file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'plugin script',
            extensions: ['js', 'cjs', 'br'],
            uniformTypeIdentifiers: ['public.javascript'],
          ),
        ],
      );
      if (file == null) {
        return;
      }
      final bytes = await file.readAsBytes();
      if (!mounted) {
        return;
      }
      await context.read<PluginStoreCubit>().installFromLocalBytes(
        bytes,
        fileName: file.name,
      );
    } catch (e) {
      showErrorToast(t.plugin.readLocalPluginFailed(error: e.toString()));
    }
  }

  Future<void> _installFromNetwork() async {
    final url = await _showInputDialog(
      context,
      title: t.plugin.addFromNetwork,
      hintText: t.plugin.networkInstallHint,
    );
    if (url == null) {
      return;
    }

    final resolvedUrl = url.trim();
    if (resolvedUrl.isEmpty) {
      showErrorToast(t.plugin.urlCannotBeEmpty);
      return;
    }

    if (!mounted) {
      return;
    }
    await context.read<PluginStoreCubit>().installFromNetworkUrl(resolvedUrl);
  }

  Future<String?> _showInputDialog(
    BuildContext context, {
    required String title,
    required String hintText,
  }) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: hintText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(t.plugin.startInstall),
          ),
        ],
      ),
    );
  }
}
