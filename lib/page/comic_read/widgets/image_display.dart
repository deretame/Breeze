import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/comic_read/cubit/image_size_cubit.dart';
import 'package:zephyr/util/context/context_extensions.dart';

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

  bool get isColumn => widget.isColumn;

  @override
  void initState() {
    super.initState();
    if (isColumn) {
      _resolveImageSize();
    }
  }

  @override
  void didUpdateWidget(covariant ImageDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isColumn != oldWidget.isColumn) {
      if (widget.isColumn) {
        _resolveImageSize();
      } else {
        _stopListening();
      }
    }

    if (widget.isColumn && widget.imagePath != oldWidget.imagePath) {
      _stopListening();
      _resolveImageSize();
    }
  }

  void _resolveImageSize() {
    if (!isColumn) return;

    final index = widget.index;
    final cubit = context.read<ImageSizeCubit>();
    final check = cubit.getSize(index);
    if (check.isCached) {
      return;
    }

    final imageProvider = FileImage(File(widget.imagePath));

    final newStream = imageProvider.resolve(ImageConfiguration.empty);

    final newListener = ImageStreamListener(
      (ImageInfo imageInfo, bool synchronousCall) {
        if (!mounted) return;

        final double rawWidth = imageInfo.image.width.toDouble();
        final double rawHeight = imageInfo.image.height.toDouble();
        final double logicalWidth = cubit.state.defaultWidth;
        if (rawWidth == 0) return;

        final double scaledHeight = (rawHeight / rawWidth) * logicalWidth;

        cubit.updateSize(index, Size(logicalWidth, scaledHeight));
      },
      onError: (exception, stackTrace) {
        logger.e('Failed to resolve image size: $exception');
      },
    );
    _imageStream = newStream;
    _imageListener = newListener;
    newStream.addListener(newListener);
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
    final screenWidth = context.screenWidth;
    final pixelRatio = context.devicePixelRatio;
    final int cacheSize = (screenWidth * pixelRatio).round();

    return Container(
      color: Colors.black,
      child: Image.file(
        File(widget.imagePath),
        fit: isColumn ? BoxFit.fill : BoxFit.contain,
        cacheWidth: cacheSize,
        gaplessPlayback: true,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }

          if (isColumn) {
            final cubit = context.read<ImageSizeCubit>();
            final size = cubit.state.getSizeValue(widget.index + 1);
            return Container(
              width: size.width,
              height: size.height,
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
      ),
    );
  }
}
