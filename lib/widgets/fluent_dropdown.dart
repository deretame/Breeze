import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zephyr/util/context/context_extensions.dart';

/// A single entry in a fluent popup menu.
class FluentPopupMenuItem<T> {
  const FluentPopupMenuItem({
    required this.value,
    this.leading,
    required this.title,
    this.trailing,
    this.enabled = true,
  });

  /// The value returned when this item is selected.
  final T value;

  /// Optional widget displayed at the start of the item (typically an icon).
  final Widget? leading;

  /// The main label of the item.
  final Widget title;

  /// Optional widget displayed at the end of the item.
  final Widget? trailing;

  /// Whether the item can be selected.
  final bool enabled;
}

/// Internal representation of a menu entry, used by the shared overlay.
class _MenuEntry<T> {
  const _MenuEntry({
    required this.value,
    this.leading,
    required this.title,
    this.trailing,
    this.enabled = true,
    this.isSelected = false,
  });

  final T value;
  final Widget? leading;
  final Widget title;
  final Widget? trailing;
  final bool enabled;
  final bool isSelected;
}

/// A button that displays a fluent-styled popup menu when tapped.
///
/// This is intended as a drop-in replacement for [PopupMenuButton] with the
/// same visual style as [FluentDropdown], but without any selected-value
/// highlighting inside the menu.
class FluentPopupMenuButton<T> extends StatefulWidget {
  const FluentPopupMenuButton({
    super.key,
    required this.itemBuilder,
    this.onSelected,
    this.child,
    this.icon,
    this.tooltip,
    this.enabled = true,
  });

  /// Called to build the list of menu items when the menu is opened.
  final List<FluentPopupMenuItem<T>> Function(BuildContext context) itemBuilder;

  /// Called when the user selects an item.
  final ValueChanged<T>? onSelected;

  /// The widget used as the tappable trigger. Either [child] or [icon] must
  /// be provided.
  final Widget? child;

  /// Convenience property to use an icon as the trigger. Either [child] or
  /// [icon] must be provided.
  final Widget? icon;

  /// Tooltip shown on long press / hover.
  final String? tooltip;

  /// Whether the button can be pressed.
  final bool enabled;

  @override
  State<FluentPopupMenuButton<T>> createState() =>
      _FluentPopupMenuButtonState<T>();
}

class _FluentPopupMenuButtonState<T> extends State<FluentPopupMenuButton<T>>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 220),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (!mounted) return;
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    final items = widget.itemBuilder(context);
    final entries = items
        .map(
          (item) => _MenuEntry<T>(
            value: item.value,
            leading: item.leading,
            title: item.title,
            trailing: item.trailing,
            enabled: item.enabled,
          ),
        )
        .toList();

    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);
    final screenSize = MediaQuery.sizeOf(context);
    final safePadding = MediaQuery.paddingOf(context);

    final fitsBelow =
        position.dy + size.height + 8 + 200 <
        screenSize.height - safePadding.bottom;
    final fitsRight = position.dx + 220 <= screenSize.width - safePadding.right;
    final menuWidth = _calculateMenuWidth(context, size.width, entries);

    _overlayEntry = OverlayEntry(
      builder: (context) => _MenuOverlay<T>(
        layerLink: _layerLink,
        triggerSize: size,
        menuWidth: menuWidth,
        entries: entries,
        alignRight: !fitsRight,
        alignTop: !fitsBelow,
        onSelected: (value) {
          _close(onComplete: () => widget.onSelected?.call(value));
        },
        onDismiss: _close,
        scaleAnimation: _scaleAnimation,
        opacityAnimation: _opacityAnimation,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _controller.forward();
    setState(() => _isOpen = true);
  }

  void _close({VoidCallback? onComplete}) {
    if (!_isOpen || !mounted) return;
    _isOpen = false;
    _controller.reverse().then((_) {
      if (!mounted) {
        onComplete?.call();
        return;
      }
      _overlayEntry?.remove();
      _overlayEntry = null;
      setState(() {});
      onComplete?.call();
    });
  }

  double _calculateMenuWidth(
    BuildContext context,
    double triggerWidth,
    List<_MenuEntry<T>> entries,
  ) => _calculatePopupMenuWidth(context, triggerWidth, entries);

  @override
  Widget build(BuildContext context) {
    Widget trigger;
    if (widget.child != null) {
      trigger = InkWell(
        onTap: widget.enabled ? _toggle : null,
        borderRadius: BorderRadius.circular(8),
        child: widget.child,
      );
    } else {
      trigger = IconButton(
        icon: widget.icon ?? const Icon(Icons.more_vert),
        tooltip: widget.tooltip,
        onPressed: widget.enabled ? _toggle : null,
      );
    }

    return CompositedTransformTarget(link: _layerLink, child: trigger);
  }
}

/// A Fluent UI-style dropdown button.
///
/// The trigger looks like a bordered input box. Tapping it opens an overlay
/// menu with rounded corners, a border, and a scale + fade open animation.
/// The menu is automatically aligned to stay within the screen bounds.
class FluentDropdown<T> extends StatefulWidget {
  const FluentDropdown({
    super.key,
    required this.value,
    required this.displayValue,
    required this.items,
    required this.onChanged,
  });

  /// Currently selected value.
  final T value;

  /// Text displayed in the trigger button.
  final String displayValue;

  /// Map of selectable values to their display labels.
  final Map<T, String> items;

  /// Called when the user selects a different value.
  final ValueChanged<T>? onChanged;

  @override
  State<FluentDropdown<T>> createState() => _FluentDropdownState<T>();
}

class _FluentDropdownState<T> extends State<FluentDropdown<T>>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  // 坑：AnimationController 必须在 initState() 里立刻创建，不能懒加载。
  // 因为 OverlayEntry 的回调可能在 widget 已经被 deactivated 之后触发，
  // 如果这时第一次访问 _controller 才去创建，会尝试读取 TickerMode / MediaQuery
  // 等 InheritedWidget 祖先，触发 "Looking up a deactivated widget's ancestor is unsafe"。
  // 另外 _close / _closeImmediately 里要先判断 mounted，避免 deactivated 后操作 overlay。
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 220),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (!mounted) return;
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    final entries = widget.items.entries.map((entry) {
      return _MenuEntry<T>(
        value: entry.key,
        title: Text(entry.value),
        isSelected: entry.key == widget.value,
      );
    }).toList();

    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);
    final screenSize = MediaQuery.sizeOf(context);
    final safePadding = MediaQuery.paddingOf(context);

    final fitsBelow =
        position.dy + size.height + 8 + 200 <
        screenSize.height - safePadding.bottom;
    final fitsRight = position.dx + 220 <= screenSize.width - safePadding.right;
    final menuWidth = _calculateMenuWidth(context, size.width);

    _overlayEntry = OverlayEntry(
      builder: (context) => _MenuOverlay<T>(
        layerLink: _layerLink,
        triggerSize: size,
        menuWidth: menuWidth,
        entries: entries,
        alignRight: !fitsRight,
        alignTop: !fitsBelow,
        onSelected: (value) {
          _close(onComplete: () => widget.onChanged?.call(value));
        },
        onDismiss: _close,
        scaleAnimation: _scaleAnimation,
        opacityAnimation: _opacityAnimation,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _controller.forward();
    setState(() => _isOpen = true);
  }

  void _close({VoidCallback? onComplete}) {
    if (!_isOpen || !mounted) return;
    // 立即把状态置为关闭，避免关闭过程中重复触发 _toggle/_close。
    _isOpen = false;
    _controller.reverse().then((_) {
      // 动画期间 widget 可能被 deactivate/dispose，所以这里必须判断 mounted。
      // onComplete（即 onChanged）仍要调用：用户已经做出了选择，
      // 即使本 widget 被移除，通知父级更新状态也是安全的（不访问 context）。
      if (!mounted) {
        onComplete?.call();
        return;
      }
      _overlayEntry?.remove();
      _overlayEntry = null;
      setState(() {});
      onComplete?.call();
    });
  }

  double _calculateMenuWidth(BuildContext context, double triggerWidth) {
    final textStyle =
        Theme.of(context).textTheme.bodyMedium ??
        DefaultTextStyle.of(context).style;
    var maxItemWidth = 0.0;
    for (final label in widget.items.values) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: Directionality.of(context),
      )..layout();
      if (painter.width > maxItemWidth) {
        maxItemWidth = painter.width;
      }
    }

    // 18 (checkmark) + 16 (spacing) + 24 (item horizontal padding) + 16 (menu padding)
    final contentWidth = maxItemWidth + 18 + 16 + 24 + 16;
    return contentWidth.clamp(triggerWidth, 340.0);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = context.textColor;

    final textStyle = Theme.of(context).textTheme.bodyMedium;

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: widget.onChanged == null ? null : _toggle,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 180),
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  widget.displayValue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle?.copyWith(
                    color: textColor.withValues(alpha: 0.9),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedRotation(
                turns: _isOpen ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: textColor.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

double _calculatePopupMenuWidth<T>(
  BuildContext context,
  double triggerWidth,
  List<_MenuEntry<T>> entries,
) {
  final textStyle =
      Theme.of(context).textTheme.bodyMedium ??
      DefaultTextStyle.of(context).style;
  final textScaler = MediaQuery.textScalerOf(context);
  var maxTextWidth = 0.0;
  for (final entry in entries) {
    final text = _extractText(entry.title);
    if (text == null || text.isEmpty) continue;
    final painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: Directionality.of(context),
      textScaler: textScaler,
    )..layout();
    if (painter.width > maxTextWidth) {
      maxTextWidth = painter.width;
    }
  }

  // 兜底：如果没有任何可测量的文本，给一个默认宽度，避免菜单被压得过窄。
  if (maxTextWidth == 0.0 && entries.isNotEmpty) {
    maxTextWidth = 120.0;
  }

  // 24 (leading icon slot) / 18 (placeholder) + 12 (gap) +
  // 24 (item horizontal padding) + 16 (menu padding) + trailing slot。
  // 额外 +8 作为文本测量缓冲，防止因字体渲染差异导致折行。
  final hasLeading = entries.any((e) => e.leading != null);
  final trailingWidth = entries.any((e) => e.trailing != null) ? 28.0 : 0.0;
  final contentWidth =
      maxTextWidth + (hasLeading ? 24 : 18) + 12 + 24 + 16 + trailingWidth + 8;
  return contentWidth.clamp(triggerWidth, 340.0);
}

String? _extractText(Widget widget) {
  if (widget is Text) {
    return widget.data ?? widget.textSpan?.toPlainText();
  }
  if (widget is RichText) {
    return widget.text.toPlainText();
  }
  return null;
}

class _HoverableMenuItem extends StatefulWidget {
  const _HoverableMenuItem({
    required this.isSelected,
    required this.enabled,
    required this.onTap,
    required this.child,
  });

  final bool isSelected;
  final bool enabled;
  final VoidCallback? onTap;
  final Widget child;

  @override
  State<_HoverableMenuItem> createState() => _HoverableMenuItemState();
}

class _HoverableMenuItemState extends State<_HoverableMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: widget.enabled ? (_) => setState(() => _isHovered = true) : null,
      onExit: widget.enabled ? (_) => setState(() => _isHovered = false) : null,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                : _isHovered
                ? colorScheme.primaryContainer.withValues(alpha: 0.35)
                : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _MenuPanel<T> extends StatelessWidget {
  const _MenuPanel({
    required this.menuWidth,
    required this.entries,
    required this.onSelected,
  });

  final double menuWidth;
  final List<_MenuEntry<T>> entries;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      type: MaterialType.transparency,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: menuWidth,
        constraints: const BoxConstraints(maxHeight: 320),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.all(8),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final showCheckmark = entry.isSelected;
              return _HoverableMenuItem(
                isSelected: showCheckmark,
                enabled: entry.enabled,
                onTap: entry.enabled ? () => onSelected(entry.value) : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (entry.leading != null)
                      IconTheme(
                        data: IconTheme.of(context).copyWith(
                          color: entry.enabled
                              ? colorScheme.onSurface
                              : colorScheme.onSurface.withValues(alpha: 0.38),
                        ),
                        child: entry.leading!,
                      )
                    else
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: child,
                          );
                        },
                        child: showCheckmark
                            ? Icon(
                                Icons.check,
                                key: const ValueKey('check'),
                                size: 18,
                                color: colorScheme.primary,
                              )
                            : const SizedBox(width: 18, key: ValueKey('empty')),
                      ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: DefaultTextStyle.merge(
                        style: TextStyle(
                          color: entry.enabled
                              ? null
                              : colorScheme.onSurface.withValues(alpha: 0.38),
                        ),
                        child: entry.title,
                      ),
                    ),
                    if (entry.trailing != null) ...[
                      const SizedBox(width: 12),
                      IconTheme(
                        data: IconTheme.of(context).copyWith(
                          color: entry.enabled
                              ? colorScheme.onSurface
                              : colorScheme.onSurface.withValues(alpha: 0.38),
                        ),
                        child: entry.trailing!,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MenuOverlay<T> extends StatelessWidget {
  const _MenuOverlay({
    required this.layerLink,
    required this.triggerSize,
    required this.menuWidth,
    required this.entries,
    required this.alignRight,
    required this.alignTop,
    required this.onSelected,
    required this.onDismiss,
    required this.scaleAnimation,
    required this.opacityAnimation,
  });

  final LayerLink layerLink;
  final Size triggerSize;
  final double menuWidth;
  final List<_MenuEntry<T>> entries;
  final bool alignRight;
  final bool alignTop;
  final ValueChanged<T> onSelected;
  final VoidCallback onDismiss;
  final Animation<double> scaleAnimation;
  final Animation<double> opacityAnimation;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onDismiss,
      child: Stack(
        children: [
          CompositedTransformFollower(
            link: layerLink,
            showWhenUnlinked: false,
            offset: alignTop
                ? Offset(alignRight ? 0 : 0, -6)
                : Offset(alignRight ? 0 : 0, triggerSize.height + 6),
            targetAnchor: alignTop
                ? (alignRight ? Alignment.bottomRight : Alignment.bottomLeft)
                : (alignRight ? Alignment.topRight : Alignment.topLeft),
            followerAnchor: alignTop
                ? (alignRight ? Alignment.bottomRight : Alignment.bottomLeft)
                : (alignRight ? Alignment.topRight : Alignment.topLeft),
            child: FadeTransition(
              opacity: opacityAnimation,
              child: ScaleTransition(
                alignment: alignTop
                    ? (alignRight
                          ? Alignment.bottomRight
                          : Alignment.bottomLeft)
                    : (alignRight ? Alignment.topRight : Alignment.topLeft),
                scale: scaleAnimation,
                child: _MenuPanel(
                  menuWidth: menuWidth,
                  entries: entries,
                  onSelected: onSelected,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Static helper for showing a fluent popup menu at an arbitrary screen
/// rectangle (e.g. the widget that was long-pressed).
class FluentPopupMenu {
  const FluentPopupMenu._();

  static VoidCallback? _disposeCurrent;

  /// Shows a fluent-styled popup menu anchored to [anchor].
  ///
  /// Returns the selected value, or `null` if the menu is dismissed without
  /// a selection.
  static Future<T?> show<T>({
    required BuildContext context,
    required List<FluentPopupMenuItem<T>> items,
    required Rect anchor,
    ValueChanged<T>? onSelected,
  }) async {
    // 先关闭上一个弹出的菜单，保证右键/长按另一个项目时只会显示最新菜单。
    _disposeCurrent?.call();
    _disposeCurrent = null;

    final overlayState = Overlay.of(context);
    final completer = Completer<T?>();
    final closedCompleter = Completer<void>();

    final entries = items
        .map(
          (item) => _MenuEntry<T>(
            value: item.value,
            leading: item.leading,
            title: item.title,
            trailing: item.trailing,
            enabled: item.enabled,
          ),
        )
        .toList();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) => _PositionedMenuOverlay<T>(
        entries: entries,
        anchor: anchor,
        onSelected: (value) {
          if (!completer.isCompleted) completer.complete(value);
          onSelected?.call(value);
        },
        onDismiss: () {
          if (!completer.isCompleted) completer.complete(null);
        },
        onClosed: () {
          if (!closedCompleter.isCompleted) closedCompleter.complete();
        },
      ),
    );

    var removed = false;
    late final VoidCallback disposeCurrent;
    disposeCurrent = () {
      if (!completer.isCompleted) completer.complete(null);
      if (!closedCompleter.isCompleted) closedCompleter.complete();
      if (!removed) {
        removed = true;
        entry.remove();
      }
    };
    _disposeCurrent = disposeCurrent;

    overlayState.insert(entry);
    final result = await completer.future;
    await closedCompleter.future;
    if (_disposeCurrent == disposeCurrent) {
      _disposeCurrent = null;
    }
    if (!removed) {
      removed = true;
      entry.remove();
    }
    return result;
  }
}

class _PositionedMenuOverlay<T> extends StatefulWidget {
  const _PositionedMenuOverlay({
    required this.entries,
    required this.anchor,
    required this.onSelected,
    required this.onDismiss,
    required this.onClosed,
  });

  final List<_MenuEntry<T>> entries;
  final Rect anchor;
  final ValueChanged<T> onSelected;
  final VoidCallback onDismiss;
  final VoidCallback onClosed;

  @override
  State<_PositionedMenuOverlay<T>> createState() =>
      _PositionedMenuOverlayState<T>();
}

class _PositionedMenuOverlayState<T> extends State<_PositionedMenuOverlay<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;
  bool _closedReported = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 220),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close({VoidCallback? onComplete}) {
    _controller
        .reverse()
        .then((_) {
          if (mounted) setState(() {});
          onComplete?.call();
          if (!_closedReported) {
            _closedReported = true;
            widget.onClosed();
          }
        })
        .catchError((_) {
          // 动画被中断（例如新菜单直接替换了当前菜单）。
          if (!_closedReported) {
            _closedReported = true;
            widget.onClosed();
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final safePadding = MediaQuery.paddingOf(context);
    final menuWidth = _calculatePopupMenuWidth(
      context,
      widget.anchor.width,
      widget.entries,
    );

    final fitsBelow =
        widget.anchor.bottom + 8 + 200 < screenSize.height - safePadding.bottom;
    final fitsRight =
        widget.anchor.left + menuWidth <= screenSize.width - safePadding.right;
    final alignTop = !fitsBelow;
    final alignRight = !fitsRight;

    final dx = alignRight
        ? widget.anchor.right - menuWidth
        : widget.anchor.left;
    final dy = alignTop ? widget.anchor.top - 6 : widget.anchor.bottom + 6;

    final alignment = alignTop
        ? (alignRight ? Alignment.bottomRight : Alignment.bottomLeft)
        : (alignRight ? Alignment.topRight : Alignment.topLeft);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => _close(onComplete: widget.onDismiss),
      onLongPress: () => _close(onComplete: widget.onDismiss),
      onSecondaryTapDown: (_) => _close(onComplete: widget.onDismiss),
      child: Stack(
        children: [
          Positioned(
            left: dx.clamp(
              safePadding.left,
              (screenSize.width - safePadding.right - menuWidth).clamp(
                safePadding.left,
                double.infinity,
              ),
            ),
            top: dy.clamp(
              safePadding.top,
              (screenSize.height - safePadding.bottom - 200).clamp(
                safePadding.top,
                double.infinity,
              ),
            ),
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: ScaleTransition(
                alignment: alignment,
                scale: _scaleAnimation,
                child: _MenuPanel(
                  menuWidth: menuWidth,
                  entries: widget.entries,
                  onSelected: (value) {
                    _close(onComplete: () => widget.onSelected(value));
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
