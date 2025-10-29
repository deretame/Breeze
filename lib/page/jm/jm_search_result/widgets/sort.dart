import 'package:flutter/material.dart';

import '../bloc/jm_search_result_bloc.dart';

class SortWidget extends StatefulWidget {
  final JmSearchResultEvent event;
  final ValueChanged sortCallback;

  const SortWidget({
    super.key,
    required this.event,
    required this.sortCallback,
  });

  @override
  State<SortWidget> createState() => _SortWidgetState();
}

class _SortWidgetState extends State<SortWidget> {
  JmSearchResultEvent get event => widget.event;

  ValueChanged get searchCallback => widget.sortCallback;

  final List<String> sortList = ["", "mv", "mp", "tf"];
  final Map<String, String> sortMap = {
    "": "从新到旧",
    "mv": "最多观看",
    "mp": "最多图片",
    "tf": "最多点赞",
  };

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: event.sort,
      icon: const Icon(Icons.expand_more),
      elevation: 16,
      underline: Container(height: 2),
      onChanged: searchCallback,
      items: sortList.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(sortMap[value]!),
        );
      }).toList(),
    );
  }
}
