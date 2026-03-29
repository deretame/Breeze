import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/page/comic_list/models/comic_list_scene.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/page/search_result/bloc/search_bloc.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/json/json_value.dart';
import 'package:zephyr/util/router/router.gr.dart';

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
  final Map<From, Future<Map<String, dynamic>>> _pluginInfoFutures = {};

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

  From get _currentFrom {
    final state = context.read<GlobalSettingCubit>().state;
    return state.disableBika ? From.jm : From.bika;
  }

  Future<void> _reloadCurrent() async {
    setState(() {
      _pluginInfoFutures.remove(From.bika);
      _pluginInfoFutures.remove(From.jm);
    });
  }

  Widget _buildPluginHome() {
    final disableBika = context.watch<GlobalSettingCubit>().state.disableBika;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        if (!disableBika) ...[
          _buildPluginCardAsync(From.bika),
          const SizedBox(height: 12),
        ],
        _buildPluginCardAsync(From.jm),
      ],
    );
  }

  Widget _buildPluginCardAsync(From from) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _pluginInfoFutures.putIfAbsent(from, () => _loadPluginInfo(from)),
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
                        _pluginInfoFutures.remove(from);
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
          title: title,
          description: description,
          iconUrl: iconUrl,
          functions: rawFunctions,
        );
      },
    );
  }

  Widget _buildPluginCard(
    BuildContext context, {
    required From from,
    required String title,
    required String description,
    required String iconUrl,
    required List<Map<String, dynamic>> functions,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerLow,
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
                                    pluginRuntimeName: _pluginRuntimeName(from),
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
                if (from == From.jm && id == 'recommend') {
                  action = {
                    'type': 'openPluginFunction',
                    'payload': {
                      'id': 'recommend',
                      'title': text,
                      'presentation': 'page',
                    },
                  };
                }
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

  String _pluginRuntimeName(From from) {
    return from == From.bika ? 'bikaComic' : 'jmComic';
  }

  Future<Map<String, dynamic>> _loadPluginInfo(From from) async {
    final response = await callUnifiedComicPlugin(
      from: from,
      fnPath: 'getInfo',
      core: const <String, dynamic>{},
      extern: const <String, dynamic>{},
    );
    return response;
  }

  Future<void> _handleAction(Map<String, dynamic> action) async {
    final type = action['type']?.toString() ?? '';
    final payload = asJsonMap(action['payload']);

    if (type == 'none' || type.isEmpty) {
      return;
    }

    if (type == 'openSearch') {
      final source = _sourceFromString(payload['source']?.toString());
      final keyword = payload['keyword']?.toString() ?? '';
      final url = payload['url']?.toString() ?? '';
      final categories = asJsonList(payload['categories'])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList();

      final extern = <String, dynamic>{
        if (source == From.bika && categories.isNotEmpty)
          'categories': categories,
        if (url.isNotEmpty) 'url': url,
      };

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
      final source = parsed == From.unknown ? _currentFrom : parsed;
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
    From from,
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
    From from,
  ) {
    final type = action['type']?.toString().trim() ?? '';
    if (type != 'openPluginFunction' && type != 'openCloudFavorite') {
      return action;
    }

    final payload = asJsonMap(action['payload']);
    if ((payload['source']?.toString().trim() ?? '').isNotEmpty) {
      return action;
    }

    final nextPayload = Map<String, dynamic>.from(payload)
      ..['source'] = from.name;
    return Map<String, dynamic>.from(action)..['payload'] = nextPayload;
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

  From _sourceFromString(String? source) {
    return switch (source) {
      'bika' => From.bika,
      'jm' => From.jm,
      _ => _currentFrom,
    };
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

  final From from;
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
              onAction: widget.onAction,
              isLoadingMore: false,
              showLoadMoreRetry: false,
              onRetryLoadMore: () {},
            ),
    );
  }
}
