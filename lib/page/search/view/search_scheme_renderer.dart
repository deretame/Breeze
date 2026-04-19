import 'dart:convert';

import 'package:flutter/material.dart' hide SearchBar;
import 'package:zephyr/util/json/json_value.dart';
import 'package:zephyr/page/search/widget/history.dart';
import 'package:zephyr/page/search/widget/search_bar.dart';

import 'search_scheme_json.dart';

class SearchSchemeRenderer {
  SearchSchemeRenderer({required this.aggregateMode})
    : _schema = jsonDecode(searchPageSchemeJson) as Map<String, dynamic>;

  final Map<String, dynamic> _schema;
  final bool aggregateMode;

  Widget build() {
    final layout = asJsonMap(_schema['layout']);
    final children = asJsonList(layout['children']);
    final widgets = <Widget>[];

    for (final item in children) {
      final config = asJsonMap(item);
      final type = config['type']?.toString() ?? '';
      switch (type) {
        case 'searchBar':
          widgets.add(SearchBar(aggregateMode: aggregateMode));
          break;
        case 'divider':
          widgets.add(
            Divider(height: (config['height'] as num?)?.toDouble() ?? 1),
          );
          break;
        case 'history':
          final child = HistoryWidget(aggregateMode: aggregateMode);
          widgets.add(
            config['expanded'] == true ? Expanded(child: child) : child,
          );
          break;
        default:
          break;
      }
    }

    return Column(children: widgets);
  }
}
