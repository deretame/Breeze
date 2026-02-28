import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path/path.dart' as p;
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
              icon: const Icon(Icons.close, color: Colors.white),
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

                if (Platform.isWindows ||
                    Platform.isLinux ||
                    Platform.isMacOS) {
                  // 桌面端使用文件选择器
                  try {
                    var result = await _saveImageWithSelector(imagePath);
                    if (result.isNotEmpty) {
                      showSuccessToast("图片已保存至: $result");
                    }
                  } catch (e, s) {
                    logger.e("桌面端保存图片失败", error: e, stackTrace: s);
                    showErrorToast("图片保存失败！\n${e.toString()}");
                  }
                } else if (Platform.isAndroid || Platform.isIOS) {
                  // 移动端 (iOS & Android) 使用 gal 插件保存到相册
                  await _saveImageMobile(imagePath);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // 桌面端保存逻辑：弹出目录选择器
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

  // 移动端保存逻辑：利用 gal 写入系统相册
  Future<void> _saveImageMobile(String inputImagePath) async {
    try {
      // 检查是否已有相册写入权限，如果没有则申请
      if (!await Gal.hasAccess()) {
        await Gal.requestAccess();
      }

      // 将图片放入相册
      await Gal.putImage(
        inputImagePath,
        album: Platform.isIOS ? null : appName,
      );
      showSuccessToast("图片已保存到相册！");
    } on GalException catch (e) {
      logger.e("Gal 保存异常", error: e);
      // 根据 GalException 的类型给出更精确的提示
      if (e.type == GalExceptionType.accessDenied) {
        showErrorToast("保存失败: 请在系统设置中授予相册访问权限");
      } else {
        showErrorToast("保存失败: ${e.type.message}");
      }
    } catch (e, s) {
      logger.e("移动端保存图片发生未知异常", error: e, stackTrace: s);
      showErrorToast("图片保存失败！");
    }
  }
}
