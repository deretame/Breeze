import 'dart:io';
import 'package:flutter/material.dart';
import '../../../config/global/global.dart';

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

class _ImageDisplayState extends State<ImageDisplay>
    with AutomaticKeepAliveClientMixin {
  ImageStream? _imageStream;
  late final ImageStreamListener _imageListener;

  bool get isColumn => widget.isColumn;

  double imageWidth = screenWidth;
  double imageHeight = screenWidth;

  @override
  bool get wantKeepAlive => true;

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
    super.build(context);
    return Container(
      color: Colors.black,
      width: screenWidth,
      height:
          imageHeight != screenWidth
              ? (imageHeight * (screenWidth / imageWidth))
              : screenWidth,
      child:
          isColumn
              ? imageWidth != screenWidth && imageHeight != screenWidth
                  ? Image.file(File(widget.imagePath), fit: BoxFit.fill)
                  : Container(color: const Color(0xFF2D2D2D))
              : Image.file(File(widget.imagePath), fit: BoxFit.contain),
    );
  }
}
