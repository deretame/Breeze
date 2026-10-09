import 'package:freezed_annotation/freezed_annotation.dart';

part 'comic_preview_event.freezed.dart';

@freezed
abstract class LoadComicPreview with _$LoadComicPreview {
  const factory LoadComicPreview({@Default(false) bool loadMore}) =
      _LoadComicPreview;
}
