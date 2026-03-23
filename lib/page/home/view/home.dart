import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zephyr/config/bika/bika_setting.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/page/comic_list/models/comic_list_scene.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/page/search_result/bloc/search_bloc.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/json/json_value.dart';
import 'package:zephyr/util/jm_url_set.dart';
import 'package:zephyr/util/router/router.gr.dart';

import 'home_scheme_renderer.dart';

enum HomeFeedStatus {
  initial,
  success,
  failure,
  loadingMore,
  loadingMoreFailure,
}

class HomeFeedSnapshot {
  const HomeFeedSnapshot({
    this.status = HomeFeedStatus.initial,
    this.scheme = const <String, dynamic>{},
    this.data = const <String, dynamic>{},
    this.title = '',
    this.result = '',
    this.hasReachedMax = true,
    this.nextPage = 0,
  });

  final HomeFeedStatus status;
  final Map<String, dynamic> scheme;
  final Map<String, dynamic> data;
  final String title;
  final String result;
  final bool hasReachedMax;
  final int nextPage;

  HomeFeedSnapshot copyWith({
    HomeFeedStatus? status,
    Map<String, dynamic>? scheme,
    Map<String, dynamic>? data,
    String? title,
    String? result,
    bool? hasReachedMax,
    int? nextPage,
  }) {
    return HomeFeedSnapshot(
      status: status ?? this.status,
      scheme: scheme ?? this.scheme,
      data: data ?? this.data,
      title: title ?? this.title,
      result: result ?? this.result,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      nextPage: nextPage ?? this.nextPage,
    );
  }
}

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeSchemeRenderer _renderer = const HomeSchemeRenderer();
  final Map<From, HomeFeedSnapshot> _snapshots = {
    From.bika: const HomeFeedSnapshot(),
    From.jm: const HomeFeedSnapshot(),
  };
  final Set<From> _loadingInitial = <From>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _ensureLoaded(_currentFrom);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final globalSettingState = context.watch<GlobalSettingCubit>().state;
    final from = globalSettingState.disableBika ? From.jm : _currentFrom;

    _ensureLoaded(from);

    final snapshot = _snapshots[from] ?? const HomeFeedSnapshot();
    final fallbackTitle = from == From.bika ? '哔咔漫画' : '禁漫首页';
    final title = _renderer.title(
      snapshot.scheme,
      snapshot.title.isNotEmpty ? snapshot.title : fallbackTitle,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
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
        child: _buildBody(from, snapshot),
      ),
      floatingActionButton: globalSettingState.disableBika
          ? null
          : FloatingActionButton(
              heroTag: const ValueKey('switch_comic'),
              onPressed: _switchComic,
              child: const Icon(Icons.compare_arrows),
            ),
    );
  }

  From get _currentFrom {
    final state = context.read<GlobalSettingCubit>().state;
    return state.comicChoice == 1 ? From.bika : From.jm;
  }

  Widget _buildBody(From from, HomeFeedSnapshot snapshot) {
    if (_loadingInitial.contains(from) &&
        snapshot.scheme.isEmpty &&
        snapshot.status == HomeFeedStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.status == HomeFeedStatus.failure && snapshot.scheme.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(snapshot.result),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _loadInitial(from, force: true),
              child: const Text('重新加载'),
            ),
          ],
        ),
      );
    }

    return _renderer.buildPage(
      context,
      from: from,
      scheme: snapshot.scheme,
      data: snapshot.data,
      onReachBottom: () => _loadMore(from),
      onAction: _handleAction,
      isLoadingMore: snapshot.status == HomeFeedStatus.loadingMore,
      showLoadMoreRetry: snapshot.status == HomeFeedStatus.loadingMoreFailure,
      onRetryLoadMore: () => _loadMore(from, force: true),
    );
  }

  Future<void> _reloadCurrent() async {
    await _loadInitial(_currentFrom, force: true);
  }

  void _ensureLoaded(From from) {
    final snapshot = _snapshots[from] ?? const HomeFeedSnapshot();
    if (_loadingInitial.contains(from) || snapshot.scheme.isNotEmpty) {
      return;
    }

    _loadInitial(from);
  }

  Future<void> _loadInitial(From from, {bool force = false}) async {
    if (_loadingInitial.contains(from) && !force) {
      return;
    }

    setState(() {
      _loadingInitial.add(from);
      _snapshots[from] = const HomeFeedSnapshot(status: HomeFeedStatus.initial);
    });

    try {
      final response = await callUnifiedComicPlugin(
        from: from,
        fnPath: 'getHomeData',
        core: _initialHomeCore(from),
        extern: _initialHomeExtern(from),
      );
      final envelope = UnifiedPluginEnvelope.fromMap(response);
      final incoming = asMap(envelope.data);

      final title =
          envelope.scheme['title']?.toString() ??
          (from == From.bika ? '哔咔漫画' : '禁漫首页');

      if (!mounted) {
        return;
      }

      setState(() {
        _snapshots[from] = HomeFeedSnapshot(
          status: HomeFeedStatus.success,
          scheme: envelope.scheme,
          data: incoming,
          title: title,
          hasReachedMax: incoming['hasReachedMax'] == true,
          nextPage: 0,
        );
        _loadingInitial.remove(from);
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _snapshots[from] = HomeFeedSnapshot(
          status: HomeFeedStatus.failure,
          result: e.toString(),
        );
        _loadingInitial.remove(from);
      });
    }
  }

  Future<void> _loadMore(From from, {bool force = false}) async {
    if (from != From.jm) {
      return;
    }

    final snapshot = _snapshots[from] ?? const HomeFeedSnapshot();
    if (!force &&
        (snapshot.hasReachedMax ||
            snapshot.status == HomeFeedStatus.loadingMore ||
            snapshot.scheme.isEmpty)) {
      return;
    }

    setState(() {
      _snapshots[from] = snapshot.copyWith(status: HomeFeedStatus.loadingMore);
    });

    try {
      final response = await callUnifiedComicPlugin(
        from: from,
        fnPath: 'getHomeData',
        core: {'page': snapshot.nextPage, 'path': '$currentJmBaseUrl/latest'},
        extern: const {
          'source': 'home',
          'suggestionPath': 'https://www.cdnsha.org/latest',
        },
      );
      final envelope = UnifiedPluginEnvelope.fromMap(response);
      final incoming = asMap(envelope.data);
      final currentData = Map<String, dynamic>.from(snapshot.data);
      final existingItems = asJsonList(
        currentData['suggestionItems'],
      ).map((item) => asJsonMap(item)).toList();
      final nextItems = asJsonList(
        incoming['suggestionItems'],
      ).map((item) => asJsonMap(item)).toList();
      currentData['suggestionItems'] = [...existingItems, ...nextItems];
      currentData['sections'] =
          currentData['sections'] ?? incoming['sections'] ?? const <dynamic>[];

      if (!mounted) {
        return;
      }

      setState(() {
        _snapshots[from] = snapshot.copyWith(
          status: HomeFeedStatus.success,
          scheme: envelope.scheme.isNotEmpty
              ? envelope.scheme
              : snapshot.scheme,
          data: currentData,
          nextPage: snapshot.nextPage + 1,
          hasReachedMax: incoming['hasReachedMax'] == true,
        );
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _snapshots[from] = snapshot.copyWith(
          status: HomeFeedStatus.loadingMoreFailure,
          result: e.toString(),
        );
      });
    }
  }

  Map<String, dynamic> _initialHomeCore(From from) {
    if (from == From.jm) {
      return {'page': -1, 'path': '$currentJmBaseUrl/promote?page=0'};
    }
    return const <String, dynamic>{};
  }

  Map<String, dynamic> _initialHomeExtern(From from) {
    if (from == From.jm) {
      return const {
        'source': 'home',
        'promotePath': 'https://www.cdnsha.org/promote?page=0',
      };
    }
    return const {'source': 'home'};
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

      var searchStates = SearchStates.initial(
        context,
      ).copyWith(from: source, searchKeyword: keyword);

      if (source == From.bika && categories.isNotEmpty) {
        final selectedCategories = {
          for (final key in categoryMap.keys) key: categories.contains(key),
        };
        searchStates = searchStates.copyWith(categories: selectedCategories);
      }

      context.pushRoute(
        SearchResultRoute(
          searchEvent: SearchEvent().copyWith(
            searchStates: searchStates,
            url: url,
          ),
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

    if (type == 'openComicList') {
      final scene = ComicListScene.fromMap(asJsonMap(payload['scene']));
      context.pushRoute(ComicListRoute(scene: scene, title: scene.title));
      return;
    }
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

  void _switchComic() {
    final globalSettingCubit = context.read<GlobalSettingCubit>();

    if (globalSettingCubit.state.comicChoice == 1) {
      globalSettingCubit.updateState(
        (current) => current.copyWith(comicChoice: 2),
      );
      _ensureLoaded(From.jm);
    } else {
      globalSettingCubit.updateState(
        (current) => current.copyWith(comicChoice: 1),
      );
      _ensureLoaded(From.bika);
    }
  }

  void search() {
    final globalSettingState = context.read<GlobalSettingCubit>().state;

    if (globalSettingState.disableBika) {
      context.pushRoute(
        SearchRoute(
          searchState: SearchStates.initial(context).copyWith(from: From.jm),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          children: [
            SimpleDialogOption(
              onPressed: () {
                context.pop();
                context.pushRoute(
                  SearchRoute(
                    searchState: SearchStates.initial(
                      context,
                    ).copyWith(from: From.bika),
                  ),
                );
              },
              child: const Chip(
                label: Text("哔咔漫画"),
                backgroundColor: Colors.pink,
                labelStyle: TextStyle(color: Colors.white),
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                context.pop();
                context.pushRoute(
                  SearchRoute(
                    searchState: SearchStates.initial(
                      context,
                    ).copyWith(from: From.jm),
                  ),
                );
              },
              child: const Chip(
                label: Text("禁漫天堂"),
                backgroundColor: Colors.orange,
                labelStyle: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
