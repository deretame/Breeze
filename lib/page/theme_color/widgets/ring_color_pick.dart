import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ColorPickerPage extends StatelessWidget {
  final Color currentColor;
  final Function(Color) onColorChanged;

  const ColorPickerPage({
    super.key,
    required this.currentColor,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 颜色选择器
          HueRingPicker(
            pickerColor: currentColor,
            onColorChanged: onColorChanged, // 颜色变化时回调
            displayThumbColor: true, // 是否显示拇指颜色
          ),
        ],
      ),
    );
  }
}
