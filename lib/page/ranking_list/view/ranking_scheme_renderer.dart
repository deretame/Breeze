import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:zephyr/page/jm/jm_ranking/view/jm_ranking.dart';
import 'package:zephyr/page/ranking_list/view/bika_rank_list.dart';

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
    required List<String> currentFilter,
  }) {
    final mode = _findMode(comicChoice);
    final sections = _asList(mode['sections']).map((item) => _asMap(item)).toList();
    final bodyType = sections.isEmpty
        ? 'bikaRanking'
        : sections.first['type']?.toString() ?? 'bikaRanking';
    if (bodyType == 'jmRanking') {
      return JmRankingPage(
        categoryId: currentFilter[0],
        sortId: currentFilter[1],
      );
    }
    return const BikaRankList();
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
