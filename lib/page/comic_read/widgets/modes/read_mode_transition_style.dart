import 'package:flutter/material.dart';

/// 列/行模式过渡卡片的样式配置。
class ReadModeTransitionStyle {
  const ReadModeTransitionStyle._({
    required this.fixedCardSize,
    required this.outerPadding,
    required this.cardPadding,
    required this.minHeight,
    required this.lineSpacing,
  });

  /// 行模式：卡片在水平内边距中自适应，无固定尺寸。
  static const row = ReadModeTransitionStyle._(
    fixedCardSize: null,
    outerPadding: null,
    cardPadding: EdgeInsets.symmetric(horizontal: 24),
    minHeight: 320,
    lineSpacing: 34,
  );

  /// 列模式：卡片为固定正方形，便于在竖向滚动中保持视觉统一。
  factory ReadModeTransitionStyle.column({required double shortEdge}) {
    return ReadModeTransitionStyle._(
      fixedCardSize: Size(shortEdge, shortEdge),
      outerPadding: const EdgeInsets.symmetric(vertical: 18),
      cardPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      minHeight: 0,
      lineSpacing: 24,
    );
  }

  final Size? fixedCardSize;
  final EdgeInsets? outerPadding;
  final EdgeInsets cardPadding;
  final double minHeight;
  final double lineSpacing;
}
