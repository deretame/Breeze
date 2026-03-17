import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:zephyr/page/jm/jm_promote/view/jm_promote.dart';

import 'home_scheme_json.dart';

class HomeSchemeRenderer {
  HomeSchemeRenderer()
    : _schema = jsonDecode(homePageSchemeJson) as Map<String, dynamic>;

  final Map<String, dynamic> _schema;

  String titleForChoice(int comicChoice) {
    final mode = _findMode(comicChoice);
    return mode['title']?.toString() ?? '';
  }

  bool showSwitchFab(int comicChoice) {
    final mode = _findMode(comicChoice);
    final fab = _asMap(mode['fab']);
    return fab['enabled'] == true;
  }

  Widget buildBody({
    required int comicChoice,
    required ScrollController? bikaScrollController,
    required Widget bikaKeyword,
    required Widget bikaCategory,
  }) {
    final mode = _findMode(comicChoice);
    final body = _asMap(mode['body']);
    final listKey = body['listKey']?.toString() ?? 'bika_list';
    final sections = _asList(mode['sections'])
        .map((item) => _asMap(item))
        .toList();

    if (sections.length == 1 && sections.first['type'] == 'jmPromote') {
      return const JmPromotePage(key: ValueKey('jm_promote'));
    }

    final children = <Widget>[];
    for (final section in sections) {
      final type = section['type']?.toString() ?? '';
      if (type == 'bikaKeyword') {
        children.add(bikaKeyword);
      } else if (type == 'bikaCategory') {
        children.add(bikaCategory);
      }
    }

    return ListView(
      key: ValueKey(listKey),
      physics: const AlwaysScrollableScrollPhysics(),
      controller: bikaScrollController,
      children: children,
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
