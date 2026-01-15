import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

class SortWidget extends StatefulWidget {
  final String initialSort;
  final Function(String) onSortChanged;

  const SortWidget({
    super.key,
    required this.initialSort,
    required this.onSortChanged,
  });

  @override
  State<SortWidget> createState() => _SortWidgetState();
}

class _SortWidgetState extends State<SortWidget> {
  final Map<String, String> sortMap = {
    "dd": "从新到旧",
    "da": "从旧到新",
    "ld": "最多点赞",
    "vd": "最多观看",
  };

  late String selectedValue;

  @override
  void initState() {
    super.initState();
    selectedValue = sortMap.containsKey(widget.initialSort)
        ? widget.initialSort
        : "dd";
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        isExpanded: true,
        hint: const Text('选择排序', style: TextStyle(fontSize: 16)),
        items: sortMap.entries.map((entry) {
          return DropdownMenuItem<String>(
            value: entry.key,
            child: Text(entry.value, style: const TextStyle(fontSize: 16)),
          );
        }).toList(),
        value: selectedValue,
        onChanged: (String? value) {
          if (value == null) return;

          setState(() {
            selectedValue = value;
          });
          widget.onSortChanged(value);
        },
        buttonStyleData: const ButtonStyleData(width: 120),
        menuItemStyleData: const MenuItemStyleData(height: 40),
      ),
    );
  }
}
