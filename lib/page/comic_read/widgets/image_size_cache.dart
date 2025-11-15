import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// 图片尺寸缓存管理器
/// 用于缓存图片的宽高信息，避免组件重建时高度跳动
class ImageSizeCache {
  static final ImageSizeCache _instance = ImageSizeCache._internal();
  factory ImageSizeCache() => _instance;
  ImageSizeCache._internal();

  // 缓存图片尺寸 key: cacheKey, value: Size(width, height)
  final Map<String, Size> _sizeCache = {};

  /// 获取缓存的图片尺寸
  Size? getSize(String cacheKey) => _sizeCache[cacheKey];

  /// 缓存图片尺寸（支持多个 key 指向同一个尺寸）
  void cacheSize(String cacheKey, Size size, {List<String>? additionalKeys}) {
    _sizeCache[cacheKey] = size;
    // 如果有额外的 key，也一起缓存
    if (additionalKeys != null) {
      for (final key in additionalKeys) {
        _sizeCache[key] = size;
      }
    }
  }

  /// 清除指定图片的缓存
  void remove(String cacheKey) {
    _sizeCache.remove(cacheKey);
  }

  /// 清除所有缓存
  void clear() {
    _sizeCache.clear();
  }

  /// 获取缓存数量
  int get cacheCount => _sizeCache.length;

  /// 异步获取图片尺寸（如果缓存中没有）
  Future<Size?> getImageSize(String cacheKey, String imagePath) async {
    // 先检查缓存
    if (_sizeCache.containsKey(cacheKey)) {
      return _sizeCache[cacheKey];
    }

    // 如果缓存中没有，尝试读取图片获取尺寸
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        return null;
      }

      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final size = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );

      // 缓存尺寸（同时用 cacheKey 和 imagePath 作为 key）
      cacheSize(cacheKey, size, additionalKeys: [imagePath]);

      // 释放资源
      frame.image.dispose();
      codec.dispose();

      return size;
    } catch (e) {
      return null;
    }
  }
}
