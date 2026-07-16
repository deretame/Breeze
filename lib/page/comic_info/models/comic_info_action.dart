import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/config/router/router.gr.dart';
import 'package:zephyr/page/comic_list/models/comic_list_scene.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/page/search_result/bloc/search_bloc.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/json/json_value.dart';

Future<void> handleComicInfoAction(
  BuildContext context,
  Map<String, dynamic> action, {
  required String fallbackPluginId,
}) async {
  final type = action['type']?.toString().trim() ?? '';
  final payload = asJsonMap(action['payload']);

  if (type.isEmpty || type == 'none') {
    return;
  }

  if (type == 'openSearch') {
    final pluginId = _sourceIdFromString(
      payload['source']?.toString(),
      fallbackPluginId,
    );
    final keyword = payload['keyword']?.toString() ?? '';
    final externPatch = asJsonMap(payload['extern']);

    final searchStates = SearchStates.initial().copyWith(
      from: pluginId,
      searchKeyword: keyword,
      pluginExtern: externPatch,
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

    return;
  }

  if (type == 'openComicList') {
    final sceneMap = Map<String, dynamic>.from(asJsonMap(payload['scene']));
    if ((sceneMap['source']?.toString().trim() ?? '').isEmpty) {
      sceneMap['source'] = fallbackPluginId;
    }
    final scene = ComicListScene.fromMap(sceneMap);
    context.pushRoute(ComicListRoute(scene: scene, title: scene.title));
    return;
  }

  if (type == 'openComicInfo') {
    final comicId = payload['comicId']?.toString().trim() ?? '';
    if (comicId.isEmpty) {
      return;
    }
    final pluginId = _sourceIdFromString(
      payload['source']?.toString(),
      fallbackPluginId,
    );
    if (pluginId.isEmpty) {
      return;
    }
    context.pushRoute(
      ComicInfoRoute(
        comicId: comicId,
        from: pluginId,
        pluginId: pluginId,
        type: ComicEntryType.normal,
      ),
    );
  }
}

String _sourceIdFromString(String? source, String fallbackPluginId) {
  final resolved = (source ?? '').trim();
  return resolved.isEmpty ? fallbackPluginId : resolved;
}
