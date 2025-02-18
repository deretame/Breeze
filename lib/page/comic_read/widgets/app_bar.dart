import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../main.dart';

class ComicReadAppBar extends StatelessWidget {
  final String title;
  final bool isVisible;
  final VoidCallback onThemeModeChanged;

  const ComicReadAppBar({
    super.key,
    required this.title,
    required this.isVisible,
    required this.onThemeModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      top: isVisible ? 0 : -kToolbarHeight - MediaQuery.of(context).padding.top,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: AppBar(
            title: Text(title),
            backgroundColor: globalSetting.backgroundColor.withValues(
              alpha: 0.5,
            ),
            elevation: isVisible ? 4.0 : 0.0,
            actions: [
              IconButton(
                icon:
                    globalSetting.themeMode == ThemeMode.system
                        ? Icon(Icons.brightness_auto_rounded)
                        : Icon(Icons.brightness_auto_outlined),
                onPressed: onThemeModeChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
