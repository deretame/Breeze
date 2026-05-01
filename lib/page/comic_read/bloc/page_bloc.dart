import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/page/comic_read/method/get_local_info.dart';
import 'package:zephyr/page/comic_read/method/get_plugin_read_snapshot.dart';
import 'package:zephyr/page/comic_read/model/normal_comic_ep_info.dart';

import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/error_filter.dart';

part 'page_event.dart';
part 'page_state.dart';

const throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class PageBloc extends Bloc<PageEvent, PageState> {
  PageBloc() : super(PageState()) {
    on<PageEvent>(
      _fetchPages,
      transformer: throttleDroppable(throttleDuration),
    );
  }

  Future<void> _fetchPages(PageEvent event, Emitter<PageState> emit) async {
    emit(state.copyWith(status: PageStatus.initial));

    try {
      final isDownload =
          event.type == ComicEntryType.download ||
          event.type == ComicEntryType.historyAndDownload;

      late final NormalComicEpInfo result;
      if (isDownload) {
        result = await getPluginInfoFromLocal(
          event.from,
          event.comicId,
          event.epsId,
        );
      } else {
        result = await getPluginReadSnapshot(
          event.comicId,
          event.epsId,
          event.from,
          event.comicInfo,
        );
      }

      emit(state.copyWith(status: PageStatus.success, epInfo: result));
    } on StateError catch (_) {
      emit(state.copyWith(status: PageStatus.failure, result: "no element"));
    } catch (e) {
      emit(
        state.copyWith(
          status: PageStatus.failure,
          result: normalizeSearchErrorMessage(e),
        ),
      );
    }
  }
}
