import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zephyr/type/enum.dart';

part 'get_comic_info_event.freezed.dart';

@freezed
abstract class GetComicInfoEvent with _$GetComicInfoEvent {
  const factory GetComicInfoEvent({
    required String comicId,
    required String from,
    required ComicEntryType type,
    Map<String, dynamic>? extern,
  }) = _GetComicInfoEvent;
}
