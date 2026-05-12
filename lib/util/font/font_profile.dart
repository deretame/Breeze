import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zephyr/util/get_path.dart';

const _fontSettingKeys = <int, String>{
  100: 'font_profile_w100',
  200: 'font_profile_w200',
  300: 'font_profile_w300',
  400: 'font_profile_w400',
  500: 'font_profile_w500',
  600: 'font_profile_w600',
  700: 'font_profile_w700',
  800: 'font_profile_w800',
  900: 'font_profile_w900',
};

const fontWeightLabels = <int, String>{
  100: 'Thin',
  200: 'ExtraLight',
  300: 'Light',
  400: 'Regular',
  500: 'Medium',
  600: 'SemiBold',
  700: 'Bold',
  800: 'ExtraBold',
  900: 'Black',
};

class FontProfileController extends ChangeNotifier {
  FontProfileController._();

  static final FontProfileController instance = FontProfileController._();

  SharedPreferences? _prefs;
  Map<int, String> _paths = const {};
  Map<int, String> _families = const {};

  Map<int, String> get paths => _paths;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    final nextPaths = <int, String>{};
    final nextFamilies = <int, String>{};
    for (final entry in _fontSettingKeys.entries) {
      final path = _prefs!.getString(entry.value)?.trim() ?? '';
      if (path.isEmpty) continue;
      final family = await _registerFont(entry.key, path);
      if (family == null) continue;
      nextPaths[entry.key] = path;
      nextFamilies[entry.key] = family;
    }
    _paths = nextPaths;
    _families = nextFamilies;
  }

  String? pathForWeight(int weight) => _paths[weight];

  String familyForWeight(FontWeight? weight) {
    final normalized = _normalizeWeight(weight);
    return _families[normalized] ?? _families[400] ?? '';
  }

  Future<bool> setPath(int weight, String path) async {
    _prefs ??= await SharedPreferences.getInstance();
    final normalizedPath = path.trim();
    final nextPaths = Map<int, String>.from(_paths);
    final nextFamilies = Map<int, String>.from(_families);
    final key = _fontSettingKeys[weight]!;
    final previousPath = _paths[weight];

    if (normalizedPath.isEmpty) {
      nextPaths.remove(weight);
      nextFamilies.remove(weight);
      await _prefs!.remove(key);
      await _deleteIfManaged(previousPath);
      _paths = nextPaths;
      _families = nextFamilies;
      notifyListeners();
      return true;
    }

    final storedPath = await _copyToManagedFonts(weight, normalizedPath);
    final family = await _registerFont(weight, storedPath);
    if (family == null) {
      await _deleteIfManaged(storedPath);
      return false;
    }

    nextPaths[weight] = storedPath;
    nextFamilies[weight] = family;
    await _prefs!.setString(key, storedPath);
    if (previousPath != null && previousPath != storedPath) {
      await _deleteIfManaged(previousPath);
    }
    _paths = nextPaths;
    _families = nextFamilies;
    notifyListeners();
    return true;
  }

  Future<void> clearAll() async {
    _prefs ??= await SharedPreferences.getInstance();
    final managedPaths = _paths.values.toList(growable: false);
    for (final key in _fontSettingKeys.values) {
      await _prefs!.remove(key);
    }
    _paths = {};
    _families = {};
    for (final path in managedPaths) {
      await _deleteIfManaged(path);
    }
    notifyListeners();
  }

  TextTheme applyToTextTheme(TextTheme base) {
    return TextTheme(
      displayLarge: _apply(base.displayLarge),
      displayMedium: _apply(base.displayMedium),
      displaySmall: _apply(base.displaySmall),
      headlineLarge: _apply(base.headlineLarge),
      headlineMedium: _apply(base.headlineMedium),
      headlineSmall: _apply(base.headlineSmall),
      titleLarge: _apply(base.titleLarge),
      titleMedium: _apply(base.titleMedium),
      titleSmall: _apply(base.titleSmall),
      bodyLarge: _apply(base.bodyLarge),
      bodyMedium: _apply(base.bodyMedium),
      bodySmall: _apply(base.bodySmall),
      labelLarge: _apply(base.labelLarge),
      labelMedium: _apply(base.labelMedium),
      labelSmall: _apply(base.labelSmall),
    );
  }

  TextStyle? applyStyleForWeight(TextStyle? style, int weight) {
    if (style == null) return null;
    final family = _families[weight] ?? _families[400] ?? '';
    if (family.isEmpty) return style;
    return style.copyWith(fontFamily: family);
  }

  TextStyle? _apply(TextStyle? style) {
    if (style == null) return null;
    final family = familyForWeight(style.fontWeight);
    if (family.isEmpty) return style;
    return style.copyWith(fontFamily: family);
  }

  Future<String?> _registerFont(int weight, String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      final family = 'user-font-$weight-${path.hashCode}';
      final loader = FontLoader(family);
      loader.addFont(
        Future.value(
          ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes),
        ),
      );
      await loader.load();
      return family;
    } catch (_) {
      return null;
    }
  }

  Future<String> _copyToManagedFonts(int weight, String sourcePath) async {
    final fileRoot = await getFilePath();
    final fontsDir = Directory(p.join(fileRoot, 'fonts'));
    if (!await fontsDir.exists()) {
      await fontsDir.create(recursive: true);
    }

    final originalName = p.basename(sourcePath);
    final sanitizedName = originalName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final targetPath = p.join(fontsDir.path, 'w${weight}_$sanitizedName');
    final sourceFile = File(sourcePath);
    final targetFile = File(targetPath);

    if (p.equals(sourceFile.path, targetFile.path)) {
      return targetFile.path;
    }

    await sourceFile.copy(targetFile.path);
    return targetFile.path;
  }

  Future<void> _deleteIfManaged(String? targetPath) async {
    if (targetPath == null || targetPath.isEmpty) return;
    final fontsDir = Directory(p.join(await getFilePath(), 'fonts'));
    final normalizedFontsDir = p.normalize(fontsDir.path);
    final normalizedTarget = p.normalize(targetPath);
    if (!p.isWithin(normalizedFontsDir, normalizedTarget) &&
        normalizedFontsDir != normalizedTarget) {
      return;
    }

    final file = File(targetPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  int _normalizeWeight(FontWeight? weight) {
    if (weight == null) return 400;
    final value = weight.value;
    if (value <= 100) return 100;
    if (value == 200) return 200;
    if (value == 300) return 300;
    if (value == 400) return 400;
    if (value == 500) return 500;
    if (value == 600) return 600;
    if (value == 700) return 700;
    if (value == 800) return 800;
    return 900;
  }
}
