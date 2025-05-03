import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../../../../network/http/bika/http_request.dart';
import '../../../../../type/stack.dart';
import '../../../json/bika/comic_info/comic_info.dart';
import '../../../json/bika/eps/eps.dart';

part 'get_comic_eps_event.dart';
part 'get_comic_eps_state.dart';

const _throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> _throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class GetComicEpsBloc extends Bloc<GetComicEpsEvent, GetComicEpsState> {
  GetComicEpsBloc() : super(GetComicEpsState()) {
    on<GetComicEpsEvent>(
      _fetchEps,
      transformer: _throttleDroppable(_throttleDuration),
    );
  }

  Future<void> _fetchEps(
    GetComicEpsEvent event,
    Emitter<GetComicEpsState> emit,
  ) async {
    try {
      emit(state.copyWith(status: GetComicEpsStatus.initial));

      var eps = await _getEps(event.comic);

      emit(state.copyWith(status: GetComicEpsStatus.success, eps: eps));
    } catch (e) {
      emit(
        state.copyWith(status: GetComicEpsStatus.failure, result: e.toString()),
      );
    }
  }

  Future<List<Doc>> _getEps(Comic comic) async {
    List<Doc> eps = [];
    StackList epsStack = StackList();
    for (int i = 1; i <= (comic.epsCount / 40 + 1); i++) {
      var result = await getEps(comic.id, i);
      epsStack.push(Eps.fromJson(result).data.eps);
    }

    if (epsStack.isEmpty) {
      throw Exception("获取数据失败");
    }

    List<EpsClass> epsList = [];
    while (epsStack.isNotEmpty) {
      epsList.add(epsStack.pop());
    }

    if (epsList.isEmpty) {
      throw Exception("获取数据失败");
    }

    while (epsList.isNotEmpty) {
      EpsClass ep = epsList.removeAt(0);
      StackList epStackList = StackList();
      for (int i = 0; i < ep.docs.length; i++) {
        epStackList.push(ep.docs[i]);
      }

      while (epStackList.isNotEmpty) {
        eps.add(epStackList.pop());
      }
    }
    return eps;
  }
}
