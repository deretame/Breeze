import 'dart:io';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();

    _imageListener = ImageStreamListener((ImageInfo imageInfo, _) {
      if (mounted) {
        setState(() {
          imageWidth = imageInfo.image.width.toDouble();
          imageHeight = imageInfo.image.height.toDouble();
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (isColumn) {
      final imageProvider = FileImage(File(widget.imagePath));
      _imageStream = imageProvider.resolve(
        createLocalImageConfiguration(context),
      );
      _imageStream!.addListener(_imageListener);
    }
  }

  @override
  void dispose() {
    _imageStream?.removeListener(_imageListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int cacheSize =
        (context.screenWidth * MediaQuery.of(context).devicePixelRatio).round();

    return Container(
      color: Colors.black,
      width: context.screenWidth,
      height:
          imageHeight != 0
              ? (imageHeight * (context.screenWidth / imageWidth))
              : context.screenWidth,
      child:
          isColumn
              ? imageWidth != 0 && imageHeight != 0
                  ? Image.file(
                    File(widget.imagePath),
                    fit: BoxFit.fill,
                    cacheWidth: cacheSize,
                  )
                  : Container(color: const Color(0xFF2D2D2D))
              : Image.file(
                File(widget.imagePath),
                fit: BoxFit.contain,
                cacheWidth: cacheSize,
              ),
    );
  }
}
