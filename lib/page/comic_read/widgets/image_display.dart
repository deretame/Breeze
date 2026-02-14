import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/comic_read/cubit/image_size_cubit.dart';

class ImageDisplay extends StatefulWidget {
  final String imagePath;
  final bool isColumn;
  final int index;

  const ImageDisplay({
    super.key,
    required this.imagePath,
    required this.isColumn,
    required this.index,
  });

  @override
  State<ImageDisplay> createState() => _ImageDisplayState();
}

class _ImageDisplayState extends State<ImageDisplay> {
  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;

  double? _rawWidth;
  double? _rawHeight;

  bool get isColumn => widget.isColumn;

  @override
  void initState() {
    super.initState();
    if (isColumn) {
      _resolveImageMeta();
    }
  }

  @override
  void didUpdateWidget(covariant ImageDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isColumn && widget.imagePath != oldWidget.imagePath) {
      _stopListening();
      _rawWidth = null;
      _rawHeight = null;
      _resolveImageMeta();
    }
  }

  void _resolveImageMeta() {
    final imageProvider = FileImage(File(widget.imagePath));
    final newStream = imageProvider.resolve(ImageConfiguration.empty);

    final newListener = ImageStreamListener(
      (ImageInfo imageInfo, bool synchronousCall) {
        if (!mounted) return;

        _rawWidth = imageInfo.image.width.toDouble();
        _rawHeight = imageInfo.image.height.toDouble();

        if (context.mounted) {
          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null && renderBox.hasSize) {
            _updateCubitSize(renderBox.size.width);
          }
        }
      },
      onError: (exception, stackTrace) {
        logger.e('Failed to resolve image size: $exception');
      },
    );

    _imageStream = newStream;
    _imageListener = newListener;
    newStream.addListener(newListener);
  }

  void _updateCubitSize(double actualWidth) {
    if (_rawWidth == null || _rawHeight == null || _rawWidth == 0) return;

    final index = widget.index;
    final cubit = context.read<ImageSizeCubit>();

    final double finalHeight = (_rawHeight! / _rawWidth!) * actualWidth;

    final currentCachedSize = cubit.getSize(index);

    if (!currentCachedSize.isCached ||
        (currentCachedSize.size.height - finalHeight).abs() > 0.5 ||
        (currentCachedSize.size.width - actualWidth).abs() > 0.5) {
      cubit.updateSize(index, Size(actualWidth, finalHeight));
    }
  }

  void _stopListening() {
    if (_imageStream != null && _imageListener != null) {
      _imageStream!.removeListener(_imageListener!);
    }
    _imageStream = null;
    _imageListener = null;
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int cacheSize = (width * pixelRatio).round();

        if (_rawWidth != null && isColumn) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _updateCubitSize(width);
          });
        }

        return Image.file(
          File(widget.imagePath),
          width: width,
          fit: isColumn ? BoxFit.fill : BoxFit.contain,
          cacheWidth: cacheSize > 0 ? cacheSize : null,
          gaplessPlayback: true,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) {
              return child;
            }

            if (isColumn) {
              return Container(
                width: width,
                color: const Color(0xFF2D2D2D),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            } else {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white24),
              );
            }
          },
        );
      },
    );
  }
}
