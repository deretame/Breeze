import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

class CloudFavoriteSort extends StatefulWidget {
  final String initialSort;
  final Function(String) onSortChanged;

  const CloudFavoriteSort({
    super.key,
    required this.initialSort,
    required this.onSortChanged,
  });

  @override
  State<CloudFavoriteSort> createState() => _CloudFavoriteSortState();
}

class _CloudFavoriteSortState extends State<CloudFavoriteSort> {
  final Map<String, String> sortMap = {'mr': '收藏时间', 'mp': '更新时间'};

  late String selectedValue;

  @override
  void initState() {
    super.initState();
    if (sortMap.containsKey(widget.initialSort)) {
      selectedValue = widget.initialSort;
    } else {
      selectedValue = 'mr';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        isExpanded: true,
        hint: const Text('排序方式', style: TextStyle(fontSize: 16)),
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
