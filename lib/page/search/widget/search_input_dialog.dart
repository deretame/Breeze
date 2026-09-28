import 'dart:async';
import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zephyr/i18n/strings.g.dart';

class SearchQueryField extends StatefulWidget {
  const SearchQueryField({
    super.key,
    required this.query,
    this.onSubmitted,
    this.onChanged,
    this.onTap,
    this.autoExpand = false,
    this.hintText,
    this.semanticLabel,
    this.focusNode,
    this.closeOnSubmit = true,
  });

  final String query;
  final FutureOr<void> Function(String query)? onSubmitted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool autoExpand;
  final String? hintText;
  final String? semanticLabel;

  /// 外部传入的焦点节点。提供后父级可主动聚焦/失焦（如弹窗关闭后恢复键盘）；
  /// 不提供则内部自建自管。
  final FocusNode? focusNode;

  /// 提交（回车）后是否收起浮层。搜索页保持默认 true；
  /// 书架这种希望回车后继续改词的场景传 false。
  final bool closeOnSubmit;

  @override
  State<SearchQueryField> createState() => _SearchQueryFieldState();
}

class _SearchQueryFieldState extends State<SearchQueryField>
    with WidgetsBindingObserver, AutoRouteAwareStateMixin<SearchQueryField> {
  final _targetKey = GlobalKey();
  late final TextEditingController _controller;
  FocusNode? _internalFocusNode;

  /// 外部节点优先，兼顾节点替换：widget.focusNode 变化时下次访问自动切换，
  /// 内部节点只在真正使用过时才创建、dispose 时只释放内部节点。
  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());
  OverlayEntry? _overlayEntry;
  OverlayState? _overlayState;
  Timer? _autoExpandFallbackTimer;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = TextEditingController(text: widget.query);
    if (widget.autoExpand) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _prepareAutoExpand();
      });
    }
  }

  /// AutoRouteAwareStateMixin.didChangeDependencies 在没有 RouterScope
  ///（如 widget test 里裸 pump）时会抛 RouterScope 断言。
  /// 正常路由栈下照常订阅；裸测只跳过订阅，展开/收起逻辑不受影响。
  @override
  void didChangeDependencies() {
    try {
      super.didChangeDependencies();
    } on FlutterError catch (e) {
      if (!e.message.contains('RouterScope')) {
        rethrow;
      }
    }
  }

  @override
  void didUpdateWidget(covariant SearchQueryField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isExpanded && oldWidget.query != widget.query) {
      _setControllerText(widget.query);
    }
    if (!oldWidget.autoExpand && widget.autoExpand) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _prepareAutoExpand();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelPendingExpand();
    _removeOverlay();
    _controller.dispose();
    _internalFocusNode?.dispose();
    _internalFocusNode = null;
    super.dispose();
  }

  void _setControllerText(String value) {
    if (_controller.text == value) {
      return;
    }
    _controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  Animation<double>? _routeAnimation;
  AnimationStatusListener? _routeAnimationListener;

  void _cancelPendingExpand() {
    _autoExpandFallbackTimer?.cancel();
    _autoExpandFallbackTimer = null;
    if (_routeAnimation != null && _routeAnimationListener != null) {
      _routeAnimation!.removeStatusListener(_routeAnimationListener!);
      _routeAnimation = null;
      _routeAnimationListener = null;
    }
  }

  void _prepareAutoExpand() {
    if (!mounted || !widget.autoExpand || widget.onTap != null || _isExpanded) {
      return;
    }
    final route = ModalRoute.of(context);
    final animation = route is PageRoute ? route.animation : null;
    if (animation == null || animation.isCompleted) {
      _openOverlayWhenReady();
      return;
    }

    _routeAnimation = animation;
    _routeAnimationListener = (status) {
      if (status != AnimationStatus.completed || !mounted) {
        return;
      }
      animation.removeStatusListener(_routeAnimationListener!);
      _routeAnimation = null;
      _routeAnimationListener = null;
      _openOverlayWhenReady();
    };
    animation.addStatusListener(_routeAnimationListener!);

    // A route can finish between the isCompleted check and addStatusListener.
    // Keep the original post-transition behavior, but do not leave the field
    // collapsed if that status change was missed by the listener.
    _autoExpandFallbackTimer = Timer(const Duration(milliseconds: 600), () {
      if (!mounted || _isExpanded) {
        return;
      }
      animation.removeStatusListener(_routeAnimationListener!);
      _routeAnimation = null;
      _routeAnimationListener = null;
      _openOverlayWhenReady();
    });
  }

  @override
  void didPushNext() {
    super.didPushNext();
    // 本页被盖住：只收视觉浮层，不向父级回写（提交已写过 cubit，
    // 回写只会把残留旧词经防抖盖掉新词）。
    _cancelPendingExpand();
    _hideOverlay();
  }

  @override
  void didPop() {
    super.didPop();
    // 本页自己被 pop（如搜索页返回键）：收起 rootOverlay 上的浮层。
    // 不手动关，输入框会悬在上一页上层（dispose 要等转场结束才跑）。
    _cancelPendingExpand();
    _hideOverlay();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    if (!widget.autoExpand) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prepareAutoExpand();
    });
  }

  void _openOverlayWhenReady() {
    if (!mounted || _isExpanded) {
      return;
    }
    if (_targetRenderBox == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openOverlayWhenReady();
      });
      return;
    }
    _autoExpandFallbackTimer?.cancel();
    _autoExpandFallbackTimer = null;
    _openOverlay();
  }

  void _openOverlay() {
    if (_isExpanded) {
      return;
    }
    // 点框重开浮层时以外部 query 对齐：展开期间 didUpdateWidget 故意不同步
    // controller，点历史等方式提交后 controller 会落后；重开时补对齐一次。
    // 初次 autoExpand 是 no-op。
    _setControllerText(widget.query);
    _overlayState = Overlay.of(context, rootOverlay: true);
    setState(() {
      _isExpanded = true;
    });
    _overlayEntry = OverlayEntry(builder: _buildOverlay);
    _overlayState!.insert(_overlayEntry!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isExpanded) {
        _focusNode.requestFocus();
      }
    });
  }

  void _removeOverlay() {
    _focusNode.unfocus();
    _overlayEntry?.remove();
    _overlayEntry = null;
    _overlayState = null;
    _isExpanded = false;
  }

  /// 只收视觉浮层，不向父级回写。路由切换（didPushNext/didPop）用：
  /// 提交已在 push 前把 cubit 写成新词，回写只会把残留旧词排上防抖、
  /// 返回后盖掉新词。
  void _hideOverlay() {
    if (!_isExpanded) {
      return;
    }
    _removeOverlay();
    if (mounted) {
      setState(() {});
    }
  }

  RenderBox? get _targetRenderBox {
    final renderObject = _targetKey.currentContext?.findRenderObject();
    if (renderObject is RenderBox && renderObject.hasSize) {
      return renderObject;
    }
    return null;
  }

  @override
  void didChangeMetrics() {
    _overlayEntry?.markNeedsBuild();
  }

  Widget _buildOverlay(BuildContext context) {
    final target = _targetRenderBox;
    final overlayRenderObject = _overlayState?.context.findRenderObject();
    if (target == null ||
        overlayRenderObject is! RenderBox ||
        !overlayRenderObject.hasSize) {
      return const SizedBox.shrink();
    }

    final targetOffset =
        target.localToGlobal(Offset.zero) -
        overlayRenderObject.localToGlobal(Offset.zero);
    final overlaySize = overlayRenderObject.size;
    final maxLeft = math.max(8.0, overlaySize.width - 8.0);
    final left = targetOffset.dx.clamp(8.0, maxLeft).toDouble();
    final width = math.max(
      1.0,
      math.min(target.size.width, overlaySize.width - left - 8.0),
    );
    final top = targetOffset.dy.clamp(0.0, overlaySize.height).toDouble();
    final maxHeight = math.max(1.0, overlaySize.height - top - 8.0);

    return Positioned(
      left: left,
      top: top,
      width: width,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          clipBehavior: Clip.none,
          child: _buildExpandedField(context),
        ),
      ),
    );
  }

  void _closeOverlay() {
    if (!_isExpanded) {
      return;
    }
    widget.onChanged?.call(_controller.text);
    _removeOverlay();
    if (mounted) {
      setState(() {});
    }
  }

  /// 用户主动关浮层（点 ×/关闭、点外部）：同时取消待触发的 autoExpand，
  /// 否则 600ms 兜底定时器会在路由动画后把浮层又弹出来。
  void _dismissOverlay() {
    _cancelPendingExpand();
    _closeOverlay();
  }

  void _submit() {
    final query = _controller.text;
    _cancelPendingExpand();
    if (widget.closeOnSubmit) {
      _removeOverlay();
      if (mounted) {
        setState(() {});
      }
    } else {
      // 保持展开：只刷新浮层内的清空/关闭按钮状态，焦点不动，键盘不收。
      _overlayEntry?.markNeedsBuild();
    }
    widget.onSubmitted?.call(query);
  }

  void _clear() {
    if (_controller.text.isEmpty) {
      return;
    }
    _controller.clear();
    // 清空也是关键词变化，同步给父级，否则列表还按旧词过滤。
    widget.onChanged?.call('');
    _overlayEntry?.markNeedsBuild();
  }

  Widget _buildCollapsedField(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEmpty = widget.query.isEmpty;

    return Semantics(
      button: true,
      label: widget.semanticLabel ?? widget.hintText ?? t.search.title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap ?? _openOverlay,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: isEmpty
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.onSurface,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isEmpty ? (widget.hintText ?? '') : widget.query,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      color: isEmpty
                          ? colorScheme.onSurfaceVariant.withValues(alpha: 0.7)
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedField(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasText = _controller.text.isNotEmpty;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) => Align(
        alignment: Alignment.topCenter,
        heightFactor: value,
        child: child,
      ),
      child: TapRegion(
        onTapOutside: (_) => _dismissOverlay(),
        child: Material(
          color: colorScheme.surfaceContainerHighest,
          elevation: 3,
          shadowColor: colorScheme.shadow.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.only(left: 14, right: 6),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        autofocus: true,
                        // 多行展示 + 回车即搜：keyboardType 必须用 text，不能用 multiline。
                        // multiline 会让 Android IME 直接忽略 textInputAction.search、
                        // 把回车当换行（且各家输入法行为不一致），这就是 a45ae20 回退单行的原因；
                        // 但单行只能显示一行，长词只能左右滚，展示需求就没了。
                        // text + maxLines 6：engine 下发 inputType=TYPE_CLASS_TEXT
                        // （无 MULTILINE flag）+ imeOptions=actionSearch，
                        // 软键盘回车即 search（桌面端硬件回车同样走 performAction）；
                        // 长文本靠软换行撑到最多 6 行展示，singleLineFormatter 只拦硬换行
                        // （粘贴带 \n 时），不影响软换行。
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.search,
                        minLines: 1,
                        maxLines: 6,
                        inputFormatters: [
                          FilteringTextInputFormatter.singleLineFormatter,
                        ],
                        textAlignVertical: TextAlignVertical.center,
                        onChanged: (value) {
                          widget.onChanged?.call(value);
                          _overlayEntry?.markNeedsBuild();
                        },
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          hintText: widget.hintText ?? t.search.searchHint,
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          hintStyle: TextStyle(
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: hasText ? t.common.clear : t.common.close,
                      visualDensity: VisualDensity.compact,
                      icon: Icon(hasText ? Icons.clear : Icons.close),
                      onPressed: hasText ? _clear : _dismissOverlay,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(key: _targetKey, child: _buildCollapsedField(context));
  }
}

@Preview(name: 'Search query field', group: 'Search')
Widget searchQueryFieldPreview() {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SearchQueryField(
            query: 'parody.chou kag...',
            hintText: 'Search...',
            onSubmitted: _previewNoop,
          ),
        ),
      ),
    ),
  );
}

void _previewNoop(String _) {}
