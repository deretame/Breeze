import 'dart:io';
import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zephyr/src/rust/api/simple.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/util/sundry.dart';
import 'package:zephyr/widgets/toast.dart';

import '../../../config/global/global.dart';
import '../../../main.dart';
import '../../../network/http/bika/http_request.dart';

Widget divider() {
  return Align(
    alignment: Alignment.center,
    child: SizedBox(
      width: screenWidth * (48 / 50), // 设置宽度
      child: Observer(
        builder:
            (context) => Divider(
              color:
                  globalSetting.themeType
                      ? materialColorScheme.secondaryFixedDim
                      : materialColorScheme.secondaryFixedDim,
              thickness: 1,
              height: 10,
            ),
      ),
    ),
  );
}

Widget changeProfilePicture(StackRouter route) {
  final ImagePicker picker = ImagePicker();
  String selectedImages = '';
  return GestureDetector(
    onTap: () async {
      try {
        var response = await picker.pickImage(source: ImageSource.gallery);
        logger.d('Response: ${response.toString()}'); // 输出响应内容

        var files = response?.path;
        if (files != null && files.isNotEmpty) {
          selectedImages = files; // 更新选择的图片

          logger.d('Selected image path: $files'); // 输出选择的图片路径
        } else {
          return;
        }
        var fileExtension = files.split(".").last;
        if (fileExtension != "jpg" &&
            fileExtension != "png" &&
            fileExtension != "jpeg" &&
            fileExtension != "webp") {
          showErrorToast("仅支持jpg、png、jpeg、webp格式的图片");
          return;
        }
      } catch (_) {
        return;
      }
      try {
        if (selectedImages.isEmpty) {
          return;
        }
        final croppedFile = await route.push<Uint8List?>(
          ImageCropRoute(imageData: await File(selectedImages).readAsBytes()),
        );
        if (croppedFile == null) {
          return;
        }

        showInfoToast("正在上传头像...");

        await updateAvatar(await compressImage(imageBytes: croppedFile));
        showSuccessToast("成功上传头像");
      } catch (e) {
        showErrorToast(
          "上传头像失败: ${e.toString()}",
          duration: const Duration(seconds: 5),
        );
      }
    },
    behavior: HitTestBehavior.opaque, // 使得所有透明区域也可以响应点击
    child: Row(
      children: [
        SizedBox(width: 10),
        Text("更新头像", style: TextStyle(fontSize: 18)),
        Expanded(child: Container()),
        Icon(Icons.chevron_right),
        SizedBox(width: 10),
      ],
    ),
  );
}

Widget changeBriefIntroduction(BuildContext context) {
  return GestureDetector(
    onTap: () async {
      var text = await _showInputDialog(context, "更新简介", "请输入新的简介");
      if (text.isNotEmpty) {
        showInfoToast('正在更新简介...');
        try {
          await updateProfile(text);
          showSuccessToast("成功更新简介");
        } catch (e) {
          showErrorToast(
            "更新简介失败: ${e.toString()}",
            duration: const Duration(seconds: 5),
          );
        }
      }
    },
    behavior: HitTestBehavior.opaque,
    child: Row(
      children: [
        SizedBox(width: 10),
        Text("更新简介", style: TextStyle(fontSize: 18)),
        Expanded(child: Container()),
        Icon(Icons.chevron_right),
        SizedBox(width: 10),
      ],
    ),
  );
}

Widget changePassword(BuildContext context) {
  return GestureDetector(
    onTap: () async {
      var text = await _showInputDialog(context, "更新密码", "请输入新的密码");
      if (text.isNotEmpty) {
        showInfoToast('正在更新密码...');
        try {
          await updatePassword(text);
          showSuccessToast("成功更新密码");
        } catch (e) {
          showErrorToast(
            "更新密码失败: ${e.toString()}",
            duration: const Duration(seconds: 5),
          );
        }
      }
    },
    behavior: HitTestBehavior.opaque,
    child: Row(
      children: [
        SizedBox(width: 10),
        Text("更新密码", style: TextStyle(fontSize: 18)),
        Expanded(child: Container()),
        Icon(Icons.chevron_right),
        SizedBox(width: 10),
      ],
    ),
  );
}

Widget changeShieldedCategories(BuildContext context, String type) {
  return GestureDetector(
    onTap: () async {
      if (type == "home") {
        late var oldCategoriesMap = Map.of(
          bikaSetting.shieldHomePageCategoriesMap,
        );
        var categoriesShield = await showShieldCategoryDialog(context, type);
        if (categoriesShield == null) {
          return;
        }

        if (oldCategoriesMap == categoriesShield) {
          return;
        }

        bikaSetting.setShieldHomeCategories(categoriesShield);

        showSuccessToast("成功更新首页屏蔽项，请刷新首页查看效果");
      } else if (type == "categories") {
        late var oldCategoriesMap = Map.of(bikaSetting.shieldCategoryMap);
        var categoriesShield = await showShieldCategoryDialog(context, type);
        if (categoriesShield == null) {
          return;
        }

        if (oldCategoriesMap == categoriesShield) {
          return;
        }

        bikaSetting.setShieldCategoryMap(categoriesShield);

        showSuccessToast("成功更新屏蔽分类");
      }
    },
    behavior: HitTestBehavior.opaque,
    child: Row(
      children: [
        SizedBox(width: 10),
        Text(type == "home" ? "首页屏蔽" : "分类屏蔽", style: TextStyle(fontSize: 18)),
        Expanded(child: Container()),
        Icon(Icons.chevron_right),
        SizedBox(width: 10),
      ],
    ),
  );
}

Future<Map<String, bool>?> showShieldCategoryDialog(
  BuildContext context,
  String type,
) {
  Map<String, bool> shieldCategoriesMap = {};
  if (type == "home") {
    shieldCategoriesMap = Map.of(bikaSetting.shieldHomePageCategoriesMap);
  } else if (type == "categories") {
    shieldCategoriesMap = Map.of(bikaSetting.shieldCategoryMap);
  }

  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('选择屏蔽分类'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            List<Widget> checkboxes = [];
            shieldCategoriesMap.forEach((key, value) {
              checkboxes.add(
                CheckboxListTile(
                  title: Text(key.let(t2s)),
                  value: shieldCategoriesMap[key],
                  onChanged: (bool? newValue) {
                    setState(() {
                      shieldCategoriesMap[key] = newValue!;
                    });
                  },
                ),
              );
            });
            return SizedBox(
              width: screenWidth * 0.8, // 设置对话框宽度
              height: screenHeight * 0.6, // 设置对话框高度
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: checkboxes,
                ),
              ),
            );
          },
        ),
        actions: <Widget>[
          TextButton(child: Text('取消'), onPressed: () => context.pop()),
          TextButton(
            child: Text('提交'),
            onPressed: () => context.pop(shieldCategoriesMap),
          ),
        ],
      );
    },
  ).then((value) {
    if (value != null) {
      logger.d('Checkbox values: $value');
    }
    return value;
  });
}

// 弹出输入框对话框
Future<String> _showInputDialog(
  BuildContext context,
  String tile,
  String defaultText,
) async {
  final TextEditingController controller = TextEditingController();

  // 显示对话框并等待响应
  String? result = await showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(tile),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: defaultText),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('取消'),
            onPressed: () {
              context.pop();
            },
          ),
          TextButton(
            child: Text('确认'),
            onPressed: () {
              Navigator.of(context).pop(controller.text);
            },
          ),
        ],
      );
    },
  );

  return result ?? "";
}
