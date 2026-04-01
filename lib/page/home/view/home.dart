import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zephyr/cubit/plugin_registry_cubit.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/page/comic_list/models/comic_list_scene.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/page/search_result/bloc/search_bloc.dart';
import 'package:zephyr/plugin/plugin_constants.dart';
import 'package:zephyr/plugin/plugin_registry_service.dart';
import 'package:zephyr/util/json/json_value.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/widgets/toast.dart';

import 'home_scheme_renderer.dart';
import 'plugin_settings_page.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeSchemeRenderer _renderer = const HomeSchemeRenderer();
  final Map<String, Future<Map<String, dynamic>>> _pluginInfoFutures = {};
  final Map<String, String> _pluginInfoCacheKeyByUuid = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("插件管理"),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: search),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'downloads') {
                context.pushRoute(DownloadTaskRoute());
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'downloads',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text("下载任务"),
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
        child: _buildPluginHome(),
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
    return kBikaPluginUuid;
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

    if (visiblePlugins.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: const [
          SizedBox(height: 120),
          Center(child: Text('暂无可用插件')),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        for (var i = 0; i < visiblePlugins.length; i++) ...[
          _buildPluginCardAsync(visiblePlugins[i].uuid, visiblePlugins[i]),
          if (i != visiblePlugins.length - 1) const SizedBox(height: 12),
        ],
      ],
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
          return Material(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Material(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: Text('插件信息加载失败: ${snapshot.error}')),
                  const SizedBox(width: 12),
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
    return Material(
      color: isEnabled
          ? colorScheme.surfaceContainerLow
          : colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: ClipRRect(
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
                                child: const Center(
                                  child: Icon(
                                    Icons.extension_outlined,
                                    size: 22,
                                  ),
                                ),
                              );
                            },
                          )
                        : ColoredBox(
                            color: colorScheme.surfaceContainerHighest,
                            child: const Center(
                              child: Icon(Icons.extension_outlined, size: 22),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
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
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          IconButton(
                            tooltip: isEnabled ? '关闭插件' : '开启插件',
                            iconSize: 16,
                            splashRadius: 14,
                            visualDensity: VisualDensity.compact,
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onPressed: () =>
                                _togglePluginEnabled(pluginUuid, !isEnabled),
                            icon: Icon(
                              isEnabled
                                  ? Icons.toggle_on_outlined
                                  : Icons.toggle_off_outlined,
                            ),
                          ),
                          IconButton(
                            tooltip: '设置',
                            iconSize: 18,
                            splashRadius: 16,
                            visualDensity: VisualDensity.compact,
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (context) => PluginSettingsPage(
                                    from: from,
                                    pluginUuid: pluginUuid,
                                    pluginRuntimeName: pluginUuid,
                                    pluginDisplayName: title,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.settings_outlined),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
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
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: enabled
                          ? colorScheme.surfaceContainerHighest
                          : colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      text,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: enabled
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
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
        showErrorToast('插件调试加载失败，已回退本地: $e');
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
      final sourceId = sanitizePluginId(source);
      final keyword = payload['keyword']?.toString() ?? '';
      final url = payload['url']?.toString() ?? '';
      final categories = asJsonList(payload['categories'])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList();

      final extern = <String, dynamic>{
        if (categories.isNotEmpty) 'categories': categories,
        if (url.isNotEmpty) 'url': url,
      };

      final searchStates = SearchStates.initial().copyWith(
        from: source,
        searchKeyword: keyword,
        pluginExtern: {...extern, '_pluginId': sourceId},
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

      if (Platform.isLinux) {
        await _launchBrowser(url);
      } else {
        context.pushRoute(WebViewRoute(info: [title, url]));
      }
      return;
    }

    if (type == 'openPluginFunction') {
      final source = _sourceFromString(payload['source']?.toString());
      await _openPluginFunction(source, payload);
      return;
    }

    if (type == 'openCloudFavorite') {
      final parsed = _sourceFromString(payload['source']?.toString());
      final source = parsed.isEmpty ? _currentFrom : parsed;
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
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => _PluginFunctionPage(
            from: from,
            functionId: functionId,
            title: title,
            onAction: _handleAction,
          ),
        ),
      );
      return;
    }

    Map<String, dynamic> response;
    try {
      response = await callUnifiedComicPlugin(
        from: from,
        fnPath: 'getFunctionPage',
        core: {'id': functionId},
        extern: const <String, dynamic>{},
      );
    } catch (_) {
      response = await callUnifiedComicPlugin(
        from: from,
        fnPath: 'get_function_page',
        core: {'id': functionId},
        extern: const <String, dynamic>{},
      );
    }

    if (!mounted) return;

    final envelope = UnifiedPluginEnvelope.fromMap(response);
    final contentData = asMap(envelope.data);
    final dialogHeight = _estimateFunctionDialogHeight(
      context,
      envelope.scheme,
      contentData,
    );
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
            height: dialogHeight,
            child: Builder(
              builder: (dialogContext) => _renderer.buildPage(
                dialogContext,
                from: from,
                scheme: envelope.scheme,
                data: contentData,
                onReachBottom: () async {},
                onAction: _handleAction,
                isLoadingMore: false,
                showLoadMoreRetry: false,
                onRetryLoadMore: () {},
              ),
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

  double _estimateFunctionDialogHeight(
    BuildContext context,
    Map<String, dynamic> scheme,
    Map<String, dynamic> data,
  ) {
    final body = asJsonMap(scheme['body']);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxHeight = screenHeight * 0.68;

    String chipKey = '';
    if (body['type']?.toString() == 'chip-list') {
      chipKey = body['key']?.toString() ?? '';
    } else if (body['type']?.toString() == 'list') {
      final children = asJsonList(body['children']).map((e) => asJsonMap(e));
      for (final child in children) {
        if (child['type']?.toString() == 'chip-list') {
          chipKey = child['key']?.toString() ?? '';
          if (chipKey.isNotEmpty) break;
        }
      }
    }

    if (chipKey.isNotEmpty) {
      final count = asJsonList(data[chipKey]).length;
      final rows = ((count + 3) ~/ 4).clamp(1, 8);
      final estimated = 108 + rows * 44;
      return estimated.toDouble().clamp(170.0, maxHeight);
    }

    return 320.0.clamp(220.0, maxHeight);
  }

  Future<void> _launchBrowser(String url) async {
    try {
      if (!await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      )) {
        throw Exception('launchUrl return false');
      }
    } catch (_) {
      if (Platform.isLinux) {
        try {
          await Process.start('cmd.exe', [
            '/c',
            'start',
            '',
            url,
          ], mode: ProcessStartMode.detached);
        } catch (e) {
          logger.e('WSL fallback failed: $e');
        }
      }
    }
  }

  String _sourceFromString(String? source) {
    final resolved = sanitizePluginId(source ?? '');
    return resolved.isEmpty ? _currentFrom : resolved;
  }

  void search() {
    context.pushRoute(
      SearchRoute(
        searchState: SearchStates.initial().copyWith(from: _currentFrom),
        aggregateMode: true,
      ),
    );
  }
}

class _PluginFunctionPage extends StatefulWidget {
  const _PluginFunctionPage({
    required this.from,
    required this.functionId,
    required this.title,
    required this.onAction,
  });

  final String from;
  final String functionId;
  final String title;
  final Future<void> Function(Map<String, dynamic> action) onAction;

  @override
  State<_PluginFunctionPage> createState() => _PluginFunctionPageState();
}

class _PluginFunctionPageState extends State<_PluginFunctionPage> {
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
      final envelope = UnifiedPluginEnvelope.fromMap(response);
      if (!mounted) return;
      setState(() {
        _scheme = envelope.scheme;
        _data = asMap(envelope.data);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _load, child: const Text('重试')),
                ],
              ),
            )
          : _renderer.buildPage(
              context,
              from: widget.from,
              scheme: _scheme,
              data: _data,
              onReachBottom: () async {},
              onAction: _onAction,
              isLoadingMore: false,
              showLoadMoreRetry: false,
              onRetryLoadMore: () {},
            ),
    );
  }

  Future<void> _onAction(Map<String, dynamic> action) async {
    final type = action['type']?.toString().trim() ?? '';
    if (type.isEmpty) {
      await widget.onAction(action);
      return;
    }

    if (type == 'openPluginFunction' ||
        type == 'openCloudFavorite' ||
        type == 'openSearch' ||
        type == 'openComicList') {
      final payload = Map<String, dynamic>.from(asJsonMap(action['payload']));
      payload['source'] = widget.from;
      if (type == 'openComicList') {
        final scene = Map<String, dynamic>.from(asJsonMap(payload['scene']));
        scene['source'] = widget.from;
        payload['scene'] = scene;
      }
      final next = Map<String, dynamic>.from(action)..['payload'] = payload;
      await widget.onAction(next);
      return;
    }

    await widget.onAction(action);
  }
}
