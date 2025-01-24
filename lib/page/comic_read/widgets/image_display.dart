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

  Future<ImageInfo>? _imageInfoFuture;

  @override
  void initState() {
    super.initState();
    _imageInfoFuture = _getImageResolution(widget.imagePath);
  }

  Future<ImageInfo> _getImageResolution(String imagePath) async {
    final Completer<ImageInfo> completer = Completer();
    final Image image = Image.file(File(imagePath));

    image.image.resolve(ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo imageInfo, _) {
        completer.complete(imageInfo);
      }),
    );

    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ImageInfo>(
      future: _imageInfoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          final imageInfo = snapshot.data!;
          imageWidth = imageInfo.image.width.toDouble();
          imageHeight = imageInfo.image.height.toDouble();
        }

        return AspectRatio(
          aspectRatio: imageWidth / imageHeight,
          child: imageWidth != screenWidth && imageHeight != screenWidth
              ? Image.file(File(widget.imagePath), fit: BoxFit.cover)
              : Container(color: Color(0xFF2D2D2D)),
        );
      },
    );
  }
}
