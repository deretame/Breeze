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

  @override
  void initState() {
    super.initState();
    _getImageResolution(widget.imagePath);
  }

  void _getImageResolution(String imagePath) {
    final Image image = Image.file(File(imagePath));

    // 监听图片解析完成
    image.image
        .resolve(ImageConfiguration())
        .addListener(
          ImageStreamListener((ImageInfo imageInfo, _) {
            if (mounted) {
              setState(() {
                imageWidth = imageInfo.image.width.toDouble();
                imageHeight = imageInfo.image.height.toDouble();
              });
            }
          }),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      width: screenWidth,
      height:
          imageHeight != screenWidth
              ? (imageHeight * (screenWidth / imageWidth))
              : screenWidth,
      child:
          imageWidth != screenWidth && imageHeight != screenWidth
              ? Image.file(File(widget.imagePath), fit: BoxFit.fill)
              : Container(color: const Color(0xFF2D2D2D)), // 占位符
    );
  }
}
