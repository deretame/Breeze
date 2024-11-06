import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../json/comic/comic_info.dart';
import '../../../../../../json/comic/eps.dart';
import '../../../../../../network/http/http_request.dart';
import '../../../../../../type/stack.dart';

abstract class EpsEvent {}

class FetchEpsEvent extends EpsEvent {}

class EpsState {
  final List<Doc> eps;
  final bool isLoading;
  final String? error;

  EpsState({this.eps = const [], this.isLoading = false, this.error});

  EpsState copyWith({List<Doc>? eps, bool? isLoading, String? error}) {
    return EpsState(
      eps: eps ?? this.eps,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class EpsBloc extends Bloc<EpsEvent, EpsState> {
  final ComicInfo comicInfo;

  EpsBloc({required this.comicInfo}) : super(EpsState()) {
    on<FetchEpsEvent>((event, emit) async {
      emit(state.copyWith(isLoading: true));
      try {
        List<Doc> eps = await fetchEp();
        emit(state.copyWith(eps: eps, isLoading: false));
      } catch (e) {
        emit(state.copyWith(error: e.toString(), isLoading: false));
      }
    });
  }

  Future<List<Doc>> fetchEp() async {
    List<Doc> eps = [];
    StackList epsStack = StackList();
    for (int i = 1; i <= (comicInfo.data.comic.epsCount / 40 + 1); i++) {
      var result = await getEps(comicInfo.data.comic.id, i);
      epsStack.push(Eps.fromJson(result).data);
    }

    if (epsStack.isEmpty) {
      throw Exception("No Episodes Found");
    }

    List<Eps> epsList = [];
    while (epsStack.isNotEmpty) {
      epsList.add(epsStack.pop());
    }

    if (epsList.isEmpty) {
      throw Exception("No Episodes Found");
    }

    while (epsList.isNotEmpty) {
      var ep = epsList.removeAt(0);
      StackList epStackList = StackList();
      for (int i = 0; i < ep.data.eps.docs.length; i++) {
        epStackList.push(ep.data.eps.docs[i]);
      }

      while (epStackList.isNotEmpty) {
        add(epStackList.pop());
      }
    }

    return eps;
  }
}
