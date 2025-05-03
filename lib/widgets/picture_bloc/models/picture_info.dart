import 'package:equatable/equatable.dart';

class PictureInfo extends Equatable {
  final String from; // 从那个漫画网站获取的
  final String url; // 网址
  final String path; // 路径
  final String cartoonId; // 漫画id
  final String chapterId; // 章节id
  final String pictureType; // 图片类型

  const PictureInfo({
    this.from = '',
    this.url = '',
    this.path = '',
    this.cartoonId = '',
    this.chapterId = '',
    this.pictureType = '',
  });

  PictureInfo copyWith({
    String? from,
    String? url,
    String? path,
    String? cartoonId,
    String? chapterId,
    String? pictureType,
  }) {
    return PictureInfo(
      from: from ?? this.from,
      url: url ?? this.url,
      path: path ?? this.path,
      cartoonId: cartoonId ?? this.cartoonId,
      chapterId: chapterId ?? this.chapterId,
      pictureType: pictureType ?? this.pictureType,
    );
  }

  @override
  List<Object> get props => [
    from,
    url,
    path,
    cartoonId,
    pictureType,
    chapterId,
  ];
}
