import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/search_result/models/models.dart';

import '../bloc/search_bloc.dart';

class SortWidget extends StatefulWidget {
  final SearchEnter searchEnter;
  final ValueChanged<SearchEnter> onChanged;
  const SortWidget({
    super.key,
    required this.searchEnter,
    required this.onChanged,
  });

  @override
  State<SortWidget> createState() => _SortWidgetState();
}

class _SortWidgetState extends State<SortWidget> {
  late final List<String> sortList = ["dd", "da", "ld", "vd"];
  late final Map<String, String> sortMap = {
    "dd": "从新到旧",
    "da": "从旧到新",
    "ld": "最多点赞",
    "vd": "最多观看",
  };

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: widget.searchEnter.sort,
      icon: const Icon(Icons.expand_more),
      elevation: 16,
      underline: Container(height: 2),
      onChanged: (String? value) {
        final newSearchEnter = widget.searchEnter.copyWith(sort: value!);
        setState(() {
          context.read<SearchBloc>().add(
            FetchSearchResult(newSearchEnter, SearchStatus.initial),
          );
        });
        widget.onChanged(newSearchEnter);
      },
      items:
          sortList.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(sortMap[value]!),
            );
          }).toList(),
    );
  }
}
