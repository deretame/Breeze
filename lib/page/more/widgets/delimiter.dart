import 'package:flutter/material.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/util/context/context_extensions.dart';

class Delimiter extends StatelessWidget {
  const Delimiter({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: context.screenWidth * (48 / 50), // 设置宽度
        child: Divider(
          color: materialColorScheme.secondaryFixedDim,
          thickness: 1,
          height: 15,
        ),
      ),
    );
  }
}
