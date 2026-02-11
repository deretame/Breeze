import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    _resolveImageSize();
  }

  void _resolveImageSize() {
    final index = widget.index + 1;
    final cubit = context.read<ImageSizeCubit>();

    final check = cubit.getSize(index);

    if (check.isCached) {
      return;
    }

    final imageProvider = FileImage(File(widget.imagePath));

    _imageStream = imageProvider.resolve(ImageConfiguration.empty);

    _imageListener = ImageStreamListener((
      ImageInfo imageInfo,
      bool synchronousCall,
    ) {
      if (!mounted) return;

      final double rawWidth = imageInfo.image.width.toDouble();
      final double rawHeight = imageInfo.image.height.toDouble();
      final double logicalWidth = cubit.state.defaultWidth;
      final double scaledHeight = (rawHeight / rawWidth) * logicalWidth;

      cubit.updateSize(index, Size(logicalWidth, scaledHeight));
    });

    _imageStream!.addListener(_imageListener!);
  }

  @override
  void dispose() {
    if (_imageListener != null) {
      _imageStream?.removeListener(_imageListener!);
    }
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
            );
          } else {
            return Container(color: Colors.black);
          }
        },
      ),
    );
  }
}
