import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_guard/permission_guard.dart';
import 'package:photo_view/photo_view.dart';
import 'package:zephyr/widgets/toast.dart';

import '../main.dart';

class FullScreenImageView extends StatelessWidget {
  final String imagePath;
  final String? uuid;
  final bool? showShade;

  const FullScreenImageView({
    super.key,
    required this.imagePath,
    this.uuid,
    this.showShade,
  });

  @override
  Widget build(BuildContext context) {
    String temp = uuid ?? "";
    final bool havaShade =
        globalSetting.shade && !globalSetting.themeType && (showShade ?? false);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoView(
            imageProvider: FileImage(File(imagePath)),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            initialScale: PhotoViewComputedScale.contained,
            heroAttributes: PhotoViewHeroAttributes(tag: imagePath + temp),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            bottom: 20, // 将图标放在底部
            right: 20, // 将图标放在右侧
            child: IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              onPressed: () async {
                debugPrint("download image");
                if (await Permission.photos.request().isGranted ||
                    await Permission.storage.request().isGranted) {
                  var result = await _copyImage2PicturesPath(imagePath);
                  if (result.isNotEmpty) {
                    showSuccessToast("图片已保存到相册！");
                  } else {
                    showErrorToast("图片保存失败！");
                  }
                } else {
                  showErrorToast("请授予访问相册的权限！");
                }
              },
            ),
          ),
          if (havaShade)
            // 遮罩层
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true, // 设置为 true，让遮罩层不响应触摸事件
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3), // 半透明黑色遮罩
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<String> _copyImage2PicturesPath(String inputImagePath) async {
    // 检查存储权限
    if (await Permission.storage.request().isGranted) {
      // 创建Pictures目录的完整路径
      final picturesDir = '/storage/emulated/0/Pictures/Breeze';
      debugPrint('Pictures directory: $picturesDir');

      // 确保Pictures目录存在
      final pictureDirectory = Directory(picturesDir);
      if (!await pictureDirectory.exists()) {
        await pictureDirectory.create(recursive: true);
      }

      // 输入图片文件和目标路径
      final inputFile = File(inputImagePath);
      final newFilePath = '$picturesDir/${inputFile.uri.pathSegments.last}';

      // 复制图片
      await inputFile.copy(newFilePath);

      return newFilePath;
    } else {
      // 权限被拒绝
      return '';
    }
  }
}
