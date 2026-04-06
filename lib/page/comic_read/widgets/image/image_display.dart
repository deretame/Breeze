import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/comic_read/cubit/image_size_cubit.dart';
import 'package:zephyr/page/comic_read/cubit/reader_cubit.dart';

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
  Timer? _einkDelayTimer;

  double? _rawWidth;
  double? _rawHeight;
  bool _einkDelayFinished = true;
  bool _wasRowActive = false;

  bool get isColumn => widget.isColumn;

  @override
  void initState() {
    super.initState();
    if (isColumn) {
      _resolveImageMeta();
    } else {
      _startEinkDelayIfNeeded(
        context.read<GlobalSettingCubit>().state.readSetting,
      );
    }
  }

  @override
  void didUpdateWidget(covariant ImageDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isColumn) {
      if (!oldWidget.isColumn || widget.imagePath != oldWidget.imagePath) {
        _stopListening();
        _rawWidth = null;
        _rawHeight = null;
        _resolveImageMeta();
      }
      _einkDelayTimer?.cancel();
      _einkDelayFinished = true;
      _wasRowActive = false;
      return;
    }

    if (oldWidget.isColumn) {
      _stopListening();
    }

    if (widget.imagePath != oldWidget.imagePath || oldWidget.isColumn) {
      _startEinkDelayIfNeeded(
        context.read<GlobalSettingCubit>().state.readSetting,
      );
    }
  }

  void _startEinkDelayIfNeeded(ReadSettingState readSetting) {
    if (isColumn) {
      _einkDelayTimer?.cancel();
      _einkDelayFinished = true;
      return;
    }

    if (!readSetting.einkOptimization) {
      _einkDelayTimer?.cancel();
      _einkDelayFinished = true;
      return;
    }

    _einkDelayTimer?.cancel();
    _einkDelayFinished = false;
    final delayMs = readSetting.einkDelayMs.clamp(50, 500);
    _einkDelayTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      setState(() {
        _einkDelayFinished = true;
      });
    });
  }

  void _resolveImageMeta() {
    final imageProvider = FileImage(File(widget.imagePath));
    final newStream = imageProvider.resolve(ImageConfiguration.empty);

    final newListener = ImageStreamListener(
      (ImageInfo imageInfo, bool synchronousCall) {
        if (!mounted) return;

        _rawWidth = imageInfo.image.width.toDouble();
        _rawHeight = imageInfo.image.height.toDouble();

        if (context.mounted) {
          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null && renderBox.hasSize) {
            _updateCubitSize(renderBox.size.width);
          }
        }
      },
      onError: (exception, stackTrace) {
        logger.e('Failed to resolve image size: $exception');
      },
    );

    _imageStream = newStream;
    _imageListener = newListener;
    newStream.addListener(newListener);
  }

  void _updateCubitSize(double actualWidth) {
    if (_rawWidth == null || _rawHeight == null || _rawWidth == 0) return;

    final index = widget.index - 1;
    final cubit = context.read<ImageSizeCubit>();

    final double finalHeight = (_rawHeight! / _rawWidth!) * actualWidth;

    final currentCachedSize = cubit.getSize(index);

    if (!currentCachedSize.isCached ||
        (currentCachedSize.size.height - finalHeight).abs() > 0.5 ||
        (currentCachedSize.size.width - actualWidth).abs() > 0.5) {
      cubit.updateSize(index, Size(actualWidth, finalHeight));
    }
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
    _einkDelayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final readSetting = context.select(
      (GlobalSettingCubit c) => c.state.readSetting,
    );
    final brightness = Theme.of(context).brightness;
    final backgroundColor = readSetting.resolveReaderBackgroundColor(
      brightness,
    );
    final foregroundColor = readSetting.resolveReaderForegroundColor(
      brightness,
    );
    final progressColor = foregroundColor.withValues(alpha: 0.3);
    final readMode = context.select(
      (GlobalSettingCubit c) => c.state.readSetting.readMode,
    );
    final currentPageIndex = context.select(
      (ReaderCubit c) => c.state.pageIndex,
    );
    final canUseEinkMask =
        !isColumn && readMode != 0 && readSetting.einkOptimization;
    final isActiveRowImage = !isColumn && currentPageIndex + 1 == widget.index;

    if (canUseEinkMask && isActiveRowImage && !_wasRowActive) {
      _wasRowActive = true;
      _startEinkDelayIfNeeded(readSetting);
    } else if (!isActiveRowImage && _wasRowActive) {
      _wasRowActive = false;
    }

    if (!canUseEinkMask && !_einkDelayFinished) {
      _einkDelayTimer?.cancel();
      _einkDelayFinished = true;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (_rawWidth != null && isColumn) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _updateCubitSize(width);
          });
        }

        return Image.file(
          File(widget.imagePath),
          width: width,
          fit: isColumn ? BoxFit.fill : BoxFit.contain,
          gaplessPlayback: true,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) {
              if (!isColumn &&
                  canUseEinkMask &&
                  isActiveRowImage &&
                  !_einkDelayFinished) {
                return Container(width: width, color: Colors.white);
              }
              return child;
            }

            if (isColumn) {
              return Container(
                width: width,
                color: backgroundColor,
                alignment: Alignment.center,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: progressColor,
                  ),
                ),
              );
            } else {
              if (canUseEinkMask && isActiveRowImage && !_einkDelayFinished) {
                return Container(width: width, color: Colors.white);
              }
              return Container(
                width: width,
                color: backgroundColor,
                alignment: Alignment.center,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: progressColor,
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
}
