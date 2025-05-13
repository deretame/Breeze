import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/bookshelf/view/bookshelf_page.dart';

class TopTabBar extends StatelessWidget {
  const TopTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        return CustomSlidingSegmentedControl<int>(
          // fromMax: true,
          children: const {
            1: Text('哔咔', textAlign: TextAlign.center),
            2: Text('禁漫', textAlign: TextAlign.center),
          },
          dividerSettings: DividerSettings(
            thickness: 2,
            endIndent: 8,
            indent: 8,
            decoration: BoxDecoration(
              color: materialColorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          isShowDivider: true,
          decoration: BoxDecoration(
            color: materialColorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          thumbDecoration: BoxDecoration(
            color: materialColorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .3),
                blurRadius: 4.0,
                spreadRadius: 1.0,
                offset: const Offset(0.0, 2.0),
              ),
            ],
          ),
          onValueChanged: (int value) {
            bookshelfStore.topBarStore.setDate(value);
          },
        );
      },
    );
  }
}
