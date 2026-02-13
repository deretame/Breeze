import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zephyr/type/enum.dart';

part 'picture_info.freezed.dart';
part 'picture_info.g.dart';

@freezed
abstract class PictureInfo with _$PictureInfo {
  const factory PictureInfo({
    @Default(From.bika) From from, // 从那个漫画网站获取的
    @Default('') String url, // 网址
    @Default('') String path, // 路径
    @Default('') String cartoonId, // 漫画id
    @Default('') String chapterId, // 章节id
    @Default(PictureType.comic) PictureType pictureType, // 图片类型
  }) = _PictureInfo;

  factory PictureInfo.fromJson(Map<String, dynamic> json) =>
      _$PictureInfoFromJson(json);
}
