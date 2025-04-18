import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/search_result/models/models.dart';

import '../bloc/search_bloc.dart';
import '../method/search_enter_provider.dart';

class SortWidget extends StatefulWidget {
  const SortWidget({super.key});

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
    final searchEnter = SearchEnterProvider.of(context)!.searchEnter;
    return DropdownButton<String>(
      value: searchEnter.sort,
      icon: const Icon(Icons.expand_more),
      elevation: 16,
      underline: Container(height: 2),
      onChanged: (String? value) {
        setState(() {
          context.read<SearchBloc>().add(
            FetchSearchResult(
              SearchEnterConst(
                url: searchEnter.url,
                from: searchEnter.from,
                keyword: searchEnter.keyword,
                type: searchEnter.type,
                state: searchEnter.state,
                sort: value!,
                categories: searchEnter.categories,
                pageCount: 1,
                refresh: searchEnter.refresh,
              ),
              SearchStatus.initial,
            ),
          );
        });
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
