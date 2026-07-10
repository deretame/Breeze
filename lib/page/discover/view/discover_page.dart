import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/router/router.gr.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/plugin/plugin_registry_service.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/widgets/toast.dart';

import '../cubit/discover_cubit.dart';
import '../service/discover_router.dart';
import '../widgets/plugin_card.dart';

@RoutePage()
class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DiscoverCubit()..load(),
      child: const _DiscoverView(),
    );
  }
}

class _DiscoverView extends StatelessWidget {
  const _DiscoverView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t.discover.title),
        actions: [
          IconButton(
            tooltip: t.discover.search,
            icon: const Icon(Icons.search),
            onPressed: () => _search(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      resizeToAvoidBottomInset: false,
      body: RefreshIndicator(
        onRefresh: () => context.read<DiscoverCubit>().reload(),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: _buildPluginHome(context),
          ),
        ),
      ),
    );
  }

  Widget _buildPluginHome(BuildContext context) {
    return BlocBuilder<DiscoverCubit, DiscoverState>(
      builder: (context, state) {
        final plugins = state.plugins.values.toList();

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            const SizedBox(height: 16),
            _buildPluginStoreButton(context),
            const SizedBox(height: 8),
            _buildSectionHeader(context, t.discover.pluginManagement),
            if (plugins.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    t.discover.noPlugins,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              for (var i = 0; i < plugins.length; i++) ...[
                _buildPluginCard(context, plugins[i], state),
                if (i != plugins.length - 1)
                  const Divider(height: 1, indent: 80, endIndent: 16),
              ],
          ],
        );
      },
    );
  }

  Widget _buildPluginCard(
    BuildContext context,
    PluginRuntimeState plugin,
    DiscoverState state,
  ) {
    final cubit = context.read<DiscoverCubit>();
    final infoState =
        state.infoStates[plugin.uuid] ??
        const DiscoverPluginInfoState(loading: true);

    return PluginCard(
      pluginUuid: plugin.uuid,
      pluginState: plugin,
      infoState: infoState,
      isToggling: state.togglingUuids.contains(plugin.uuid),
      onSearch: () => _openPluginSearch(context, plugin.uuid),
      onSettings: (title) => _openPluginSettings(context, plugin.uuid, title),
      onToggleEnabled: (enabled) => cubit.toggleEnabled(plugin.uuid, enabled),
      onRetry: () => cubit.retryLoadInfo(plugin.uuid),
      onAction: (action) => DiscoverRouter.route(
        context,
        action: DiscoverRouter.attachSource(action, plugin.uuid),
        currentFrom: cubit.currentFrom,
      ),
    );
  }

  Widget _buildPluginStoreButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => context.pushRoute(const PluginStoreRoute()),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.storefront_outlined,
              size: 22,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                t.discover.pluginStore,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            Text(
              t.discover.browseInstall,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 8, top: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _openPluginSearch(BuildContext context, String from) {
    final source = from.trim();
    if (source.isEmpty) {
      showErrorToast(t.error.missingPluginSource(action: t.discover.search));
      return;
    }
    context.pushRoute(
      SearchRoute(
        searchState: SearchStates.initial().copyWith(from: source),
        aggregateMode: false,
      ),
    );
  }

  void _openPluginSettings(BuildContext context, String uuid, String title) {
    context.pushRoute(
      PluginSettingsRoute(
        from: uuid,
        pluginUuid: uuid,
        pluginRuntimeName: uuid,
        pluginDisplayName: title,
      ),
    );
  }

  void _search(BuildContext context) {
    final cubit = context.read<DiscoverCubit>();
    final source = cubit.currentFrom;
    if (source.isEmpty) {
      showErrorToast(t.discover.noPluginForSearch);
      return;
    }
    context.pushRoute(
      SearchRoute(
        searchState: SearchStates.initial().copyWith(from: source),
        aggregateMode: true,
      ),
    );
  }
}
