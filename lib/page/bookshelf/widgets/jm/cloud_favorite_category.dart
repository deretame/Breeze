import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/page/bookshelf/json/jm_cloud_favorite/jm_cloud_favorite_json.dart'
    show FolderList;

class CloudFavoriteCategory extends StatefulWidget {
  final String initialSort;
  final List<FolderList> list;
  final Function(String) onSortChanged;

  const CloudFavoriteCategory({
    super.key,
    required this.initialSort,
    required this.list,
    required this.onSortChanged,
  });

  @override
  State<CloudFavoriteCategory> createState() => _CloudFavoriteCategoryState();
}

class _CloudFavoriteCategoryState extends State<CloudFavoriteCategory> {
  // 定义临时列表
  List<FolderList> tempList = [];
  String? selectedValue; // 改为可空，防止初始化问题

  @override
  void initState() {
    super.initState();
    tempList = widget.list.toList();
    tempList.insert(0, FolderList(name: "默认", fid: "", uid: ""));
    bool exists = tempList.any((e) => e.fid == widget.initialSort);
    selectedValue = exists ? widget.initialSort : tempList.first.fid;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        isExpanded: true,
        hint: const Text('选择分类', style: TextStyle(fontSize: 16)),
        items: tempList
            .map(
              (FolderList item) => DropdownMenuItem<String>(
                value: item.fid,
                child: Text(item.name, style: const TextStyle(fontSize: 16)),
              ),
            )
            .toList(),
        value: selectedValue,
        onChanged: (String? value) {
          if (value == null) return;
          setState(() {
            selectedValue = value;
          });
          widget.onSortChanged(value);
        },
        buttonStyleData: const ButtonStyleData(width: 100),
        menuItemStyleData: const MenuItemStyleData(height: 40),
      ),
    );
  }
}
