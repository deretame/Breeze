import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart';

import '../../../config/jm/config.dart';

String get baseUrl => JmConfig.imagesUrl;

String getJmCoverUrl(String id) {
  return '$baseUrl/media/albums/${id}_3x4.jpg';
}

String getJmImagesUrl(String id, String imageName) {
  return '$baseUrl/media/photos/$id/$imageName';
}

// 用来给compute传输图片数据
class JmPictureData {
  Uint8List imgData;
  int epsId;
  int scrambleId;
  String pictureName;

  JmPictureData(this.imgData, this.epsId, this.scrambleId, this.pictureName);
}

int getSegmentationNum(int epsId, int scrambleId, String pictureName) {
  int num = 0;

  if (epsId < scrambleId) {
    num = 0;
  } else if (epsId < 268850) {
    num = 10;
  } else if (epsId > 421926) {
    String string = epsId.toString() + pictureName;
    List<int> bytes = utf8.encode(string);
    String hash = md5.convert(bytes).toString();
    int charCode = hash.codeUnitAt(hash.length - 1);
    int remainder = charCode % 8;
    num = remainder * 2 + 2;
  } else {
    String string = epsId.toString() + pictureName;
    List<int> bytes = utf8.encode(string);
    String hash = md5.convert(bytes).toString();
    int charCode = hash.codeUnitAt(hash.length - 1);
    int remainder = charCode % 10;
    num = remainder * 2 + 2;
  }

  return num;
}

Uint8List segmentationPictureToDisk(JmPictureData pictureData) {
  Uint8List imgData = pictureData.imgData;
  int epsId = pictureData.epsId;
  int scrambleId = pictureData.scrambleId;
  String pictureName = pictureData.pictureName;

  final num = getSegmentationNum(epsId, scrambleId, pictureName);

  if (num <= 1) {
    return imgData;
  }

  Image srcImg;
  try {
    srcImg = decodeImage(imgData)!;
  } catch (e) {
    throw Exception(
      "Failed to decode image: Data length is ${imgData.length} bytes",
    );
  }

  int blockSize = (srcImg.height / num).floor();
  int remainder = srcImg.height % num;

  List<Map<String, int>> blocks = [];

  for (int i = 0; i < num; i++) {
    int start = i * blockSize;
    int end = start + blockSize + ((i != num - 1) ? 0 : remainder);
    blocks.add({'start': start, 'end': end});
  }

  Image desImg = Image(width: srcImg.width, height: srcImg.height);

  int y = 0;
  for (int i = blocks.length - 1; i >= 0; i--) {
    var block = blocks[i];
    int currBlockHeight = block['end']! - block['start']!;
    var range = srcImg.getRange(
      0,
      block['start']!,
      srcImg.width,
      currBlockHeight,
    );
    var desRange = desImg.getRange(0, y, srcImg.width, currBlockHeight);
    while (range.moveNext() && desRange.moveNext()) {
      desRange.current.r = range.current.r;
      desRange.current.g = range.current.g;
      desRange.current.b = range.current.b;
      desRange.current.a = range.current.a;
    }
    y += currBlockHeight;
  }

  return encodeJpg(desImg);
}
