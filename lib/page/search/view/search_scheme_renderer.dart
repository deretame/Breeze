import 'dart:convert';

import 'package:flutter/material.dart' hide SearchBar;
import 'package:zephyr/page/search/widget/history.dart';
import 'package:zephyr/page/search/widget/search_bar.dart';

import 'search_scheme_json.dart';

class SearchSchemeRenderer {
  SearchSchemeRenderer()
    : _schema = jsonDecode(searchPageSchemeJson) as Map<String, dynamic>;

  final Map<String, dynamic> _schema;

  Widget build() {
    final layout = _asMap(_schema['layout']);
    final children = _asList(layout['children']);
    final widgets = <Widget>[];

    for (final item in children) {
      final config = _asMap(item);
      final type = config['type']?.toString() ?? '';
      switch (type) {
        case 'searchBar':
          widgets.add(const SearchBar());
          break;
        case 'divider':
          widgets.add(Divider(height: (config['height'] as num?)?.toDouble() ?? 1));
          break;
        case 'history':
          final child = const HistoryWidget();
          widgets.add(config['expanded'] == true ? Expanded(child: child) : child);
          break;
        default:
          break;
      }
    }

    return Column(children: widgets);
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
