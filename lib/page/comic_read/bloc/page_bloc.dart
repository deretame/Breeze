import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/type/pipe.dart';

import '../../../network/http/bika/http_request.dart';
import '../../../network/http/jm/http_request.dart';
import '../../../network/http/picture/picture.dart';
import '../../../type/enum.dart';
import '../../../util/json_dispose.dart';
import '../json/bika_ep_info_json/page.dart';
import '../json/common_ep_info_json/common_ep_info_json.dart' as c;
import '../json/jm_ep_info_json/jm_ep_info_json.dart';

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
      late final c.CommonEpInfoJson result;
      if (event.from == From.bika) {
        result = await _fetchBKMedia(event.comicId, event.epsId);
      } else if (event.from == From.jm) {
        result = await _fetchJMMedia(event.epsId.toString());
      }

      emit(state.copyWith(status: PageStatus.success, epInfo: result));
    } catch (e) {
      emit(state.copyWith(status: PageStatus.failure, result: e.toString()));
    }
  }

  Future<c.CommonEpInfoJson> _fetchBKMedia(String comicId, int epsId) async {
    int page = 1, pages = 1;
    List<c.Doc> docsList = [];
    String epId = '';
    String epName = '';
    do {
      var result = await getPages(comicId, epsId, page);
      var temp = Page.fromJson(result);
      epId = temp.data.ep.id;
      epName = temp.data.ep.title;
      page += 1;
      pages = temp.data.pages.pages;
      for (var doc in temp.data.pages.docs) {
        docsList.add(
          c.Doc(
            originalName: doc.media.originalName,
            path: doc.media.path,
            fileServer: doc.media.fileServer,
            id: doc.id,
          ),
        );
      }
    } while (page <= pages);

    return c.CommonEpInfoJson(
      epId: epId,
      epName: epName,
      series: [],
      docs: docsList,
    );
  }

  Future<c.CommonEpInfoJson> _fetchJMMedia(String epId) async {
    List<c.Doc> docsList = [];
    var result = c.CommonEpInfoJson(epId: '', epName: '', series: [], docs: []);
    await getEpInfo(
      epId,
    ).let(replaceNestedNull).let(JmEpInfoJson.fromJson).also((d) {
      for (var doc in d.images) {
        docsList.add(
          c.Doc(
            originalName: doc,
            path: doc,
            fileServer: getJmImagesUrl(epId, doc),
            id: d.id.let(toString),
          ),
        );
      }
      result = result.copyWith(
        epId: d.id.let(toString),
        epName: d.name,
        series: d.series
            .map(
              (s) => c.Series(
                id: s.id.let(toString),
                name: "第${s.sort}话 ${s.name}",
                sort: s.sort,
              ),
            )
            .toList()
            .let((d) => d..removeWhere((e) => e.sort == '0')),
        docs: docsList,
      );
    });

    return result;
  }
}
