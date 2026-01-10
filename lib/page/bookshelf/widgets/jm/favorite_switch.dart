import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/type/pipe.dart';

class FavoriteSwitch extends StatefulWidget {
  final String initialSort;
  final Function(String) onSortChanged;

  const FavoriteSwitch({
    super.key,
    required this.initialSort,
    required this.onSortChanged,
  });

  @override
  State<FavoriteSwitch> createState() => _FavoriteSwitchState();
}

class _FavoriteSwitchState extends State<FavoriteSwitch> {
  final sortMap = {0: '云端', 1: '本地'};

  late int selectedValue;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.initialSort.let(toInt);
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        isExpanded: true,
        hint: const Text('收藏方式', style: TextStyle(fontSize: 16)),
        items: sortMap.entries.map((entry) {
          return DropdownMenuItem<String>(
            value: entry.key.toString(),
            child: Text(entry.value, style: const TextStyle(fontSize: 16)),
          );
        }).toList(),
        value: selectedValue.toString(),
        onChanged: (String? value) {
          if (value == null) return;
          widget.onSortChanged(value);
        },
        buttonStyleData: const ButtonStyleData(width: 120),
        menuItemStyleData: const MenuItemStyleData(height: 40),
      ),
    );
  }
}
