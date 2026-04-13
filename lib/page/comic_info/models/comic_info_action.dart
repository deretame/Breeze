import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/comic_list/models/comic_list_scene.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/page/search_result/bloc/search_bloc.dart';
import 'package:zephyr/util/json/json_value.dart';

import '../../../util/router/router.gr.dart';

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
  }
}

String _sourceIdFromString(String? source, String fallbackPluginId) {
  final resolved = (source ?? '').trim();
  return resolved.isEmpty ? fallbackPluginId : resolved;
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
