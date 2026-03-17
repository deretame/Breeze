import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:flutter/widgets.dart';

/// Material-style Divider compatibility wrapper for FluentUI
class Divider extends StatelessWidget {
  const Divider({
    super.key,
    this.color,
    this.height,
    this.thickness,
    this.indent,
    this.endIndent,
  });

  final Color? color;
  final double? height;
  final double? thickness;
  final double? indent;
  final double? endIndent;

  @override
  Widget build(BuildContext context) {
    final theme = f.FluentTheme.of(context);
    final effectiveColor = color ?? theme.resources.dividerStrokeColorDefault;
    final effectiveThickness = thickness ?? 1.0;
    final effectiveHeight = height ?? effectiveThickness;

    return SizedBox(
      height: effectiveHeight,
      child: Center(
        child: Container(
          height: effectiveThickness,
          margin: EdgeInsets.only(
            left: indent ?? 0,
            right: endIndent ?? 0,
          ),
          color: effectiveColor,
        ),
      ),
    );
  }
}
