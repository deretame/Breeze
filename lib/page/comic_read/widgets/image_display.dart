import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../config/global.dart';

class ImageDisplay extends StatefulWidget {
  final String imagePath;

  const ImageDisplay({super.key, required this.imagePath});

  @override
  State<ImageDisplay> createState() => _ImageDisplayState();
}

class _ImageDisplayState extends State<ImageDisplay> {
  double imageWidth = screenWidth;
  double imageHeight = screenWidth;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getImageResolution(widget.imagePath);
  }

  Future<void> _getImageResolution(String imagePath) async {
    final Image image = Image.file(File(imagePath));
    final ImageStream stream = image.image.resolve(ImageConfiguration());

    stream.addListener(
      ImageStreamListener(
        (ImageInfo imageInfo, _) {
          if (mounted) {
            setState(() {
              imageWidth = imageInfo.image.width.toDouble();
              imageHeight = imageInfo.image.height.toDouble();
              _isLoading = false;
            });
          }
        },
        onError: (exception, stackTrace) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Container(color: Color(0xFF2D2D2D)) // 加载中的占位符
        : AspectRatio(
            aspectRatio: imageWidth / imageHeight,
            child: Image.file(
              File(widget.imagePath),
              fit: BoxFit.cover,
            ),
          );
  }
}
