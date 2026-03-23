import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zephyr/config/bika/bika_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/comic_list/models/comic_list_scene.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/page/search_result/bloc/search_bloc.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/json/json_value.dart';

import '../../../util/router/router.gr.dart';

Future<void> handleComicInfoAction(
  BuildContext context,
  Map<String, dynamic> action, {
  required From fallbackFrom,
}) async {
  final type = action['type']?.toString().trim() ?? '';
  final payload = asJsonMap(action['payload']);

  if (type.isEmpty || type == 'none') {
    return;
  }

  if (type == 'openSearch') {
    final source = _sourceFromString(payload['source']?.toString(), fallbackFrom);
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
  }
}

From _sourceFromString(String? source, From fallbackFrom) {
  return switch (source) {
    'bika' => From.bika,
    'jm' => From.jm,
    _ => fallbackFrom,
  };
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
