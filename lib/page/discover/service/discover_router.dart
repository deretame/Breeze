import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/page/comic_list/models/comic_list_scene.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/page/search_result/bloc/search_bloc.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/json/json_value.dart';
import 'package:zephyr/config/router/router.gr.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/widgets/toast.dart';

import 'package:zephyr/page/discover/view/plugin_function_dialog.dart';

/// Discover 页插件动作路由。
///
/// 把插件返回的 action 协议转换为具体页面跳转，
/// 与 UI 解耦，方便集中维护。
class DiscoverRouter {
  DiscoverRouter._();

  static Future<void> route(
    BuildContext context, {
    required Map<String, dynamic> action,
    required String currentFrom,
  }) async {
    final type = action['type']?.toString() ?? '';

    if (type == 'none' || type.isEmpty) {
      return;
    }

    switch (type) {
      case 'openSearch':
        await _openSearch(context, asJsonMap(action['payload']));
      case 'openWeb':
        await _openWeb(context, asJsonMap(action['payload']));
      case 'openPluginFunction':
        await _openPluginFunction(
          context,
          asJsonMap(action['payload']),
          currentFrom: currentFrom,
        );
      case 'openCloudFavorite':
        await _openCloudFavorite(
          context,
          asJsonMap(action['payload']),
          currentFrom: currentFrom,
        );
      case 'openComicList':
        await _openComicList(context, asJsonMap(action['payload']));
      case 'openComicInfo':
        await _openComicInfo(context, asJsonMap(action['payload']));
    }
  }

  /// 为需要插件来源的动作自动补全 source。
  static Map<String, dynamic> attachSource(
    Map<String, dynamic> action,
    String from,
  ) {
    final type = action['type']?.toString().trim() ?? '';
    if (type != 'openPluginFunction' &&
        type != 'openCloudFavorite' &&
        type != 'openSearch' &&
        type != 'openComicList' &&
        type != 'openComicInfo') {
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

  static Future<void> _openSearch(
    BuildContext context,
    Map<String, dynamic> payload,
  ) async {
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

    if (!context.mounted) {
      return;
    }
    context.pushRoute(
      SearchResultRoute(
        searchEvent: SearchEvent().copyWith(searchStates: searchStates),
      ),
    );
  }

  static Future<void> _openWeb(
    BuildContext context,
    Map<String, dynamic> payload,
  ) async {
    final title = payload['title']?.toString() ?? '';
    final url = payload['url']?.toString() ?? '';
    if (url.isEmpty) {
      return;
    }

    if (!context.mounted) {
      return;
    }
    context.pushRoute(WebViewRoute(info: [title, url]));
  }

  static Future<void> _openPluginFunction(
    BuildContext context,
    Map<String, dynamic> payload, {
    required String currentFrom,
  }) async {
    final source = _sourceFromString(payload['source']?.toString());
    if (source.isEmpty) {
      showErrorToast(t.error.missingPluginSource(action: t.oldHome.function));
      return;
    }

    final functionId = payload['id']?.toString().trim() ?? '';
    if (functionId.isEmpty) {
      return;
    }
    final title = payload['title']?.toString().trim() ?? t.oldHome.function;
    final presentation = payload['presentation']?.toString().trim() ?? 'page';

    Future<void> onAction(Map<String, dynamic> action) => route(
      context,
      action: attachSource(action, source),
      currentFrom: currentFrom,
    );

    if (presentation != 'dialog') {
      if (!context.mounted) {
        return;
      }
      await context.pushRoute(
        PluginFunctionRoute(
          from: source,
          functionId: functionId,
          title: title,
          onAction: onAction,
        ),
      );
      return;
    }

    if (!context.mounted) {
      return;
    }
    final mediaSize = MediaQuery.sizeOf(context);
    final dialogWidth = (mediaSize.width * 0.9).clamp(280.0, 560.0).toDouble();

    await showDialog<void>(
      context: context,
      builder: (context) => PluginFunctionDialog(
        from: source,
        functionId: functionId,
        title: title,
        onAction: onAction,
        dialogWidth: dialogWidth,
      ),
    );
  }

  static Future<void> _openCloudFavorite(
    BuildContext context,
    Map<String, dynamic> payload, {
    required String currentFrom,
  }) async {
    final parsed = _sourceFromString(payload['source']?.toString());
    final source = parsed.isEmpty ? currentFrom : parsed;
    if (source.isEmpty) {
      showErrorToast(
        t.error.missingPluginSource(action: t.oldHome.cloudFavorite),
      );
      return;
    }

    final title = payload['title']?.toString();

    if (!context.mounted) {
      return;
    }
    context.pushRoute(
      ComicListRoute(
        title: title ?? t.oldHome.cloudFavorite,
        sceneSource: source,
        sceneBundleFnPath: 'getCloudFavoriteSceneBundle',
        sceneBundleFnPathFallback: 'get_cloud_favorite_scene_bundle',
      ),
    );
  }

  static Future<void> _openComicList(
    BuildContext context,
    Map<String, dynamic> payload,
  ) async {
    final scene = ComicListScene.fromMap(asJsonMap(payload['scene']));

    if (!context.mounted) {
      return;
    }
    context.pushRoute(ComicListRoute(scene: scene, title: scene.title));
  }

  static Future<void> _openComicInfo(
    BuildContext context,
    Map<String, dynamic> payload,
  ) async {
    final comicId = payload['comicId']?.toString().trim() ?? '';
    if (comicId.isEmpty) {
      return;
    }

    final source = _sourceFromString(payload['source']?.toString());
    if (source.isEmpty) {
      return;
    }

    if (!context.mounted) {
      return;
    }
    context.pushRoute(
      ComicInfoRoute(
        comicId: comicId,
        from: source,
        pluginId: source,
        type: ComicEntryType.normal,
      ),
    );
  }

  static Map<String, dynamic> _normalizeOpenSearchExtern(
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

  static String _sourceFromString(String? source) {
    return (source ?? '').trim();
  }
}
