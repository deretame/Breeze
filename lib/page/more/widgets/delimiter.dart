import 'package:flutter/material.dart';
import 'package:zephyr/config/global/global.dart';
import 'package:zephyr/main.dart';

class Delimiter extends StatelessWidget {
  const Delimiter({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: screenWidth * (48 / 50), // 设置宽度
        child: Divider(
          color: materialColorScheme.secondaryFixedDim,
          thickness: 1,
          height: 15,
        ),
      ),
    );
  }
}
