import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/cubit/plugin_registry_cubit.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/page/comic_list/models/comic_list_scene.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/page/search_result/bloc/search_bloc.dart';
import 'package:zephyr/plugin/plugin_registry_service.dart';
import 'package:zephyr/util/json/json_value.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/widgets/toast.dart';

import 'home_scheme_renderer.dart';
import 'package:zephyr/util/error_filter.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Map<String, Future<Map<String, dynamic>>> _pluginInfoFutures = {};
  final Map<String, String> _pluginInfoCacheKeyByUuid = {};

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text("发现"),
        actions: [
          IconButton(
            tooltip: '搜索',
            icon: const Icon(Icons.search),
            onPressed: search,
          ),
          if (isDesktop) ...[
            IconButton(
              tooltip: '下载任务',
              icon: const Icon(Icons.download_outlined),
              onPressed: () => context.pushRoute(DownloadTaskRoute()),
            ),
            IconButton(
              tooltip: '全局设置',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.pushRoute(GlobalSettingRoute()),
            ),
            const SizedBox(width: 8),
          ] else
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                if (value == 'downloads') {
                  context.pushRoute(DownloadTaskRoute());
                }
                if (value == 'settings') {
                  context.pushRoute(GlobalSettingRoute());
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'downloads',
                  child: Row(
                    children: [
                      Icon(Icons.download_outlined, size: 20),
                      SizedBox(width: 12),
                      Text("下载任务"),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings_outlined, size: 20),
                      SizedBox(width: 12),
                      Text("全局设置"),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      resizeToAvoidBottomInset: false,
      body: RefreshIndicator(
        onRefresh: () => _reloadCurrent(),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: _buildPluginHome(),
          ),
        ),
      ),
    );
  }

  String get _currentFrom {
    final pluginStates = context.read<PluginRegistryCubit>().state;
    final active =
        pluginStates.values
            .where((state) => state.isEnabled && !state.isDeleted)
            .toList()
          ..sort((a, b) => a.insertedAt.compareTo(b.insertedAt));
    if (active.isNotEmpty) {
      return active.first.uuid;
    }
    final visible =
        pluginStates.values.where((state) => !state.isDeleted).toList()
          ..sort((a, b) => a.insertedAt.compareTo(b.insertedAt));
    if (visible.isNotEmpty) {
      return visible.first.uuid;
    }
    return '';
  }

  Future<void> _reloadCurrent() async {
    setState(() {
      _pluginInfoFutures.clear();
    });
  }

  Widget _buildPluginHome() {
    final pluginStates = context.watch<PluginRegistryCubit>().state;
    _reconcilePluginInfoCache(pluginStates);
    final visiblePlugins =
        pluginStates.values.where((state) => !state.isDeleted).toList()
          ..sort((a, b) => a.insertedAt.compareTo(b.insertedAt));

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        const SizedBox(height: 16),
        _buildPluginStoreButton(),
        const SizedBox(height: 8),
        _buildSectionHeader('扩展插件'),
        if (visiblePlugins.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text('暂无可用插件', style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          for (var i = 0; i < visiblePlugins.length; i++) ...[
            _buildPluginCardAsync(visiblePlugins[i].uuid, visiblePlugins[i]),
            if (i != visiblePlugins.length - 1)
              const Divider(height: 1, indent: 80, endIndent: 16),
          ],
      ],
    );
  }

  Widget _buildPluginStoreButton() {
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
            const Expanded(
              child: Text(
                '插件商店',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
            Text(
              '浏览和管理',
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

  Widget _buildSectionHeader(String title) {
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

  Widget _buildPluginCardAsync(
    String pluginUuid,
    PluginRuntimeState? pluginState,
  ) {
    final from = pluginUuid;
    final isEnabled = pluginState?.isEnabled ?? true;
    return FutureBuilder<Map<String, dynamic>>(
      future: _pluginInfoFutures.putIfAbsent(
        pluginUuid,
        () => _loadPluginInfo(pluginUuid),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
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
        if (snapshot.hasError || !snapshot.hasData) {
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
                    '插件信息加载失败: ${snapshot.error}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _pluginInfoFutures.remove(pluginUuid);
                    });
                  },
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }

        final info = snapshot.data!;
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

        return _buildPluginCard(
          context,
          from: from,
          pluginUuid: pluginUuid,
          pluginState: pluginState,
          title: title,
          description: isEnabled ? description : '已关闭（功能入口已隐藏）',
          iconUrl: iconUrl,
          functions: isEnabled ? rawFunctions : const <Map<String, dynamic>>[],
        );
      },
    );
  }

  Widget _buildPluginCard(
    BuildContext context, {
    required String from,
    required String pluginUuid,
    required PluginRuntimeState? pluginState,
    required String title,
    required String description,
    required String iconUrl,
    required List<Map<String, dynamic>> functions,
  }) {
    final isEnabled = pluginState?.isEnabled ?? true;
    final colorScheme = Theme.of(context).colorScheme;

    Widget iconWidget = ClipRRect(
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
              description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
                  onPressed: isEnabled ? () => _openPluginSearch(from) : null,
                ),
                IconButton(
                  tooltip: '设置',
                  icon: const Icon(Icons.settings_outlined, size: 20),
                  onPressed: () {
                    context.pushRoute(
                      PluginSettingsRoute(
                        from: from,
                        pluginUuid: pluginUuid,
                        pluginRuntimeName: pluginUuid,
                        pluginDisplayName: title,
                      ),
                    );
                  },
                ),
                Switch(
                  value: isEnabled,
                  onChanged: (val) => _togglePluginEnabled(pluginUuid, val),
                ),
              ],
            ),
          ),
          if (functions.isNotEmpty && isEnabled)
            Padding(
              padding: const EdgeInsets.only(left: 84, right: 20, bottom: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: functions.map((function) {
                  final id = function['id']?.toString().trim() ?? '';
                  final text = function['title']?.toString().trim() ?? '未命名';
                  var action = asJsonMap(function['action']);
                  if (action.isEmpty) {
                    if (id.isNotEmpty) {
                      action = {
                        'type': 'openPluginFunction',
                        'payload': {
                          'id': id,
                          'title': text,
                          'presentation': 'page',
                        },
                      };
                    }
                  }
                  final enabled = action.isNotEmpty;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: enabled
                        ? () => _handleAction(_attachActionSource(action, from))
                        : null,
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
                        text,
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

  Future<void> _togglePluginEnabled(String uuid, bool enabled) async {
    await PluginRegistryService.I.setEnabled(uuid, enabled);
  }

  void _reconcilePluginInfoCache(Map<String, PluginRuntimeState> pluginStates) {
    for (final entry in pluginStates.entries) {
      final plugin = entry.key;
      final state = entry.value;
      final cacheKey = _pluginInfoCacheKey(state);
      final previous = _pluginInfoCacheKeyByUuid[plugin];
      if (previous != null && previous != cacheKey) {
        _pluginInfoFutures.remove(plugin);
      }
      _pluginInfoCacheKeyByUuid[plugin] = cacheKey;

      if (state.isDeleted) {
        _pluginInfoFutures.remove(plugin);
      }
    }
  }

  String _pluginInfoCacheKey(PluginRuntimeState? state) {
    if (state == null) {
      return 'none';
    }
    return '${state.isDeleted}|${state.debug}|${state.debugUrl ?? ''}';
  }

  Future<Map<String, dynamic>> _loadPluginInfo(String uuid) async {
    final cached = PluginRegistryService.I.getCachedPluginInfo(uuid);
    if (cached != null) {
      return cached;
    }
    final runtimeName = uuid;
    try {
      final response = await PluginRegistryService.I.fetchPluginInfo(
        uuid: uuid,
        runtimeName: runtimeName,
      );
      return response;
    } catch (e) {
      final state = PluginRegistryService.I.getByUuid(uuid);
      if (state?.debug == true) {
        showErrorToast('插件调试加载失败，已回退数据库: $e');
      }
      rethrow;
    }
  }

  Future<void> _handleAction(Map<String, dynamic> action) async {
    final type = action['type']?.toString() ?? '';
    final payload = asJsonMap(action['payload']);

    if (type == 'none' || type.isEmpty) {
      return;
    }

    if (type == 'openSearch') {
      final source = _sourceFromString(payload['source']?.toString());
      final extern = _normalizeOpenSearchExtern(payload);
      final keywordFromPayload = payload['keyword']?.toString() ?? '';
      final keywordFromExtern = extern['keyword']?.toString() ?? '';
      final keyword = keywordFromPayload.isNotEmpty
          ? keywordFromPayload
          : keywordFromExtern;

      final searchStates = SearchStates.initial().copyWith(
        from: source,
        searchKeyword: keyword,
        pluginExtern: extern,
      );

      context.pushRoute(
        SearchResultRoute(
          searchEvent: SearchEvent().copyWith(searchStates: searchStates),
        ),
      );
      return;
    }

    if (type == 'openWeb') {
      final title = payload['title']?.toString() ?? '';
      final url = payload['url']?.toString() ?? '';
      if (url.isEmpty) {
        return;
      }

      context.pushRoute(WebViewRoute(info: [title, url]));
    }

    if (type == 'openPluginFunction') {
      final source = _sourceFromString(payload['source']?.toString());
      if (source.isEmpty) {
        showErrorToast('缺少插件来源，无法打开功能页');
        return;
      }
      await _openPluginFunction(source, payload);
      return;
    }

    if (type == 'openCloudFavorite') {
      final parsed = _sourceFromString(payload['source']?.toString());
      final source = parsed.isEmpty ? _currentFrom : parsed;
      if (source.isEmpty) {
        showErrorToast('缺少插件来源，无法打开云端收藏');
        return;
      }
      final title = payload['title']?.toString();
      context.pushRoute(
        ComicListRoute(
          title: title ?? '云端收藏',
          sceneSource: source,
          sceneBundleFnPath: 'getCloudFavoriteSceneBundle',
          sceneBundleFnPathFallback: 'get_cloud_favorite_scene_bundle',
        ),
      );
      return;
    }

    if (type == 'openComicList') {
      final scene = ComicListScene.fromMap(asJsonMap(payload['scene']));
      context.pushRoute(ComicListRoute(scene: scene, title: scene.title));
      return;
    }
  }

  Map<String, dynamic> _normalizeOpenSearchExtern(
    Map<String, dynamic> payload,
  ) {
    final extern = Map<String, dynamic>.from(asJsonMap(payload['extern']));
    for (final entry in payload.entries) {
      final key = entry.key.toString();
      if (key == 'source' || key == 'extern' || extern.containsKey(key)) {
        continue;
      }
      final value = entry.value;
      if (value == null) {
        continue;
      }
      if (value is String && value.trim().isEmpty) {
        continue;
      }
      extern[key] = value;
    }

    return extern;
  }

  Future<void> _openPluginFunction(
    String from,
    Map<String, dynamic> payload,
  ) async {
    final functionId = payload['id']?.toString().trim() ?? '';
    if (functionId.isEmpty) {
      return;
    }
    final title = payload['title']?.toString().trim() ?? '功能';
    final presentation = payload['presentation']?.toString().trim() ?? 'page';

    if (presentation != 'dialog') {
      if (!mounted) return;
      await context.pushRoute(
        PluginFunctionRoute(
          from: from,
          functionId: functionId,
          title: title,
          onAction: _handleAction,
        ),
      );
      return;
    }

    if (!mounted) return;
    final mediaSize = MediaQuery.sizeOf(context);
    final dialogWidth = (mediaSize.width * 0.9).clamp(280.0, 560.0).toDouble();

    if (presentation == 'dialog') {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          contentPadding: const EdgeInsets.only(top: 8),
          content: SizedBox(
            width: dialogWidth,
            height: 320,
            child: _PluginFunctionDialogContent(
              from: from,
              functionId: functionId,
              onAction: _handleAction,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        ),
      );
      return;
    }
  }

  Map<String, dynamic> _attachActionSource(
    Map<String, dynamic> action,
    String from,
  ) {
    final type = action['type']?.toString().trim() ?? '';
    if (type != 'openPluginFunction' &&
        type != 'openCloudFavorite' &&
        type != 'openSearch' &&
        type != 'openComicList') {
      return action;
    }

    final payload = Map<String, dynamic>.from(asJsonMap(action['payload']));
    payload['source'] = from;

    if (type == 'openComicList') {
      final scene = Map<String, dynamic>.from(asJsonMap(payload['scene']));
      scene['source'] = from;
      payload['scene'] = scene;
    }

    return Map<String, dynamic>.from(action)..['payload'] = payload;
  }

  String _sourceFromString(String? source) {
    final resolved = (source ?? '').trim();
    return resolved;
  }

  void _openPluginSearch(String from) {
    final source = _sourceFromString(from);
    if (source.isEmpty) {
      showErrorToast('缺少插件来源，无法搜索');
      return;
    }
    context.pushRoute(
      SearchRoute(
        searchState: SearchStates.initial().copyWith(from: source),
        aggregateMode: false,
      ),
    );
  }

  void search() {
    final source = _currentFrom;
    if (source.isEmpty) {
      showErrorToast('暂无可用插件，无法搜索');
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

class _PluginFunctionDialogContent extends StatefulWidget {
  const _PluginFunctionDialogContent({
    required this.from,
    required this.functionId,
    required this.onAction,
  });

  final String from;
  final String functionId;
  final Future<void> Function(Map<String, dynamic> action) onAction;

  @override
  State<_PluginFunctionDialogContent> createState() =>
      _PluginFunctionDialogContentState();
}

class _PluginFunctionDialogContentState
    extends State<_PluginFunctionDialogContent> {
  final HomeSchemeRenderer _renderer = const HomeSchemeRenderer();
  bool _loading = true;
  String _error = '';
  Map<String, dynamic> _scheme = const <String, dynamic>{};
  Map<String, dynamic> _data = const <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      Map<String, dynamic> response;
      try {
        response = await callUnifiedComicPlugin(
          from: widget.from,
          fnPath: 'getFunctionPage',
          core: {'id': widget.functionId},
          extern: const <String, dynamic>{},
        );
      } catch (_) {
        response = await callUnifiedComicPlugin(
          from: widget.from,
          fnPath: 'get_function_page',
          core: {'id': widget.functionId},
          extern: const <String, dynamic>{},
        );
      }

      if (!mounted) return;
      final envelope = UnifiedPluginEnvelope.fromMap(response);
      setState(() {
        _scheme = envelope.scheme;
        _data = asMap(envelope.data);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = normalizeSearchErrorMessage(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              TextButton(onPressed: _load, child: const Text('重试')),
            ],
          ),
        ),
      );
    }

    return _renderer.buildPage(
      context,
      from: widget.from,
      scheme: _scheme,
      data: _data,
      onReachBottom: () async {},
      onAction: widget.onAction,
      isLoadingMore: false,
      showLoadMoreRetry: false,
      onRetryLoadMore: () {},
    );
  }
}
