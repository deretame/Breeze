import 'package:flutter/material.dart';

class ScrollableTitle extends StatelessWidget {
  final String text;

  const ScrollableTitle({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // 设置左右间距，防止内容紧贴边缘
          // const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 20,
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}
