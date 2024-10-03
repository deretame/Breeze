import 'package:mmkv/mmkv.dart';

var mmkv = MMKV.defaultMMKV();

// 图片画质设置
void setImageQuality(String value) {
  mmkv.encodeString('image_quality', value);
}

String? getImageQuality() {
  return mmkv.decodeString('image_quality');
}

// 是否是第一次初始化
bool setFirstInit(bool value) {
  return mmkv.encodeBool('first_init', !value);
}

bool getFirstInit() {
  return !mmkv.decodeBool('first_init');
}
