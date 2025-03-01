import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../config/global.dart';

class ImageDisplay extends StatelessWidget {
  final String imagePath;
  final bool isColumn;

  const ImageDisplay({
    super.key,
    required this.imagePath,
    required this.isColumn,
  });

  @override
  Widget build(BuildContext context) {
    return isColumn
        ? _buildAdaptiveImage()
        : Image.file(File(imagePath), fit: BoxFit.contain);
  }

  Widget _buildAdaptiveImage() {
    return FutureBuilder<Size>(
      future: _getImageSize(),
      builder: (context, snapshot) {
        final size = snapshot.data;
        return Container(
          color: Colors.black,
          width: screenWidth,
          height:
              size != null
                  ? screenWidth * size.height / size.width
                  : screenWidth,
          child: _buildImageContent(size),
        );
      },
    );
  }

  Widget _buildImageContent(Size? size) {
    return size != null
        ? Image.file(File(imagePath), fit: BoxFit.fill)
        : const Placeholder(color: Color(0xFF2D2D2D));
  }

  Future<Size> _getImageSize() async {
    final Completer<Size> completer = Completer();
    final ImageStream stream = FileImage(
      File(imagePath),
    ).resolve(ImageConfiguration());

    stream.addListener(
      ImageStreamListener(
        (ImageInfo info, _) {
          completer.complete(
            Size(info.image.width.toDouble(), info.image.height.toDouble()),
          );
        },
        onError: (error, stackTrace) {
          completer.complete(Size.zero); // 出错时返回 Size.zero
        },
      ),
    );

    return completer.future;
  }
}
