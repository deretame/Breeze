import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_guard/permission_guard.dart';
import 'package:photo_view/photo_view.dart';
import 'package:zephyr/config/global/global.dart';
import 'package:zephyr/widgets/toast.dart';

import '../main.dart';

@RoutePage()
class FullScreenImagePage extends StatelessWidget {
  final String imagePath;

  const FullScreenImagePage({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 图片部分
          PhotoView(
            imageProvider: FileImage(File(imagePath)),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            initialScale: PhotoViewComputedScale.contained,
          ),

          // 关闭按钮
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),

          // 下载按钮
          Positioned(
            bottom: 20,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              onPressed: () async {
                logger.d("download image");
                try {
                  if (Platform.isWindows ||
                      Platform.isLinux ||
                      Platform.isMacOS ||
                      Platform.isIOS) {
                    // 桌面端及 iOS 使用文件选择器
                    var result = await _saveImageWithSelector(imagePath);
                    if (result.isNotEmpty) {
                      showSuccessToast("图片已保存至: $result");
                    }
                  } else {
                    // Android 端需要权限
                    if (await Permission.photos.request().isGranted ||
                        await Permission.storage.request().isGranted) {
                      var result = await _saveImageAndroid(imagePath);
                      if (result.isNotEmpty) {
                        showSuccessToast("图片已保存到相册！");
                      } else {
                        showErrorToast("图片保存失败！");
                      }
                    } else {
                      showErrorToast("请授予访问相册的权限！");
                    }
                  }
                } catch (e, s) {
                  logger.e("保存图片失败", error: e, stackTrace: s);
                  showErrorToast("图片保存失败！\n${e.toString()}");
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _saveImageWithSelector(String inputImagePath) async {
    final inputFile = File(inputImagePath);
    final ext = p.extension(inputImagePath).toLowerCase();

    final typeGroup = XTypeGroup(
      label: 'images',
      extensions: ext.isNotEmpty ? [ext.substring(1)] : ['jpg', 'png', 'jpeg'],
    );

    final result = await getSaveLocation(
      suggestedName: inputFile.uri.pathSegments.last,
      acceptedTypeGroups: [typeGroup],
    );

    if (result == null) {
      return ''; // 用户取消了选择
    }

    await inputFile.copy(result.path);
    return result.path;
  }

  Future<String> _saveImageAndroid(String inputImagePath) async {
    if (!await Permission.storage.request().isGranted) {
      return '';
    }

    String picturesDir = '';
    try {
      final dirs = await getExternalStorageDirectories(
        type: StorageDirectory.pictures,
      );
      if (dirs != null && dirs.isNotEmpty) {
        picturesDir = p.join(dirs.first.path, appName);
      }
    } catch (e) {
      logger.e('Failed to get external storage directories: $e');
    }

    if (picturesDir.isEmpty) {
      picturesDir = p.join('/storage/emulated/0/Pictures', appName);
    }

    logger.d('Pictures directory: $picturesDir');

    // 确保目录存在
    final pictureDirectory = Directory(picturesDir);
    if (!await pictureDirectory.exists()) {
      await pictureDirectory.create(recursive: true);
    }

    // 输入图片文件和目标路径
    final inputFile = File(inputImagePath);
    final newFilePath = p.join(picturesDir, inputFile.uri.pathSegments.last);

    // 复制图片
    await inputFile.copy(newFilePath);

    return newFilePath;
  }
}
