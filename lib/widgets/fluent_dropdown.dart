import 'package:flutter/material.dart';
import 'package:zephyr/util/context/context_extensions.dart';

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
      builder: (context) => _DropdownOverlay<T>(
        layerLink: _layerLink,
        triggerSize: size,
        menuWidth: menuWidth,
        value: widget.value,
        items: widget.items,
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

class _DropdownOverlay<T> extends StatelessWidget {
  const _DropdownOverlay({
    required this.layerLink,
    required this.triggerSize,
    required this.menuWidth,
    required this.value,
    required this.items,
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
  final T value;
  final Map<T, String> items;
  final bool alignRight;
  final bool alignTop;
  final ValueChanged<T> onSelected;
  final VoidCallback onDismiss;
  final Animation<double> scaleAnimation;
  final Animation<double> opacityAnimation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final entry = items.entries.elementAt(index);
                        final isSelected = entry.key == value;
                        return GestureDetector(
                          onTap: () => onSelected(entry.key),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primaryContainer.withValues(
                                      alpha: 0.5,
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 180),
                                  transitionBuilder: (child, animation) {
                                    return ScaleTransition(
                                      scale: animation,
                                      child: child,
                                    );
                                  },
                                  child: isSelected
                                      ? Icon(
                                          Icons.check,
                                          key: const ValueKey('check'),
                                          size: 18,
                                          color: colorScheme.primary,
                                        )
                                      : const SizedBox(
                                          width: 18,
                                          key: ValueKey('empty'),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Text(
                                    entry.value,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
