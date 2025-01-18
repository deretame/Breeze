import 'package:flutter/material.dart';
import 'package:zephyr/config/global.dart';

import '../../../config/color_theme_types.dart';

class ColorThemeItem extends StatelessWidget {
  final ColorThemeInfo colorInfo;
  final Color currentColor;
  final Function(Color) onColorSelected;

  const ColorThemeItem({
    super.key,
    required this.colorInfo,
    required this.currentColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: screenWidth / 4 - 30, // 每个颜色块的宽度
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            onColorSelected(colorInfo.color); // 点击颜色块后回调
          },
          borderRadius: BorderRadius.circular(8),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: colorInfo.color,
                  borderRadius: BorderRadius.circular(8), // 圆角
                  border: currentColor == colorInfo.color
                      ? Border.all(color: Colors.black, width: 2) // 选中状态
                      : null,
                ),
              ),
              SizedBox(height: 8), // 颜色块和文字的间距
              Text(
                colorInfo.label,
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
