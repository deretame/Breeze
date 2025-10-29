import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/widgets/toast.dart';

import '../main.dart';

@RoutePage()
class ImageCropPage extends StatefulWidget {
  final Uint8List imageData;

  const ImageCropPage({super.key, required this.imageData});

  @override
  State<ImageCropPage> createState() => _ImageCropPageState();
}

class _ImageCropPageState extends State<ImageCropPage> {
  final _cropController = CropController();
  var _isCropping = false;
  var _statusText = '正在加载图片';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('裁剪图片'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _cropImage),
        ],
      ),
      body: Center(
        child: _isCropping
            ? const CircularProgressIndicator()
            : Crop(
                controller: _cropController,
                image: widget.imageData,
                onCropped: (result) {
                  setState(() => _isCropping = false);
                  switch (result) {
                    case CropSuccess(:final croppedImage):
                      context.maybePop(croppedImage);
                    case CropFailure(:final cause):
                      logger.e(cause);
                      showErrorToast("裁剪失败 ${cause.toString()}");
                      context.maybePop(null);
                  }
                },
                aspectRatio: 1,
                fixCropRect: false,
                initialRectBuilder: InitialRectBuilder.withBuilder((
                  viewportRect,
                  imageRect,
                ) {
                  // 初始裁剪区域为图片中心的正方形
                  final size = viewportRect.shortestSide * 1.0;
                  final center = viewportRect.center;
                  return Rect.fromCenter(
                    center: center,
                    width: size,
                    height: size,
                  );
                }),
                onStatusChanged: (status) => setState(() {
                  _statusText =
                      <CropStatus, String>{
                        CropStatus.nothing: '没有图片数据',
                        CropStatus.loading: '正在加载图片',
                        CropStatus.ready: '图片加载成功',
                        CropStatus.cropping: '正在裁剪',
                      }[status] ??
                      '';
                }),
                overlayBuilder: (context, rect) {
                  return CustomPaint(painter: _GridPainter());
                },
              ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(_statusText, textAlign: TextAlign.center),
      ),
    );
  }

  void _cropImage() {
    setState(() {
      _isCropping = true;
    });
    _cropController.crop();
  }
}

class _GridPainter extends CustomPainter {
  final divisions = 2;
  final strokeWidth = 1.0;
  final Color color = Colors.black54;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..color = color;

    final spacing = size / (divisions + 1);
    for (var i = 1; i < divisions + 1; i++) {
      // 画垂直线
      canvas.drawLine(
        Offset(spacing.width * i, 0),
        Offset(spacing.width * i, size.height),
        paint,
      );

      // 画水平线
      canvas.drawLine(
        Offset(0, spacing.height * i),
        Offset(size.width, spacing.height * i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}
