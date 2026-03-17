export 'package:easy_refresh/easy_refresh.dart' show EasyRefresh, ClassicHeader;
export 'package:fluent_ui/fluent_ui.dart'
    hide Card, Checkbox, Divider, IconButton, ListTile, OutlinedButton, Slider;
export 'package:flutter/animation.dart' show AlwaysStoppedAnimation;
export 'package:flutter/material.dart' show VisualDensity, TextInputAction;
export 'package:flutter/services.dart';
export 'divider_compat.dart';

import 'dart:math' as math;

import 'package:easy_refresh/easy_refresh.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:flutter/material.dart' show VisualDensity, TextInputAction;
import 'package:flutter/services.dart' show TextInputFormatter;
import 'package:flutter/widgets.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/widgets/toast.dart';

// Re-export showDialog from fluent_ui
Future<T?> showDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return f.showDialog<T>(
    context: context,
    builder: builder,
    barrierDismissible: barrierDismissible,
  );
}

Future<DateTime?> showDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  DateTime? selectedDate = initialDate;

  final result = await f.showDialog<DateTime>(
    context: context,
    builder: (ctx) {
      return f.ContentDialog(
        title: const Text('选择日期'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: f.DatePicker(
            selected: initialDate,
            onChanged: (date) {
              selectedDate = date;
            },
          ),
        ),
        actions: [
          f.Button(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          f.FilledButton(
            onPressed: () => Navigator.pop(ctx, selectedDate),
            child: const Text('确定'),
          ),
        ],
      );
    },
  );

  return result;
}

class Dialog extends StatelessWidget {
  const Dialog({
    super.key,
    this.child,
    this.backgroundColor,
    this.shape,
  });

  final Widget? child;
  final Color? backgroundColor;
  final ShapeBorder? shape;

  @override
  Widget build(BuildContext context) {
    final theme = f.FluentTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.micaBackgroundColor,
        borderRadius: shape is RoundedRectangleBorder
            ? (shape as RoundedRectangleBorder).borderRadius
            : BorderRadius.circular(8),
        border: shape is RoundedRectangleBorder
            ? (shape as RoundedRectangleBorder).side != BorderSide.none
                ? Border.fromBorderSide((shape as RoundedRectangleBorder).side)
                : null
            : null,
      ),
      child: child,
    );
  }
}

class SimpleDialogOption extends StatelessWidget {
  const SimpleDialogOption({
    super.key,
    this.onPressed,
    this.child,
  });

  final VoidCallback? onPressed;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return f.Button(
      onPressed: onPressed,
      child: child ?? const SizedBox.shrink(),
    );
  }
}

class SimpleDialog extends StatelessWidget {
  const SimpleDialog({
    super.key,
    this.title,
    this.children,
  });

  final Widget? title;
  final List<Widget>? children;

  @override
  Widget build(BuildContext context) {
    return f.ContentDialog(
      title: title,
      content: children != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: children!,
            )
          : null,
    );
  }
}

typedef ColorScheme = AppColorScheme;
typedef ThemeData = AppThemeData;
typedef TextTheme = AppTextTheme;
typedef PopupMenuEntry<T> = PopupMenuItem<T>;

const double kMinInteractiveDimension = 48.0;

enum MaterialTapTargetSize { padded, shrinkWrap }

enum ShowValueIndicator { never }

class RoundSliderThumbShape {
  const RoundSliderThumbShape({this.enabledThumbRadius = 8});

  final double enabledThumbRadius;
}

class RoundSliderOverlayShape {
  const RoundSliderOverlayShape({this.overlayRadius = 14});

  final double overlayRadius;
}

class SliderThemeData {
  const SliderThemeData({
    this.trackHeight,
    this.thumbShape,
    this.overlayShape,
    this.activeTrackColor,
    this.inactiveTrackColor,
    this.thumbColor,
    this.overlayColor,
    this.showValueIndicator,
  });

  final double? trackHeight;
  final RoundSliderThumbShape? thumbShape;
  final RoundSliderOverlayShape? overlayShape;
  final Color? activeTrackColor;
  final Color? inactiveTrackColor;
  final Color? thumbColor;
  final Color? overlayColor;
  final ShowValueIndicator? showValueIndicator;

  SliderThemeData copyWith({
    double? trackHeight,
    RoundSliderThumbShape? thumbShape,
    RoundSliderOverlayShape? overlayShape,
    Color? activeTrackColor,
    Color? inactiveTrackColor,
    Color? thumbColor,
    Color? overlayColor,
    ShowValueIndicator? showValueIndicator,
  }) {
    return SliderThemeData(
      trackHeight: trackHeight ?? this.trackHeight,
      thumbShape: thumbShape ?? this.thumbShape,
      overlayShape: overlayShape ?? this.overlayShape,
      activeTrackColor: activeTrackColor ?? this.activeTrackColor,
      inactiveTrackColor: inactiveTrackColor ?? this.inactiveTrackColor,
      thumbColor: thumbColor ?? this.thumbColor,
      overlayColor: overlayColor ?? this.overlayColor,
      showValueIndicator: showValueIndicator ?? this.showValueIndicator,
    );
  }
}

class SliderTheme extends StatelessWidget {
  const SliderTheme({super.key, required this.data, required this.child});

  final SliderThemeData data;
  final Widget child;

  static SliderThemeData of(BuildContext context) {
    final inherited = context
        .dependOnInheritedWidgetOfExactType<_SliderThemeScope>();
    return inherited?.data ?? const SliderThemeData();
  }

  @override
  Widget build(BuildContext context) {
    return _SliderThemeScope(data: data, child: child);
  }
}

class _SliderThemeScope extends InheritedWidget {
  const _SliderThemeScope({required this.data, required super.child});

  final SliderThemeData data;

  @override
  bool updateShouldNotify(covariant _SliderThemeScope oldWidget) {
    return oldWidget.data != data;
  }
}

class Theme extends StatelessWidget {
  const Theme({super.key, required this.data, required this.child});

  final ThemeData data;
  final Widget child;

  static ThemeData of(BuildContext context) {
    final inherited = context.dependOnInheritedWidgetOfExactType<_ThemeScope>();
    if (inherited != null) {
      return inherited.data;
    }
    return AppThemeData(f.FluentTheme.of(context));
  }

  @override
  Widget build(BuildContext context) {
    return _ThemeScope(data: data, child: child);
  }
}

class _ThemeScope extends InheritedTheme {
  const _ThemeScope({required this.data, required super.child});

  final ThemeData data;

  @override
  bool updateShouldNotify(covariant _ThemeScope oldWidget) {
    return oldWidget.data != data;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return _ThemeScope(data: data, child: child);
  }
}

class SnackBar {
  const SnackBar({required this.content});

  final Widget content;
}

class ScaffoldMessenger {
  const ScaffoldMessenger._(this.context);

  final BuildContext context;

  static ScaffoldMessenger of(BuildContext context) {
    return ScaffoldMessenger._(context);
  }

  void showSnackBar(SnackBar snackBar) {
    String message = '';
    if (snackBar.content is Text) {
      message = (snackBar.content as Text).data ?? '';
    } else {
      message = snackBar.content.toStringShort();
    }
    showInfoToast(message, context: context);
  }
}

class Drawer extends StatelessWidget {
  const Drawer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = math.min(MediaQuery.of(context).size.width * 0.92, 380.0);
    final theme = f.FluentTheme.of(context);
    return Container(
      width: width,
      color: theme.micaBackgroundColor,
      child: child,
    );
  }
}

class Scaffold extends StatefulWidget {
  const Scaffold({
    super.key,
    this.appBar,
    this.body,
    this.endDrawer,
    this.floatingActionButton,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.extendBodyBehindAppBar = false,
    this.bottomNavigationBar,
  });

  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? endDrawer;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool extendBodyBehindAppBar;
  final Widget? bottomNavigationBar;

  static ScaffoldState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_ScaffoldScope>();
    assert(scope != null, 'No Scaffold ancestor found in context.');
    return scope!.state;
  }

  @override
  State<Scaffold> createState() => ScaffoldState();
}

class ScaffoldState extends State<Scaffold> {
  bool _isEndDrawerOpen = false;

  void openEndDrawer() {
    if (widget.endDrawer == null) return;
    setState(() => _isEndDrawerOpen = true);
  }

  void closeEndDrawer() {
    if (_isEndDrawerOpen) {
      setState(() => _isEndDrawerOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = f.FluentTheme.of(context);
    final backgroundColor =
        widget.backgroundColor ?? theme.scaffoldBackgroundColor;

    Widget content = Column(
      children: [
        if (widget.appBar != null) widget.appBar!,
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: widget.resizeToAvoidBottomInset
                  ? MediaQuery.viewInsetsOf(context).bottom
                  : 0,
            ),
            child: widget.body ?? const SizedBox.shrink(),
          ),
        ),
        if (widget.bottomNavigationBar != null) widget.bottomNavigationBar!,
      ],
    );

    content = ColoredBox(color: backgroundColor, child: content);

    return _ScaffoldScope(
      state: this,
      child: Stack(
        children: [
          content,
          if (widget.floatingActionButton != null)
            PositionedDirectional(
              end: 16,
              bottom: 16 + MediaQuery.paddingOf(context).bottom,
              child: widget.floatingActionButton!,
            ),
          if (_isEndDrawerOpen && widget.endDrawer != null) ...[
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: closeEndDrawer,
                child: Container(color: f.Colors.black.withValues(alpha: 0.18)),
              ),
            ),
            PositionedDirectional(
              end: 0,
              top: 0,
              bottom: 0,
              child: widget.endDrawer!,
            ),
          ],
        ],
      ),
    );
  }
}

class _ScaffoldScope extends InheritedWidget {
  const _ScaffoldScope({required this.state, required super.child});

  final ScaffoldState state;

  @override
  bool updateShouldNotify(covariant _ScaffoldScope oldWidget) {
    return oldWidget.state != state;
  }
}

class MaterialScrollBehavior extends f.FluentScrollBehavior {
  const MaterialScrollBehavior();
}

class MaterialApp extends StatelessWidget {
  const MaterialApp({super.key, this.title = '', this.home});

  final String title;
  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return f.FluentApp(title: title, home: home);
  }
}

class AppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.bottom,
    this.backgroundColor,
    this.elevation,
    this.scrolledUnderElevation,
    this.titleSpacing = 16,
    this.toolbarHeight,
    this.automaticallyImplyLeading = true,
    this.centerTitle = false,
    this.surfaceTintColor,
    this.shadowColor,
    this.shape,
  });

  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Color? backgroundColor;
  final double? elevation;
  final double? scrolledUnderElevation;
  final double titleSpacing;
  final double? toolbarHeight;
  final bool automaticallyImplyLeading;
  final bool centerTitle;
  final Color? surfaceTintColor;
  final Color? shadowColor;
  final ShapeBorder? shape;

  @override
  Size get preferredSize => Size.fromHeight(
    (toolbarHeight ?? 56) + (bottom?.preferredSize.height ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    final theme = f.FluentTheme.of(context);
    final canPop = Navigator.of(context).canPop();
    final resolvedLeading =
        leading ??
        (automaticallyImplyLeading && canPop ? const BackButton() : null);

    Widget? titleWidget = title;
    if (titleWidget != null && centerTitle) {
      titleWidget = Center(child: titleWidget);
    }

    BorderRadiusGeometry? borderRadius;
    if (shape is RoundedRectangleBorder) {
      borderRadius = (shape as RoundedRectangleBorder).borderRadius;
    }

    final bar = Container(
      height: toolbarHeight ?? 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.scaffoldBackgroundColor,
        borderRadius: borderRadius,
        boxShadow: elevation != null && elevation! > 0
            ? [
                BoxShadow(
                  color: (shadowColor ?? f.Colors.black).withValues(alpha: 0.2),
                  blurRadius: elevation! * 2,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          if (resolvedLeading != null) resolvedLeading,
          if (!centerTitle) SizedBox(width: titleSpacing),
          if (titleWidget != null) Expanded(child: titleWidget),
          if (actions != null) ...actions!,
        ],
      ),
    );

    if (bottom == null) return bar;

    return Column(mainAxisSize: MainAxisSize.min, children: [bar, bottom!]);
  }
}

class BackButton extends StatelessWidget {
  const BackButton({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return f.IconButton(
      icon: Icon(Icons.arrow_back, color: color),
      onPressed: () => Navigator.of(context).maybePop(),
    );
  }
}

class Card extends StatelessWidget {
  const Card({
    super.key,
    required this.child,
    this.margin,
    this.color,
    this.elevation,
    this.shadowColor,
    this.shape,
    this.surfaceTintColor,
    this.clipBehavior,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? elevation;
  final Color? shadowColor;
  final ShapeBorder? shape;
  final Color? surfaceTintColor;
  final Clip? clipBehavior;

  @override
  Widget build(BuildContext context) {
    BorderRadiusGeometry borderRadius = const BorderRadius.all(
      Radius.circular(12),
    );
    Color? borderColor;
    if (shape is RoundedRectangleBorder) {
      final rounded = shape! as RoundedRectangleBorder;
      borderRadius = rounded.borderRadius;
      borderColor = rounded.side.color;
    }

    return Container(
      margin: margin,
      clipBehavior: clipBehavior ?? Clip.none,
      decoration: BoxDecoration(
        color: color ?? f.FluentTheme.of(context).cardColor,
        borderRadius: borderRadius,
        border: borderColor == null ? null : Border.all(color: borderColor),
        boxShadow: elevation == null || elevation == 0
            ? null
            : [
                BoxShadow(
                  color: (shadowColor ?? f.Colors.black).withValues(
                    alpha: 0.12,
                  ),
                  blurRadius: elevation! * 2,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: child,
    );
  }
}

class Material extends StatelessWidget {
  const Material({
    super.key,
    this.color,
    this.elevation = 0,
    this.shadowColor,
    this.borderRadius,
    this.clipBehavior = Clip.none,
    this.shape,
    required this.child,
  });

  final Color? color;
  final double elevation;
  final Color? shadowColor;
  final BorderRadiusGeometry? borderRadius;
  final Clip clipBehavior;
  final ShapeBorder? shape;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    BorderRadiusGeometry radius =
        borderRadius ?? const BorderRadius.all(Radius.circular(8));
    if (shape is RoundedRectangleBorder) {
      radius = (shape! as RoundedRectangleBorder).borderRadius;
    }
    return ClipRRect(
      borderRadius: radius,
      clipBehavior: clipBehavior,
      child: Container(
        decoration: BoxDecoration(
          color: color ?? f.Colors.transparent,
          borderRadius: radius,
          boxShadow: elevation <= 0
              ? null
              : [
                  BoxShadow(
                    color: (shadowColor ?? f.Colors.black).withValues(
                      alpha: 0.16,
                    ),
                    blurRadius: elevation * 2,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: child,
      ),
    );
  }
}

class InkWell extends StatelessWidget {
  const InkWell({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: child,
      ),
    );
  }
}

class TextButton extends StatelessWidget {
  const TextButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.style,
  });

  factory TextButton.icon({
    Key? key,
    required Widget icon,
    required Widget label,
    required VoidCallback? onPressed,
    f.ButtonStyle? style,
  }) {
    return TextButton(
      key: key,
      onPressed: onPressed,
      style: style,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [icon, const SizedBox(width: 8), label],
      ),
    );
  }

  final Widget child;
  final VoidCallback? onPressed;
  final f.ButtonStyle? style;

  static f.ButtonStyle styleFrom({
    Color? foregroundColor,
    Color? backgroundColor,
    EdgeInsetsGeometry? padding,
    BorderSide? side,
    OutlinedBorder? shape,
    TextStyle? textStyle,
    Size? minimumSize,
  }) {
    return f.ButtonStyle(
      padding: padding == null ? null : f.WidgetStatePropertyAll(padding),
      foregroundColor: foregroundColor == null
          ? null
          : f.WidgetStatePropertyAll(foregroundColor),
      backgroundColor: backgroundColor == null
          ? null
          : f.WidgetStatePropertyAll(backgroundColor),
      textStyle: textStyle == null ? null : f.WidgetStatePropertyAll(textStyle),
      shape: (side == null && shape == null)
          ? null
          : f.WidgetStatePropertyAll(
              shape ??
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: side ?? BorderSide.none,
                  ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return f.Button(
      style:
          style ??
          const f.ButtonStyle(
            backgroundColor: f.WidgetStatePropertyAll(f.Colors.transparent),
            shadowColor: f.WidgetStatePropertyAll(f.Colors.transparent),
          ),
      onPressed: onPressed,
      child: child,
    );
  }
}

class ElevatedButton extends StatelessWidget {
  const ElevatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
  });

  factory ElevatedButton.icon({
    Key? key,
    required Widget icon,
    required Widget label,
    required VoidCallback? onPressed,
    f.ButtonStyle? style,
  }) {
    return ElevatedButton(
      key: key,
      onPressed: onPressed,
      style: style,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [icon, const SizedBox(width: 8), label],
      ),
    );
  }

  final VoidCallback? onPressed;
  final Widget child;
  final f.ButtonStyle? style;

  static f.ButtonStyle styleFrom({
    Color? foregroundColor,
    Color? backgroundColor,
    EdgeInsetsGeometry? padding,
    BorderSide? side,
    OutlinedBorder? shape,
    TextStyle? textStyle,
    Size? minimumSize,
  }) {
    return f.ButtonStyle(
      padding: padding == null ? null : f.WidgetStatePropertyAll(padding),
      foregroundColor: foregroundColor == null
          ? null
          : f.WidgetStatePropertyAll(foregroundColor),
      backgroundColor: backgroundColor == null
          ? null
          : f.WidgetStatePropertyAll(backgroundColor),
      textStyle: textStyle == null ? null : f.WidgetStatePropertyAll(textStyle),
      shape: (side == null && shape == null)
          ? null
          : f.WidgetStatePropertyAll(
              shape ??
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: side ?? BorderSide.none,
                  ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return f.FilledButton(style: style, onPressed: onPressed, child: child);
  }
}

// FilledButton is an alias for ElevatedButton in Material Design
typedef FilledButton = ElevatedButton;

class OutlinedButton extends StatelessWidget {
  const OutlinedButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.style,
  });

  factory OutlinedButton.icon({
    Key? key,
    required Widget icon,
    required Widget label,
    required VoidCallback? onPressed,
    f.ButtonStyle? style,
  }) {
    return OutlinedButton(
      key: key,
      style: style,
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [icon, const SizedBox(width: 8), label],
      ),
    );
  }

  final Widget child;
  final VoidCallback? onPressed;
  final f.ButtonStyle? style;

  static f.ButtonStyle styleFrom({
    Color? foregroundColor,
    Color? backgroundColor,
    EdgeInsetsGeometry? padding,
    BorderSide? side,
    OutlinedBorder? shape,
    TextStyle? textStyle,
    Size? minimumSize,
  }) {
    return f.ButtonStyle(
      padding: padding == null ? null : f.WidgetStatePropertyAll(padding),
      foregroundColor: foregroundColor == null
          ? null
          : f.WidgetStatePropertyAll(foregroundColor),
      backgroundColor: backgroundColor == null
          ? null
          : f.WidgetStatePropertyAll(backgroundColor),
      textStyle: textStyle == null ? null : f.WidgetStatePropertyAll(textStyle),
      shape: (side == null && shape == null)
          ? null
          : f.WidgetStatePropertyAll(
              shape ??
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: side ?? BorderSide.none,
                  ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return f.OutlinedButton(style: style, onPressed: onPressed, child: child);
  }
}

class FloatingActionButton extends StatelessWidget {
  const FloatingActionButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.heroTag,
    this.tooltip,
  });

  factory FloatingActionButton.small({
    Key? key,
    required VoidCallback? onPressed,
    required Widget child,
    Color? backgroundColor,
    Object? heroTag,
    String? tooltip,
  }) {
    return FloatingActionButton(
      key: key,
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      heroTag: heroTag,
      tooltip: tooltip,
      child: SizedBox(width: 18, height: 18, child: Center(child: child)),
    );
  }

  factory FloatingActionButton.extended({
    Key? key,
    required VoidCallback? onPressed,
    Widget? icon,
    required Widget label,
    Color? backgroundColor,
    Object? heroTag,
    String? tooltip,
  }) {
    return FloatingActionButton(
      key: key,
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      heroTag: heroTag,
      tooltip: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon, const SizedBox(width: 8)],
          label,
        ],
      ),
    );
  }

  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Object? heroTag;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = f.FluentTheme.of(context);
    return f.FilledButton(
      style: f.ButtonStyle(
        padding: const f.WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        backgroundColor: f.WidgetStatePropertyAll(
          backgroundColor ??
              theme.accentColor.defaultBrushFor(theme.brightness),
        ),
        shape: f.WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
      ),
      onPressed: onPressed,
      child: child,
    );
  }
}

class IconButton extends StatelessWidget {
  const IconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.style,
    this.color,
    this.visualDensity,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final f.ButtonStyle? style;
  final Color? color;
  final VisualDensity? visualDensity;

  static f.ButtonStyle styleFrom({
    Color? foregroundColor,
    Color? backgroundColor,
    EdgeInsetsGeometry? padding,
    BorderSide? side,
    OutlinedBorder? shape,
    Size? fixedSize,
    Color? disabledForegroundColor,
    Color? disabledBackgroundColor,
  }) {
    return f.ButtonStyle(
      padding: padding == null ? null : f.WidgetStatePropertyAll(padding),
      foregroundColor: foregroundColor == null
          ? null
          : f.WidgetStatePropertyAll(foregroundColor),
      backgroundColor: backgroundColor == null
          ? null
          : f.WidgetStatePropertyAll(backgroundColor),
      shape: (side == null && shape == null)
          ? null
          : f.WidgetStatePropertyAll(
              shape ??
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: side ?? BorderSide.none,
                  ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return f.IconButton(
      icon: icon,
      onPressed: onPressed,
      style: style,
    );
  }
}

class InputBorder {
  const InputBorder();

  static const none = InputBorder();
}

class OutlineInputBorder extends InputBorder {
  const OutlineInputBorder({this.borderRadius = BorderRadius.zero});

  final BorderRadius borderRadius;
}

class InputDecoration {
  const InputDecoration({
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.filled = false,
    this.fillColor,
    this.border,
    this.isDense,
    this.hintStyle,
    this.contentPadding,
    this.helperText,
  });

  final String? labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool filled;
  final Color? fillColor;
  final InputBorder? border;
  final bool? isDense;
  final TextStyle? hintStyle;
  final EdgeInsetsGeometry? contentPadding;
  final String? helperText;
}

class TextField extends StatelessWidget {
  const TextField({
    super.key,
    this.controller,
    this.focusNode,
    this.keyboardType,
    this.inputFormatters,
    this.decoration,
    this.obscureText = false,
    this.onSubmitted,
    this.onChanged,
    this.style,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.textInputAction,
    this.readOnly = false,
    this.enabled = true,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final InputDecoration? decoration;
  final bool obscureText;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final TextStyle? style;
  final int? maxLines;
  final int? minLines;
  final bool expands;
  final TextInputAction? textInputAction;
  final bool readOnly;
  final bool enabled;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final effectiveDecoration = decoration;
    final textBox = f.TextBox(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      placeholder: effectiveDecoration?.hintText,
      placeholderStyle: effectiveDecoration?.hintStyle,
      prefix: effectiveDecoration?.prefixIcon,
      suffix: effectiveDecoration?.suffixIcon,
      obscureText: obscureText,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      style: style,
      maxLines: maxLines,
      minLines: minLines,
      expands: expands,
      textInputAction: textInputAction,
      readOnly: readOnly || !enabled,
      autofocus: autofocus,
    );

    Widget result = textBox;

    if (effectiveDecoration?.filled == true ||
        effectiveDecoration?.fillColor != null) {
      result = Container(
        padding:
            effectiveDecoration?.contentPadding ??
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color:
              effectiveDecoration?.fillColor ??
              f.FluentTheme.of(context).cardColor,
          borderRadius: effectiveDecoration?.border is OutlineInputBorder
              ? (effectiveDecoration!.border as OutlineInputBorder).borderRadius
              : BorderRadius.circular(8),
        ),
        child: result,
      );
    }

    if (effectiveDecoration?.labelText != null &&
        effectiveDecoration?.hintText == null) {
      result = f.InfoLabel(
        label: effectiveDecoration!.labelText!,
        child: result,
      );
    }

    return result;
  }
}

class ListTile extends StatelessWidget {
  const ListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.contentPadding,
    this.selected = false,
    this.enabled = true,
    this.tileColor,
    this.shape,
    this.dense = false,
    this.textColor,
    this.iconColor,
    this.visualDensity,
  });

  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? contentPadding;
  final bool selected;
  final bool enabled;
  final Color? tileColor;
  final ShapeBorder? shape;
  final bool dense;
  final Color? textColor;
  final Color? iconColor;
  final VisualDensity? visualDensity;

  @override
  Widget build(BuildContext context) {
    final padding =
        contentPadding ??
        (dense
            ? const EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 2)
            : const EdgeInsetsDirectional.only(end: 12, top: 6, bottom: 6));
    final themedLeading = leading == null
        ? null
        : IconTheme.merge(
            data: IconThemeData(color: iconColor),
            child: leading!,
          );
    final themedTrailing = trailing == null
        ? null
        : IconTheme.merge(
            data: IconThemeData(color: iconColor),
            child: trailing!,
          );
    final themedTitle = title == null
        ? null
        : DefaultTextStyle.merge(
            style: TextStyle(color: textColor),
            child: title!,
          );
    final themedSubtitle = subtitle == null
        ? null
        : DefaultTextStyle.merge(
            style: TextStyle(color: textColor?.withValues(alpha: 0.8)),
            child: subtitle!,
          );

    if (selected) {
      return f.ListTile.selectable(
        leading: themedLeading,
        title: themedTitle,
        subtitle: themedSubtitle,
        trailing: themedTrailing,
        onPressed: enabled ? onTap : null,
        selected: true,
        selectionMode: f.ListTileSelectionMode.single,
        tileColor: tileColor == null
            ? null
            : f.WidgetStateColor.resolveWith((states) => tileColor!),
        shape:
            shape ??
            const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
        contentPadding: padding,
      );
    }

    return f.ListTile(
      leading: themedLeading,
      title: themedTitle,
      subtitle: themedSubtitle,
      trailing: themedTrailing,
      onPressed: enabled ? onTap : null,
      tileColor: tileColor == null
          ? null
          : f.WidgetStateColor.resolveWith((states) => tileColor!),
      shape:
          shape ??
          const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
      contentPadding: padding,
    );
  }
}

class Switch extends StatelessWidget {
  const Switch({
    super.key,
    required this.value,
    required this.onChanged,
    this.visualDensity,
    this.thumbIcon,
  });

  const Switch.adaptive({
    super.key,
    required this.value,
    required this.onChanged,
    this.visualDensity,
    this.thumbIcon,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final VisualDensity? visualDensity;
  final WidgetStateProperty<Icon?>? thumbIcon;

  @override
  Widget build(BuildContext context) {
    return f.ToggleSwitch(checked: value, onChanged: onChanged);
  }
}

class SwitchListTile extends StatelessWidget {
  const SwitchListTile({
    super.key,
    this.secondary,
    this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.thumbIcon,
  });

  final Widget? secondary;
  final Widget? title;
  final Widget? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final WidgetStateProperty<Icon?>? thumbIcon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: secondary,
      title: title,
      subtitle: subtitle,
      trailing: Switch(value: value, onChanged: onChanged),
      onTap: onChanged == null ? null : () => onChanged!(!value),
    );
  }
}

class Checkbox extends StatelessWidget {
  const Checkbox({super.key, required this.value, required this.onChanged});

  final bool? value;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return f.Checkbox(checked: value, onChanged: onChanged);
  }
}

class CheckboxListTile extends StatelessWidget {
  const CheckboxListTile({
    super.key,
    this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.controlAffinity,
  });

  final Widget? title;
  final Widget? subtitle;
  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final ListTileControlAffinity? controlAffinity;

  @override
  Widget build(BuildContext context) {
    final checkbox = Checkbox(value: value, onChanged: onChanged);
    final isLeading = controlAffinity == ListTileControlAffinity.leading;

    return ListTile(
      leading: isLeading ? checkbox : null,
      title: title,
      subtitle: subtitle,
      trailing: isLeading ? null : checkbox,
      onTap: onChanged == null ? null : () => onChanged!(!(value ?? false)),
    );
  }
}

enum ListTileControlAffinity {
  leading,
  trailing,
  platform,
}

class RadioListTile<T> extends StatelessWidget {
  const RadioListTile({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.title,
    this.subtitle,
  });

  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final Widget? title;
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return ListTile(
      title: title,
      subtitle: subtitle,
      trailing: f.RadioGroup<T>(
        groupValue: groupValue,
        onChanged: onChanged ?? (_) {},
        child: f.RadioButton<T>(value: value),
      ),
      onTap: onChanged == null ? null : () => onChanged!(value),
      selected: selected,
    );
  }
}

class Slider extends StatelessWidget {
  const Slider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.label,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;
  final double min;
  final double max;
  final int? divisions;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return f.Slider(
      value: value,
      min: min,
      max: max,
      divisions: divisions,
      label: label,
      onChanged: onChanged,
      onChangeStart: onChangeStart,
      onChangeEnd: onChangeEnd,
    );
  }
}

class DropdownButtonHideUnderline extends StatelessWidget {
  const DropdownButtonHideUnderline({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

class DropdownMenuItem<T> {
  const DropdownMenuItem({required this.value, required this.child});

  final T value;
  final Widget child;
}

class DropdownButton<T> extends StatelessWidget {
  const DropdownButton({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.icon,
    this.isExpanded = false,
    this.style,
  });

  final List<DropdownMenuItem<T>>? items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final Widget? icon;
  final bool isExpanded;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return f.ComboBox<T>(
      value: value,
      onChanged: onChanged,
      isExpanded: isExpanded,
      icon: icon ?? const SizedBox.shrink(),
      items: items
          ?.map(
            (item) => f.ComboBoxItem<T>(value: item.value, child: item.child),
          )
          .toList(),
    );
  }
}

class PopupMenuItem<T> {
  const PopupMenuItem({this.key, required this.value, required this.child});

  final Key? key;
  final T value;
  final Widget child;
}

class PopupMenuButton<T> extends StatelessWidget {
  const PopupMenuButton({
    super.key,
    this.icon,
    required this.itemBuilder,
    this.onSelected,
  });

  final Widget? icon;
  final List<PopupMenuEntry<T>> Function(BuildContext context) itemBuilder;
  final ValueChanged<T>? onSelected;

  @override
  Widget build(BuildContext context) {
    final items = itemBuilder(context);
    return f.DropDownButton(
      buttonBuilder: (context, onOpen) {
        return f.IconButton(
          icon: icon ?? const Icon(Icons.more_vert),
          onPressed: onOpen,
        );
      },
      items: items
          .map(
            (item) => f.MenuFlyoutItem(
              onPressed: () => onSelected?.call(item.value),
              text: item.child,
            ),
          )
          .toList(),
    );
  }
}

class Chip extends StatelessWidget {
  const Chip({
    super.key,
    required this.label,
    this.avatar,
    this.backgroundColor,
    this.onDeleted,
    this.deleteIcon,
    this.labelStyle,
    this.padding,
    this.side,
    this.shape,
  });

  final Widget label;
  final Widget? avatar;
  final Color? backgroundColor;
  final VoidCallback? onDeleted;
  final Widget? deleteIcon;
  final TextStyle? labelStyle;
  final EdgeInsetsGeometry? padding;
  final BorderSide? side;
  final OutlinedBorder? shape;

  @override
  Widget build(BuildContext context) {
    final radius = shape is StadiumBorder
        ? BorderRadius.circular(999)
        : BorderRadius.circular(16);
    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? f.FluentTheme.of(context).cardColor,
        borderRadius: radius,
        border: side == null ? null : Border.fromBorderSide(side!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (avatar != null) ...[avatar!, const SizedBox(width: 6)],
          DefaultTextStyle.merge(style: labelStyle, child: label),
          if (onDeleted != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onDeleted,
              child: deleteIcon ?? const Icon(Icons.close, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}

class InputChip extends StatelessWidget {
  const InputChip({
    super.key,
    required this.label,
    this.avatar,
    this.backgroundColor,
    this.onDeleted,
    this.deleteIcon,
    this.labelStyle,
    this.padding,
    this.side,
    this.shape,
    this.onPressed,
    this.materialTapTargetSize,
  });

  final Widget label;
  final Widget? avatar;
  final Color? backgroundColor;
  final VoidCallback? onDeleted;
  final Widget? deleteIcon;
  final TextStyle? labelStyle;
  final EdgeInsetsGeometry? padding;
  final BorderSide? side;
  final OutlinedBorder? shape;
  final VoidCallback? onPressed;
  final MaterialTapTargetSize? materialTapTargetSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Chip(
        label: label,
        avatar: avatar,
        backgroundColor: backgroundColor,
        onDeleted: onDeleted,
        deleteIcon: deleteIcon,
        labelStyle: labelStyle,
        padding: padding,
        side: side,
        shape: shape,
      ),
    );
  }
}

class ActionChip extends StatelessWidget {
  const ActionChip({
    super.key,
    required this.label,
    this.avatar,
    this.backgroundColor,
    this.onPressed,
    this.labelStyle,
    this.side,
    this.tooltip,
    this.visualDensity,
  });

  final Widget label;
  final Widget? avatar;
  final Color? backgroundColor;
  final VoidCallback? onPressed;
  final TextStyle? labelStyle;
  final BorderSide? side;
  final String? tooltip;
  final VisualDensity? visualDensity;

  @override
  Widget build(BuildContext context) {
    final child = f.Button(
      style: f.ButtonStyle(
        backgroundColor: f.WidgetStatePropertyAll(
          backgroundColor ?? f.FluentTheme.of(context).cardColor,
        ),
        shape: f.WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: side ?? BorderSide.none,
          ),
        ),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (avatar != null) ...[avatar!, const SizedBox(width: 6)],
          DefaultTextStyle.merge(style: labelStyle, child: label),
        ],
      ),
    );
    if (tooltip == null) return child;
    return f.Tooltip(message: tooltip!, child: child);
  }
}

class ChoiceChip extends StatelessWidget {
  const ChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.avatar,
    this.labelStyle,
    this.backgroundColor,
    this.selectedColor,
    this.side,
    this.shape,
    this.showCheckmark = true,
    this.materialTapTargetSize,
    this.visualDensity,
  });

  final Widget label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final Widget? avatar;
  final TextStyle? labelStyle;
  final Color? backgroundColor;
  final Color? selectedColor;
  final BorderSide? side;
  final OutlinedBorder? shape;
  final bool showCheckmark;
  final MaterialTapTargetSize? materialTapTargetSize;
  final VisualDensity? visualDensity;

  @override
  Widget build(BuildContext context) {
    final theme = f.FluentTheme.of(context);
    return f.Button(
      style: f.ButtonStyle(
        backgroundColor: f.WidgetStatePropertyAll(
          selected
              ? (selectedColor ??
                    theme.accentColor.tertiaryBrushFor(theme.brightness))
              : (backgroundColor ?? theme.cardColor),
        ),
        shape: f.WidgetStatePropertyAll(
          shape ??
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: side ?? BorderSide.none,
              ),
        ),
      ),
      onPressed: onSelected == null ? null : () => onSelected!(!selected),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected && showCheckmark) ...[
            const Icon(Icons.check, size: 14),
            const SizedBox(width: 6),
          ],
          if (avatar != null) ...[avatar!, const SizedBox(width: 6)],
          DefaultTextStyle.merge(style: labelStyle, child: label),
        ],
      ),
    );
  }
}

class CircularProgressIndicator extends StatelessWidget {
  const CircularProgressIndicator({
    super.key,
    this.value,
    this.strokeWidth = 4,
    this.valueColor,
    this.color,
  });

  final double? value;
  final double strokeWidth;
  final Animation<Color?>? valueColor;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return f.ProgressRing(
      value: value == null ? null : value! * 100,
      strokeWidth: strokeWidth,
      activeColor: color ?? valueColor?.value,
    );
  }
}

class LinearProgressIndicator extends StatelessWidget {
  const LinearProgressIndicator({
    super.key,
    this.value,
    this.backgroundColor,
    this.valueColor,
    this.minHeight,
  });

  final double? value;
  final Color? backgroundColor;
  final Animation<Color?>? valueColor;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    return f.ProgressBar(
      value: value == null ? null : value! * 100,
      backgroundColor: backgroundColor,
      activeColor: valueColor?.value,
    );
  }
}

class RefreshIndicator extends StatelessWidget {
  const RefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.displacement = 40.0,
  });

  final Widget child;
  final Future<void> Function() onRefresh;
  final double displacement;

  @override
  Widget build(BuildContext context) {
    return EasyRefresh(
      header: const ClassicHeader(),
      onRefresh: onRefresh,
      child: child,
    );
  }
}

class AlertDialog extends StatelessWidget {
  const AlertDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.backgroundColor,
    this.scrollable = false,
  });

  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return f.ContentDialog(
      title: title,
      content: content,
      actions: actions,
      constraints: const BoxConstraints(maxWidth: 560),
    );
  }
}

Future<T?> showModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  Color? backgroundColor,
}) {
  return f.showDialog<T>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: MediaQuery.paddingOf(dialogContext).bottom + 12,
          ),
          decoration: BoxDecoration(
            color:
                backgroundColor ??
                f.FluentTheme.of(dialogContext).micaBackgroundColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: builder(dialogContext),
        ),
      );
    },
  );
}

class ExpansionTile extends StatefulWidget {
  const ExpansionTile({
    super.key,
    required this.title,
    this.children = const [],
    this.initiallyExpanded = false,
    this.tilePadding,
    this.childrenPadding,
    this.shape,
    this.collapsedShape,
  });

  final Widget title;
  final List<Widget> children;
  final bool initiallyExpanded;
  final EdgeInsetsGeometry? tilePadding;
  final EdgeInsetsGeometry? childrenPadding;
  final ShapeBorder? shape;
  final ShapeBorder? collapsedShape;

  @override
  State<ExpansionTile> createState() => _ExpansionTileState();
}

class _ExpansionTileState extends State<ExpansionTile> {
  @override
  Widget build(BuildContext context) {
    return f.Expander(
      initiallyExpanded: widget.initiallyExpanded,
      header: Padding(
        padding:
            widget.tilePadding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: widget.title,
      ),
      content: Padding(
        padding:
            widget.childrenPadding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(children: widget.children),
      ),
    );
  }
}

class DefaultTabController extends StatefulWidget {
  const DefaultTabController({
    super.key,
    required this.length,
    required this.child,
  });

  final int length;
  final Widget child;

  static TabController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_TabControllerScope>();
    assert(scope != null, 'No DefaultTabController found in context');
    return scope!.controller;
  }

  @override
  State<DefaultTabController> createState() => _DefaultTabControllerState();
}

class _DefaultTabControllerState extends State<DefaultTabController> {
  late final TabController controller;

  @override
  void initState() {
    super.initState();
    controller = TabController(length: widget.length, vsync: null);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _TabControllerScope(controller: controller, child: widget.child);
  }
}

class _TabControllerScope extends InheritedWidget {
  const _TabControllerScope({required this.controller, required super.child});

  final TabController controller;

  @override
  bool updateShouldNotify(covariant _TabControllerScope oldWidget) {
    return oldWidget.controller != controller;
  }
}

class TabController extends ChangeNotifier {
  TabController({
    required this.length,
    required dynamic vsync,
    int initialIndex = 0,
  }) : _index = initialIndex;

  final int length;
  int _index;

  int get index => _index;

  set index(int value) {
    if (value == _index) return;
    _index = value.clamp(0, length - 1);
    notifyListeners();
  }

  void animateTo(int value) {
    index = value;
  }
}

class Tab extends StatelessWidget {
  const Tab({super.key, this.text, this.icon, this.child});

  final String? text;
  final Widget? icon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (child != null) return child!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          icon!,
          if (text != null) const SizedBox(width: 6),
        ],
        if (text != null) Text(text!),
      ],
    );
  }
}

class TabBar extends StatelessWidget implements PreferredSizeWidget {
  const TabBar({
    super.key,
    this.controller,
    required this.tabs,
    this.isScrollable = false,
    this.dividerColor,
    this.labelStyle,
  });

  final TabController? controller;
  final List<Widget> tabs;
  final bool isScrollable;
  final Color? dividerColor;
  final TextStyle? labelStyle;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    final resolvedController = controller ?? DefaultTabController.of(context);
    final theme = f.FluentTheme.of(context);

    return AnimatedBuilder(
      animation: resolvedController,
      builder: (context, _) {
        final children = List.generate(tabs.length, (index) {
          final selected = resolvedController.index == index;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: f.Button(
              style: f.ButtonStyle(
                backgroundColor: f.WidgetStatePropertyAll(
                  selected
                      ? theme.accentColor.tertiaryBrushFor(theme.brightness)
                      : f.Colors.transparent,
                ),
                shape: f.WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              onPressed: () => resolvedController.animateTo(index),
              child: DefaultTextStyle.merge(
                style: labelStyle,
                child: tabs[index],
              ),
            ),
          );
        });

        return Container(
          decoration: BoxDecoration(
            border: dividerColor == null
                ? null
                : Border(bottom: BorderSide(color: dividerColor!)),
          ),
          child: isScrollable
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: children),
                )
              : Row(
                  children: [
                    for (final child in children) Expanded(child: child),
                  ],
                ),
        );
      },
    );
  }
}

class TabBarView extends StatelessWidget {
  const TabBarView({super.key, this.controller, required this.children});

  final TabController? controller;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final resolvedController = controller ?? DefaultTabController.of(context);
    return AnimatedBuilder(
      animation: resolvedController,
      builder: (context, _) {
        return IndexedStack(
          index: resolvedController.index.clamp(0, children.length - 1),
          children: children,
        );
      },
    );
  }
}

class Icons {
  static const IconData add = f.FluentIcons.add;
  static const IconData account_circle_outlined = f.FluentIcons.contact;
  static const IconData arrow_back = f.FluentIcons.back;
  static const IconData arrow_forward_ios = f.FluentIcons.chevron_right;
  static const IconData attach_file_rounded = f.FluentIcons.attach;
  static const IconData auto_awesome_outlined = f.FluentIcons.starburst;
  static const IconData auto_stories_outlined = f.FluentIcons.book_answers;
  static const IconData back = f.FluentIcons.back;
  static const IconData battery_1_bar = f.FluentIcons.power_button;
  static const IconData battery_2_bar = f.FluentIcons.power_button;
  static const IconData battery_3_bar = f.FluentIcons.power_button;
  static const IconData battery_4_bar = f.FluentIcons.power_button;
  static const IconData battery_5_bar = f.FluentIcons.power_button;
  static const IconData battery_6_bar = f.FluentIcons.power_button;
  static const IconData battery_alert = f.FluentIcons.warning;
  static const IconData battery_charging_full = f.FluentIcons.power_button;
  static const IconData battery_full = f.FluentIcons.power_button;
  static const IconData block = f.FluentIcons.blocked;
  static const IconData block_outlined = f.FluentIcons.blocked;
  static const IconData bluetooth = f.FluentIcons.bluetooth;
  static const IconData bug_report_outlined = f.FluentIcons.bug;
  static const IconData cancel = f.FluentIcons.cancel;
  static const IconData cancel_outlined = f.FluentIcons.cancel;
  static const IconData category = f.FluentIcons.category_classification;
  static const IconData category_outlined =
      f.FluentIcons.category_classification;
  static const IconData chart = f.FluentIcons.chart;
  static const IconData check = f.FluentIcons.accept;
  static const IconData chevron_right = f.FluentIcons.chevron_right;
  static const IconData chevron_right_rounded = f.FluentIcons.chevron_right;
  static const IconData chrome_close = f.FluentIcons.chrome_close;
  static const IconData chrome_full_screen = f.FluentIcons.chrome_full_screen;
  static const IconData chrome_minimize = f.FluentIcons.chrome_minimize;
  static const IconData chrome_restore = f.FluentIcons.chrome_restore;
  static const IconData close = f.FluentIcons.chrome_close;
  static const IconData cloud_download_outlined = f.FluentIcons.cloud_download;
  static const IconData cloud_outlined = f.FluentIcons.cloud;
  static const IconData cloud_sync_outlined = f.FluentIcons.sync;
  static const IconData color_lens_outlined = f.FluentIcons.color;
  static const IconData colorize_outlined = f.FluentIcons.color;
  static const IconData comment = f.FluentIcons.comment;
  static const IconData comment_outlined = f.FluentIcons.comment;
  static const IconData comment_sharp = f.FluentIcons.comment;
  static const IconData compare_arrows = f.FluentIcons.sync;
  static const IconData contrast_outlined = f.FluentIcons.color;
  static const IconData dark_mode_outlined = f.FluentIcons.power_button;
  static const IconData delete_outline = f.FluentIcons.delete;
  static const IconData deselect = f.FluentIcons.cancel;
  static const IconData download = f.FluentIcons.download;
  static const IconData download_outlined = f.FluentIcons.download;
  static const IconData download_rounded = f.FluentIcons.download;
  static const IconData expand_less = f.FluentIcons.chevron_up;
  static const IconData expand_more = f.FluentIcons.chevron_down;
  static const IconData favorite = f.FluentIcons.favorite_star_fill;
  static const IconData favorite_border = f.FluentIcons.favorite_star;
  static const IconData favorite_rounded = f.FluentIcons.favorite_star;
  static const IconData filter_alt = f.FluentIcons.filter;
  static const IconData history = f.FluentIcons.history;
  static const IconData history_rounded = f.FluentIcons.history;
  static const IconData history_toggle_off = f.FluentIcons.history;
  static const IconData home = f.FluentIcons.home;
  static const IconData home_outlined = f.FluentIcons.home;
  static const IconData home_rounded = f.FluentIcons.home;
  static const IconData hourglass_empty = f.FluentIcons.history;
  static const IconData image = f.FluentIcons.image_search;
  static const IconData image_outlined = f.FluentIcons.image_search;
  static const IconData info_outline = f.FluentIcons.info;
  static const IconData label_important_outline = f.FluentIcons.label;
  static const IconData library = f.FluentIcons.library;
  static const IconData list_alt_rounded = f.FluentIcons.view_list;
  static const IconData login = f.FluentIcons.contact;
  static const IconData logout = f.FluentIcons.blocked;
  static const IconData low_priority_rounded = f.FluentIcons.sort;
  static const IconData manage_accounts_outlined =
      f.FluentIcons.contact_card_settings;
  static const IconData manage_search = f.FluentIcons.search_and_apps;
  static const IconData memory = f.FluentIcons.device_bug;
  static const IconData memory_outlined = f.FluentIcons.device_bug;
  static const IconData menu = f.FluentIcons.more;
  static const IconData more = f.FluentIcons.more;
  static const IconData more_vert = f.FluentIcons.more_vertical;
  static const IconData network_cell = f.FluentIcons.network_tower;
  static const IconData notifications_active_outlined = f.FluentIcons.warning;
  static const IconData open_in_new_rounded = f.FluentIcons.open_in_new_window;
  static const IconData open_in_new_window = f.FluentIcons.open_in_new_window;
  static const IconData palette_outlined = f.FluentIcons.color;
  static const IconData password_outlined = f.FluentIcons.password_field;
  static const IconData pause_rounded = f.FluentIcons.pause;
  static const IconData person_outline = f.FluentIcons.contact;
  static const IconData play_arrow_rounded = f.FluentIcons.play;
  static const IconData public_outlined = f.FluentIcons.globe;
  static const IconData refresh = f.FluentIcons.refresh;
  static const IconData remove_red_eye = f.FluentIcons.view;
  static const IconData rocket_launch_outlined = f.FluentIcons.play;
  static const IconData route_outlined = f.FluentIcons.network_device_scanning;
  static const IconData router = f.FluentIcons.network_device_scanning;
  static const IconData router_outlined = f.FluentIcons.network_device_scanning;
  static const IconData save_alt = f.FluentIcons.save;
  static const IconData search = f.FluentIcons.search;
  static const IconData search_outlined = f.FluentIcons.search;
  static const IconData search_rounded = f.FluentIcons.search;
  static const IconData select_all = f.FluentIcons.select_all;
  static const IconData settings = f.FluentIcons.settings;
  static const IconData settings_outlined = f.FluentIcons.settings;
  static const IconData shield_outlined = f.FluentIcons.shield;
  static const IconData short_text_outlined = f.FluentIcons.label;
  static const IconData shortcut = f.FluentIcons.link;
  static const IconData signal_cellular_off = f.FluentIcons.blocked;
  static const IconData signal_wifi_off = f.FluentIcons.blocked;
  static const IconData skip_next_rounded = f.FluentIcons.next;
  static const IconData skip_previous_rounded = f.FluentIcons.previous;
  static const IconData smartphone_outlined = f.FluentIcons.cell_phone;
  static const IconData sort = f.FluentIcons.sort;
  static const IconData speed_outlined = f.FluentIcons.sync;
  static const IconData star = f.FluentIcons.favorite_star_fill;
  static const IconData star_border = f.FluentIcons.favorite_star;
  static const IconData storage_outlined = f.FluentIcons.storage_optical;
  static const IconData sync_outlined = f.FluentIcons.sync;
  static const IconData travel_explore_outlined = f.FluentIcons.globe;
  static const IconData tune = f.FluentIcons.settings;
  static const IconData tune_outlined = f.FluentIcons.settings;
  static const IconData tune_rounded = f.FluentIcons.settings;
  static const IconData vertical_align_top = f.FluentIcons.chevron_up;
  static const IconData view_agenda_outlined = f.FluentIcons.view_dashboard;
  static const IconData visibility_off_outlined = f.FluentIcons.hide;
  static const IconData vpn_key = f.FluentIcons.key_phrase_extraction;
  static const IconData wifi = f.FluentIcons.wifi;
  static const IconData wifi_off_rounded = f.FluentIcons.wifi;
}
