import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/user_download/user_download.dart';

class SortWidget extends StatefulWidget {
  const SortWidget({
    super.key,
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
    final searchEnter = SearchEnterProvider.of(context)!.searchEnter;
    return DropdownButton<String>(
      value: searchEnter.sort,
      icon: const Icon(Icons.expand_more),
      elevation: 16,
      underline: Container(
        height: 2,
      ),
      onChanged: (String? value) {
        setState(
          () {
            context.read<UserDownloadBloc>().add(
                  UserDownloadEvent(
                    SearchEnterConst(
                      keyword: searchEnter.keyword,
                      sort: value!,
                      categories: searchEnter.categories,
                      refresh: searchEnter.refresh,
                    ),
                  ),
                );
          },
        );
      },
      items: sortList.map<DropdownMenuItem<String>>(
        (String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(sortMap[value]!),
          );
        },
      ).toList(),
    );
  }
}
