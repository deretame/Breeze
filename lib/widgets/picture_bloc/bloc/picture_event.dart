import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zephyr/widgets/picture_bloc/models/models.dart';

part 'picture_event.freezed.dart';

@freezed
abstract class PictureEvent with _$PictureEvent {
  const factory PictureEvent.getPicture(
    PictureInfo pictureInfo, {
    @Default(true) bool usePlugin,
  }) = GetPicture;
}
