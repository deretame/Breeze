import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:zephyr/util/desktop/native_window.dart';

/// Material 3 风格的自定义标题栏（仅桌面平台使用）
class CustomTitleBar extends StatefulWidget {
  const CustomTitleBar({super.key});

  @override
  State<CustomTitleBar> createState() => _CustomTitleBarState();
}

class _CustomTitleBarState extends State<CustomTitleBar> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    if (Platform.isWindows && NativeWindow.isReady) {
      _isMaximized = NativeWindow.isMaximized;
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() {
    if (mounted) setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) setState(() => _isMaximized = false);
  }

  void _minimize() {
    if (Platform.isWindows) {
      NativeWindow.minimize();
    } else {
      windowManager.minimize();
    }
  }

  void _toggleMaximize() {
    if (Platform.isWindows) {
      NativeWindow.toggleMaximize();
    } else if (_isMaximized) {
      windowManager.unmaximize();
    } else {
      windowManager.maximize();
    }
  }

  void _handleClose() {
    if (Platform.isWindows) {
      NativeWindow.close();
    } else {
      windowManager.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 40,
      color: colorScheme.surface,
      child: Row(
        children: [
          // 1. 左侧和中间区域：负责拖拽和双击
          // 使用 Expanded 占满剩余空间，把按钮挤到右边
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent, // 确保空白处也能响应
              onPanStart: (_) => windowManager.startDragging(),
              onDoubleTap: _toggleMaximize,
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Image.asset(
                    'asset/image/app_icon.ico',
                    width: 18,
                    height: 18,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Breeze',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. 右侧按钮区域：完全独立，不受 onDoubleTap 影响
          // 这里的点击会瞬间响应，因为它们不在上面的 GestureDetector 内部
          _TitleBarButton(
            icon: Icons.minimize_rounded,
            onPressed: _minimize,
            hoverColor: colorScheme.onSurface.withValues(alpha: 0.08),
            iconColor: colorScheme.onSurfaceVariant,
          ),
          _TitleBarButton(
            icon: _isMaximized
                ? Icons.filter_none_rounded
                : Icons.crop_square_rounded,
            onPressed: _toggleMaximize,
            hoverColor: colorScheme.onSurface.withValues(alpha: 0.08),
            iconColor: colorScheme.onSurfaceVariant,
          ),
          _TitleBarButton(
            icon: Icons.close_rounded,
            onPressed: _handleClose,
            hoverColor: Colors.red,
            hoverIconColor: Colors.white,
            iconColor: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

/// 标题栏上的单个按钮
class _TitleBarButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color hoverColor;
  final Color iconColor;
  final Color? hoverIconColor;

  const _TitleBarButton({
    required this.icon,
    required this.onPressed,
    required this.hoverColor,
    required this.iconColor,
    this.hoverIconColor,
  });

  @override
  State<_TitleBarButton> createState() => _TitleBarButtonState();
}

class _TitleBarButtonState extends State<_TitleBarButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 46,
          height: 40,
          color: _isHovered ? widget.hoverColor : Colors.transparent,
          child: Icon(
            widget.icon,
            size: 18,
            color: _isHovered
                ? (widget.hoverIconColor ?? widget.iconColor)
                : widget.iconColor,
          ),
        ),
      ),
    );
  }
}
