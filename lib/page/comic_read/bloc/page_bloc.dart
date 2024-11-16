import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/page/comic_read/comic_read.dart';

import '../../../network/http/http_request.dart';

part 'page_event.dart';
part 'page_state.dart';

const throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class PageBloc extends Bloc<GetPage, PageState> {
  PageBloc() : super(PageState()) {
    on<GetPage>(
      _fetchPages,
      transformer: throttleDroppable(throttleDuration),
    );
  }

  Future<void> _fetchPages(
    GetPage event,
    Emitter<PageState> emit,
  ) async {
    emit(
      state.copyWith(
        status: PageStatus.initial,
      ),
    );

    try {
      final result = await _fetchMedia(event.comicId, event.epsId);

      emit(
        state.copyWith(
          status: PageStatus.success,
          medias: result,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PageStatus.failure,
          result: e.toString(),
        ),
      );
    }
  }

  Future<List<Media>> _fetchMedia(String comicId, int epsId) async {
    int page = 1, pages = 1;
    List<Media> mediaList = [];
    do {
      var result = await getPages(comicId, epsId, page);
      var temp = Page.fromJson(result);
      page += 1;
      pages = temp.data.pages.pages;
      for (var doc in temp.data.pages.docs) {
        mediaList.add(doc.media);
      }
    } while (page < pages);

    return mediaList;
  }
}
