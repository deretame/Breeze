import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart';

class SortWidget extends StatefulWidget {
  final SearchStatusStore searchStatusStore;
  final Function(String) onSortChanged;

  const SortWidget({
    super.key,
    required this.searchStatusStore,
    required this.onSortChanged,
  });

  @override
  State<SortWidget> createState() => _SortWidgetState();
}

class _SortWidgetState extends State<SortWidget> {
  SearchStatusStore get searchStatusStore => widget.searchStatusStore;

  late final List<String> sortList = ["从新到旧", "从旧到新", "最多点赞", "最多观看"];
  late final Map<String, String> sortMap = {
    "dd": "从新到旧",
    "da": "从旧到新",
    "ld": "最多点赞",
    "vd": "最多观看",
  };
  late final Map<String, String> sortMap2 = {
    "从新到旧": "dd",
    "从旧到新": "da",
    "最多点赞": "ld",
    "最多观看": "vd",
  };

  late String selectedValue;

  @override
  void initState() {
    super.initState();
    selectedValue = sortMap[searchStatusStore.sort]!;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        isExpanded: true,
        hint: Text('选择排序', style: TextStyle(fontSize: 16)),
        items: sortList
            .map(
              (String item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item, style: const TextStyle(fontSize: 16)),
              ),
            )
            .toList(),
        value: selectedValue,
        onChanged: (String? value) {
          setState(() {
            selectedValue = value!;
          });
          widget.onSortChanged(sortMap2[value!]!);
        },
        buttonStyleData: const ButtonStyleData(width: 100),
        menuItemStyleData: const MenuItemStyleData(height: 40),
      ),
    );
  }
}
