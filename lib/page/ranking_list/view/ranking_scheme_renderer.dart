import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:zephyr/page/ranking_list/view/plugin_paged_comic_list_view.dart';
import 'package:zephyr/page/ranking_list/view/ranking_content_view.dart';
import 'package:zephyr/type/enum.dart';

import 'ranking_scheme_json.dart';

class RankingSchemeRenderer {
  RankingSchemeRenderer()
    : _schema = jsonDecode(rankingPageSchemeJson) as Map<String, dynamic>;

  final Map<String, dynamic> _schema;

  String title(int comicChoice) {
    return _findMode(comicChoice)['title']?.toString() ?? '';
  }

  bool showFilter(int comicChoice) {
    return _findMode(comicChoice)['showFilter'] == true;
  }

  bool showSwitchFab(int comicChoice) {
    return _findMode(comicChoice)['showSwitchFab'] == true;
  }

  Widget body({
    required int comicChoice,
    required Map<String, dynamic> currentFilter,
  }) {
    final mode = _findMode(comicChoice);
    final sections = _asList(mode['sections']).map((item) => _asMap(item)).toList();
    final bodyType = sections.isEmpty
        ? 'bikaRanking'
        : sections.first['type']?.toString() ?? 'bikaRanking';
    if (bodyType == 'jmRanking') {
      final type = currentFilter['type']?.toString() ?? '0';
      final order = currentFilter['order']?.toString() ?? 'new';
      return PluginPagedComicListView(
        key: ValueKey('ranking_${type}_$order'),
        from: From.jm,
        fnPath: 'getRankingData',
        coreBuilder: (page) => {'page': page},
        externBuilder: (_) => {
          'type': type,
          'order': order,
          'source': 'ranking',
        },
        itemMapper: (item) => item,
      );
    }
    return RankingContentView(
      days: currentFilter['days']?.toString() ?? 'H24',
      rankingType: currentFilter['type']?.toString() ?? 'comic',
      card: currentFilter['card']?.toString() ?? 'comic',
    );
  }

  Map<String, dynamic> _findMode(int comicChoice) {
    final modes = _asMap(_schema['modes']);
    for (final entry in modes.entries) {
      final mode = _asMap(entry.value);
      final value = (mode['comicChoice'] as num?)?.toInt();
      if (value == comicChoice) {
        return mode;
      }
    }
    return _asMap(modes['bika']);
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.fromEntries(
        value.entries.map((entry) => MapEntry(entry.key.toString(), entry.value)),
      );
    }
    return const <String, dynamic>{};
  }

  List<dynamic> _asList(dynamic value) {
    if (value is List) {
      return value;
    }
    return const <dynamic>[];
  }
}
