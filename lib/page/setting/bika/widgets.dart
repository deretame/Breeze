import 'dart:io';
import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zephyr/config/bika/bika_setting.dart';
import 'package:zephyr/src/rust/api/simple.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/util/sundry.dart';
import 'package:zephyr/widgets/toast.dart';

import '../../../main.dart';
import '../../../network/http/bika/http_request.dart';

Widget changeProfilePicture(StackRouter route) {
  final ImagePicker picker = ImagePicker();
  return ListTile(
    leading: const Icon(Icons.account_circle_outlined),
    title: const Text('更新头像'),
    subtitle: const Text('选择图片并裁剪后上传'),
    trailing: const Icon(Icons.chevron_right),
    onTap: () async {
      String selectedImages = '';
      try {
        var response = await picker.pickImage(source: ImageSource.gallery);
        logger.d('Response: ${response.toString()}');

        var files = response?.path;
        if (files != null && files.isNotEmpty) {
          selectedImages = files;

          logger.d('Selected image path: $files');
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
  );
}

Widget changeBriefIntroduction(BuildContext context) {
  return ListTile(
    leading: const Icon(Icons.short_text_outlined),
    title: const Text('更新简介'),
    subtitle: const Text('输入新简介并立即同步'),
    trailing: const Icon(Icons.chevron_right),
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
  );
}

Widget changePassword(BuildContext context) {
  return ListTile(
    leading: const Icon(Icons.password_outlined),
    title: const Text('更新密码'),
    subtitle: const Text('设置新密码并立即生效'),
    trailing: const Icon(Icons.chevron_right),
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
  );
}

Widget changeShieldedCategories(BuildContext context, String type) {
  final bikaCubit = context.read<BikaSettingCubit>();
  final bikaState = context.watch<BikaSettingCubit>().state;
  return ListTile(
    leading: Icon(
      type == "home" ? Icons.home_outlined : Icons.category_outlined,
    ),
    title: Text(type == "home" ? "首页屏蔽" : "分类屏蔽"),
    subtitle: const Text('选择分类，保存后立即生效'),
    trailing: const Icon(Icons.chevron_right),
    onTap: () async {
      if (type == "home") {
        final oldCategoriesMap = _withDefaultCategories(
          homePageCategoriesMap,
          bikaState.shieldHomePageCategoriesMap,
        );
        var categoriesShield = await showShieldCategoryDialog(context, type);
        if (categoriesShield == null) {
          return;
        }

        if (oldCategoriesMap == categoriesShield) {
          return;
        }

        bikaCubit.updateShieldHomePageCategoriesMap(categoriesShield);

        showSuccessToast("成功更新首页屏蔽项，请刷新首页查看效果");
      } else if (type == "categories") {
        final oldCategoriesMap = _withDefaultCategories(
          categoryMap,
          bikaState.shieldCategoryMap,
        );
        var categoriesShield = await showShieldCategoryDialog(context, type);
        if (categoriesShield == null) {
          return;
        }

        if (oldCategoriesMap == categoriesShield) {
          return;
        }

        bikaCubit.updateShieldCategoryMap(categoriesShield);

        showSuccessToast("成功更新屏蔽分类");
      }
    },
  );
}

Future<Map<String, bool>?> showShieldCategoryDialog(
  BuildContext context,
  String type,
) {
  final bikaCubit = context.read<BikaSettingCubit>();
  late final Map<String, bool> shieldCategoriesMap;
  if (type == "home") {
    shieldCategoriesMap = _withDefaultCategories(
      homePageCategoriesMap,
      bikaCubit.state.shieldHomePageCategoriesMap,
    );
  } else if (type == "categories") {
    shieldCategoriesMap = _withDefaultCategories(
      categoryMap,
      bikaCubit.state.shieldCategoryMap,
    );
  } else {
    shieldCategoriesMap = _withDefaultCategories(categoryMap, const {});
  }

  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('选择屏蔽分类'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            List<Widget> checkboxes = [];
            shieldCategoriesMap.forEach((key, value) {
              checkboxes.add(
                CheckboxListTile(
                  title: Text(key.let(t2s)),
                  value: shieldCategoriesMap[key],
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (bool? newValue) {
                    setState(() {
                      shieldCategoriesMap[key] = newValue!;
                    });
                  },
                ),
              );
            });
            return SizedBox(
              width: context.screenWidth * 0.8, // 设置对话框宽度
              height: context.screenHeight * 0.6, // 设置对话框高度
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
          TextButton(child: const Text('取消'), onPressed: () => context.pop()),
          FilledButton(
            child: const Text('提交'),
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

Map<String, bool> _withDefaultCategories(
  Map<String, bool> baseMap,
  Map<String, bool> selectedMap,
) {
  return {for (final key in baseMap.keys) key: selectedMap[key] ?? false};
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
          decoration: InputDecoration(
            hintText: defaultText,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('取消'),
            onPressed: () {
              context.pop();
            },
          ),
          FilledButton(
            child: const Text('确认'),
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
