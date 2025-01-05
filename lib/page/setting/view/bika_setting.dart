import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:image/image.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/util/router/router.gr.dart';

import '../../../config/global.dart';
import '../../../network/http/http_request.dart';

@RoutePage()
class BikaSettingPage extends StatefulWidget {
  const BikaSettingPage({super.key});

  @override
  State<BikaSettingPage> createState() => _BikaSettingPageState();
}

class _BikaSettingPageState extends State<BikaSettingPage> {
  late final List<String> shuntList = ["1", "2", "3"];
  late final Map<String, String> shunt = {
    "1": "1",
    "2": "2",
    "3": "3",
  };
  late final List<String> imageQualityList = [
    "low",
    "medium",
    "high",
    "original"
  ];
  late final Map<String, String> imageQuality = {
    "low": "低画质",
    "medium": "中画质",
    "high": "高画质",
    "original": "原图",
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('哔咔设置'),
      ),
      body: Observer(builder: (context) {
        return Column(
          children: [
            _changeProfilePicture(),
            SizedBox(height: 15),
            _changeBriefIntroduction(),
            SizedBox(height: 10),
            _divider(),
            _shuntWidget(),
            _imageQualityWidget(),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  bikaSetting.deleteAuthorization();
                  // bikaSetting.deleteAccount();
                  // bikaSetting.deletePassword();
                  AutoRouter.of(context).push(LoginRoute());
                },
                child: Text(
                  "退出登录",
                ),
              ),
            )
          ],
        );
      }),
    );
  }

  Widget _divider() {
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: screenWidth * (48 / 50), // 设置宽度
        child: Divider(
          color: globalSetting.themeType
              ? Colors.grey.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.5),
          thickness: 1,
          height: 10,
        ),
      ),
    );
  }

  Widget _changeProfilePicture() {
    final ImagePicker picker = ImagePicker();
    String selectedImages = '';
    return GestureDetector(
      onTap: () async {
        debugPrint("点击了更新头像");
        try {
          var response = await picker.pickImage(source: ImageSource.gallery);
          debugPrint('Response: ${response.toString()}'); // 输出响应内容

          var files = response?.path;
          if (files != null && files.isNotEmpty) {
            setState(() {
              selectedImages = files; // 更新选择的图片
            });
            debugPrint('Selected image path: $files'); // 输出选择的图片路径
          } else {
            debugPrint('No files found.');
            return;
          }
        } catch (e) {
          debugPrint('Error retrieving lost data: ${e.toString()}');
        }

        if (selectedImages.isNotEmpty) {
          final croppedFile = await ImageCropper().cropImage(
            sourcePath: selectedImages,
            compressFormat: ImageCompressFormat.jpg,
            compressQuality: 100,
            uiSettings: [
              AndroidUiSettings(
                toolbarTitle: '裁剪图片',
                toolbarColor: Colors.deepOrange,
                toolbarWidgetColor: Colors.white,
                initAspectRatio: CropAspectRatioPreset.square,
                lockAspectRatio: true,
                aspectRatioPresets: [
                  CustomizedAspectRatioPresetData(),
                ],
              ),
            ],
          );
          if (croppedFile != null) {
            setState(() {
              selectedImages = croppedFile.path;
            });
          } else {
            return;
          }
        }

        EasyLoading.show(status: '正在上传头像...');
        try {
          await updateAvatar(await compressImage(File(selectedImages)));
          EasyLoading.showInfo("成功上传头像");
        } catch (e) {
          EasyLoading.showError("上传头像失败: ${e.toString()}");
        }
      },
      behavior: HitTestBehavior.opaque, // 使得所有透明区域也可以响应点击
      child: Row(
        children: [
          SizedBox(width: 10),
          Text(
            "更新头像",
            style: TextStyle(
              fontSize: 18,
            ),
          ),
          Expanded(child: Container()),
          Icon(Icons.chevron_right),
          SizedBox(width: 10),
        ],
      ),
    );
  }

  Future<String> compressImage(File originalFile) async {
    List<int> imageBytes = await originalFile.readAsBytes();
    var decodedImage = decodeImage(Uint8List.fromList(imageBytes));

    // 将原始图像转换为 base64 字符串
    String base64String = base64Encode(imageBytes);
    int originalBase64Length = base64String.length;

    // 计算压缩比
    double compressionRatio = 1400000 / originalBase64Length;
    int quality = (compressionRatio * 100).toInt();
    quality = quality.clamp(1, 100); // 确保 quality 在 1 到 100 之间

    // 压缩图像
    var compressedBytes = encodeJpg(decodedImage!, quality: quality);

    // 再次检查压缩后的 base64 长度
    String compressedBase64String = base64Encode(compressedBytes);
    if (compressedBase64String.length > 1400000) {
      // 如果仍然超过长度限制，可以进一步降低 quality
      quality = (quality * 0.9).toInt(); // 降低 quality 10%
      compressedBytes = encodeJpg(decodedImage, quality: quality);
    }

    // 最终压缩后的 base64 字符串
    String finalBase64String = base64Encode(compressedBytes);
    debugPrint('Final Base64 Length: ${finalBase64String.length}');

    return finalBase64String;
  }

  Widget _changeBriefIntroduction() {
    return GestureDetector(
      onTap: () async {
        var text = await _showInputDialog(context);
        if (text.isNotEmpty) {
          EasyLoading.show(status: '正在更新简介...');
          try {
            await updateProfile(text); // 假设你有这个方法
            EasyLoading.showInfo("成功更新简介");
          } catch (e) {
            EasyLoading.showError("更新简介失败: ${e.toString()}");
          }
        }
      },
      behavior: HitTestBehavior.opaque, // 使得所有透明区域也可以响应点击
      child: Row(
        children: [
          SizedBox(width: 10),
          Text(
            "更新简介",
            style: TextStyle(
              fontSize: 18,
            ),
          ),
          Expanded(child: Container()),
          Icon(Icons.chevron_right),
          SizedBox(width: 10),
        ],
      ),
    );
  }

  // 弹出输入框对话框
  Future<String> _showInputDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController();

    // 显示对话框并等待响应
    String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('请输入信息'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: "输入你的内容"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('取消'),
              onPressed: () {
                Navigator.of(context).pop(); // 直接关闭对话框
              },
            ),
            TextButton(
              child: Text('确认'),
              onPressed: () {
                // 将用户输入传递出去
                Navigator.of(context).pop(controller.text);
              },
            ),
          ],
        );
      },
    );

    // 返回用户输入或 null（如果用户点击了取消）
    return result ?? ""; // 如果是取消则返回空字符串
  }

  Widget _shuntWidget() {
    return Row(
      children: [
        SizedBox(width: 10),
        Text(
          "分流设置",
          style: TextStyle(
            fontSize: 18,
          ),
        ),
        Expanded(child: Container()),
        DropdownButton<String>(
          value: bikaSetting.getProxy().toString(),
          icon: const Icon(Icons.expand_more),
          onChanged: (String? value) {
            setState(() {
              bikaSetting.setProxy(int.parse(value!));
            });
          },
          items: shuntList.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(shunt[value]!),
            );
          }).toList(),
          style: TextStyle(
            color: globalSetting.textColor,
            fontSize: 18,
          ),
        ),
        SizedBox(width: 10),
      ],
    );
  }

  Widget _imageQualityWidget() {
    return Row(
      children: [
        SizedBox(width: 10),
        Text(
          "图片质量",
          style: TextStyle(
            fontSize: 18,
          ),
        ),
        Expanded(child: Container()),
        DropdownButton<String>(
          value: bikaSetting.getImageQuality(),
          icon: const Icon(Icons.expand_more),
          onChanged: (String? value) {
            setState(() {
              // 删除缓存避免出问题
              cacheInterceptor.clear();
              bikaSetting.setImageQuality(value!);
            });
          },
          items: imageQualityList.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(imageQuality[value]!),
            );
          }).toList(),
          style: TextStyle(
            color: globalSetting.textColor,
            fontSize: 18,
          ),
        ),
        SizedBox(width: 10),
      ],
    );
  }
}

class CustomizedAspectRatioPresetData implements CropAspectRatioPresetData {
  @override
  (int, int)? get data => (1, 1);

  @override
  String get name => '1:1';
}
