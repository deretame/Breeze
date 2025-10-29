import 'dart:io';
import 'package:flutter/material.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/util/context/context_extensions.dart';

class ImageDisplay extends StatefulWidget {
  final String imagePath;
  final bool isColumn;

  const ImageDisplay({
    super.key,
    required this.imagePath,
    required this.isColumn,
  });

  @override
  State<ImageDisplay> createState() => _ImageDisplayState();
}

class _ImageDisplayState extends State<ImageDisplay> {
  ImageStream? _imageStream;
  late final ImageStreamListener _imageListener;

  bool get isColumn => widget.isColumn;

  double imageWidth = 0;
  double imageHeight = 0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    _imageListener = ImageStreamListener(
      (ImageInfo imageInfo, _) {
        if (mounted) {
          setState(() {
            imageWidth = imageInfo.image.width.toDouble();
            imageHeight = imageInfo.image.height.toDouble();
            _hasError = false;
          });
        }
      },
      onError: (exception, stackTrace) {
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (isColumn) {
      _loadImageStream();
    }
  }

  Future<void> _loadImageStream() async {
    // 检查文件是否存在
    final file = File(widget.imagePath);
    if (!await file.exists()) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
      return;
    }

    if (!mounted) return;

    final imageProvider = FileImage(file);
    _imageStream = imageProvider.resolve(
      createLocalImageConfiguration(context),
    );
    _imageStream!.addListener(_imageListener);
  }

  @override
  void dispose() {
    _imageStream?.removeListener(_imageListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 如果图片解码失败，显示错误提示
    if (_hasError) {
      return Container(
        color: isColumn ? const Color(0xFF2D2D2D) : Colors.black,
        width: context.screenWidth,
        height: context.screenWidth,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image,
                size: 64,
                color: isColumn ? const Color(0xFFCCCCCC) : Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                '图片解码失败',
                style: TextStyle(
                  fontSize: 16,
                  color: isColumn ? const Color(0xFFCCCCCC) : Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '图片数据可能已损坏',
                style: TextStyle(
                  fontSize: 12,
                  color: isColumn
                      ? const Color(0xFFCCCCCC).withValues(alpha: 0.7)
                      : Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  // 删除损坏的缓存文件
                  try {
                    final file = File(widget.imagePath);
                    if (await file.exists()) {
                      await file.delete();
                    }
                    setState(() {
                      _hasError = false;
                    });
                    // 触发重新加载
                    if (mounted) {
                      setState(() {});
                    }
                  } catch (e) {
                    // 删除失败，保持错误状态
                    logger.e('删除损坏图片失败: ${widget.imagePath}', error: e);
                  }
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('删除并重试'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 限制缓存大小，避免 GPU 内存溢出
    // 使用较小的缓存尺寸，最大不超过 1080p
    final screenWidth = context.screenWidth;
    final pixelRatio = context.devicePixelRatio;
    final maxCacheWidth = 1080; // 限制最大宽度
    final cacheSize = (screenWidth * pixelRatio).round().clamp(
      0,
      maxCacheWidth,
    );

    return Container(
      color: Colors.black,
      width: context.screenWidth,
      height: imageHeight != 0
          ? (imageHeight * (context.screenWidth / imageWidth))
          : context.screenWidth,
      child: isColumn
          ? imageWidth != 0 && imageHeight != 0
                ? Image.file(
                    File(widget.imagePath),
                    fit: BoxFit.fill,
                    cacheWidth: cacheSize,
                    gaplessPlayback: true,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFF2D2D2D),
                        child: Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 64,
                            color: const Color(0xFFCCCCCC),
                          ),
                        ),
                      );
                    },
                  )
                : Container(color: const Color(0xFF2D2D2D))
          : Image.file(
              File(widget.imagePath),
              fit: BoxFit.contain,
              cacheWidth: cacheSize,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.black,
                  child: Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
