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

  bool _isMounted = false; // 标志，指示 Widget 是否仍挂载

  @override
  void initState() {
    super.initState();
    _isMounted = true; // Widget 初始化时认为它是挂载的
    _getImageResolution(widget.imagePath);
  }

  Future<void> _getImageResolution(String imagePath) async {
    final Completer<void> completer = Completer();
    final Image image = Image.file(File(imagePath));

    // 监听图片解析完成
    image.image.resolve(ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo imageInfo, _) {
        // 只有在 Widget 仍挂载时才调用 setState
        if (_isMounted) {
          setState(() {
            imageWidth = imageInfo.image.width.toDouble();
            imageHeight = imageInfo.image.height.toDouble();
          });
        }
        completer.complete();
      }),
    );

    await completer.future; // 等待解析完成
  }

  @override
  void dispose() {
    _isMounted = false; // Widget 暴露时，设置为未挂载
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      width: screenWidth,
      height: imageHeight != screenWidth
          ? (imageHeight * (screenWidth / imageWidth))
          : screenWidth, // 动态计算高度
      child: imageWidth != screenWidth && imageHeight != screenWidth
          ? Image.file(
              File(widget.imagePath),
              fit: BoxFit.cover, // 使图片填充整个屏幕
            )
          : Container(color: Color(0xFF2D2D2D)), // 占位符
    );
  }
}
