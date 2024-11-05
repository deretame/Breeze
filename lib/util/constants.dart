import 'dart:io';

class Constants {
  /// 为true表示使用FluentUI 否则为false,不应作为Desktop的判断
  static final bool isFluent = Platform.isWindows;
}
