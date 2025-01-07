import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:image/image.dart';

Future<String> compressImage(File originalFile) async {
  List<int> imageBytes = await originalFile.readAsBytes();
  var decodedImage = decodeImage(Uint8List.fromList(imageBytes));

  // 将原始图像转换为 base64 字符串
  String base64String = base64Encode(imageBytes);
  int originalBase64Length = base64String.length;

  // 计算压缩比
  double compressionRatio = 680000 / originalBase64Length;
  int quality = (compressionRatio * 100).toInt();
  quality = quality.clamp(1, 100); // 确保 quality 在 1 到 100 之间

  // 压缩图像
  var compressedBytes = encodeJpg(decodedImage!, quality: quality);

  // 再次检查压缩后的 base64 长度
  String compressedBase64String = base64Encode(compressedBytes);
  if (compressedBase64String.length > 680000) {
    // 如果仍然超过长度限制，可以进一步降低 quality
    quality = (quality * 0.9).toInt(); // 降低 quality 10%
    compressedBytes = encodeJpg(decodedImage, quality: quality);
  }

  // 最终压缩后的 base64 字符串
  String finalBase64String = base64Encode(compressedBytes);
  debugPrint('Final Base64 Length: ${finalBase64String.length}');

  return finalBase64String;
}
