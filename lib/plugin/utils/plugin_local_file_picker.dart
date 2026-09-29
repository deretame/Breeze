import 'package:file_selector/file_selector.dart';

/// 选择本地插件脚本文件，返回 null 表示用户取消。
///
/// 刻意不过滤后缀：`file_selector` 会把 `extensions` 翻译成系统级过滤，
/// 而 `cjs` / `br` 在系统映射表里不存在——Android 侧经 `MimeTypeMap` 转换
/// 直接丢弃该后缀（`br` 文件不可见），iOS 侧非 `public.javascript` 类型
/// 灰掉选不中，macOS 侧 `UTType(filenameExtension:)` 同样解析不出。
/// 因此全量选择，后缀/内容校验交给安装层
/// （见 `PluginInstallService.installFromLocalBytes` 的内容嗅探）。
Future<XFile?> pickPluginScriptFile() => openFile();
