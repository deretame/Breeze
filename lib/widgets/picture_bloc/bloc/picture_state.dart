import 'package:freezed_annotation/freezed_annotation.dart';

part 'picture_state.freezed.dart';

enum PictureLoadStatus { initial, success, failure }

@freezed
abstract class PictureLoadState with _$PictureLoadState {
  const factory PictureLoadState({
    @Default(PictureLoadStatus.initial) PictureLoadStatus status,
    String? imagePath,
    String? result,
  }) = _PictureLoadState;
}
