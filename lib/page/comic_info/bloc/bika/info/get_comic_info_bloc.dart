import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/comic_info/json/bika/eps/eps.dart' show Doc, Eps;
import 'package:zephyr/page/comic_info/json/bika/recommend/recommend_json.dart'
    as recommend_json;
import 'package:zephyr/page/comic_info/models/all_info.dart';

import '../../../../../network/http/bika/http_request.dart';
import '../../../json/bika/comic_info/comic_info.dart';

part 'get_comic_info_event.dart';
part 'get_comic_info_state.dart';

const _throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> _throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class GetComicInfoBloc extends Bloc<GetComicInfoEvent, GetComicInfoState> {
  GetComicInfoBloc() : super(GetComicInfoState()) {
    on<GetComicInfoEvent>(
      _fetchComicInfo,
      transformer: _throttleDroppable(_throttleDuration),
    );
  }

  Future<void> _fetchComicInfo(
    GetComicInfoEvent event,
    Emitter<GetComicInfoState> emit,
  ) async {
    try {
      emit(state.copyWith(status: GetComicInfoStatus.initial));

      var comicInfo = await _getComicInfo(event.comicId);
      final [eps, recommendJson] = await Future.wait([
        _getEps(comicInfo.data.comic),
        _fetchRecommend(event.comicId),
      ]);
      var allInfo = AllInfo(
        comicInfo: comicInfo.data.comic,
        eps: eps as List<Doc>,
        recommendJson: recommendJson as List<recommend_json.Comic>,
      );

      emit(
        state.copyWith(status: GetComicInfoStatus.success, allInfo: allInfo),
      );
    } catch (e, s) {
      logger.e(e, stackTrace: s);
      emit(
        state.copyWith(
          status: GetComicInfoStatus.failure,
          result: e.toString(),
        ),
      );
    }
  }

  Future<ComicInfo> _getComicInfo(String comicId) async {
    var result = await getComicInfo(comicId);

    // 打补丁
    result['data']['comic']['_creator']['slogan'] ??= "";
    result['data']['comic']['_creator']['title'] ??= '';
    result['data']['comic']['_creator']['verified'] ??= false;
    result['data']['comic']['chineseTeam'] ??= "";
    result['data']['comic']['description'] ??= "";
    result['data']['comic']['totalComments'] ??=
        result['data']['comic']['commentsCount'] ?? 0;
    result['data']['comic']['author'] ??= '';
    result['data']['comic']['_creator']['avatar'] ??= {
      "fileServer": "",
      "path": "",
      "originalName": "",
    };

    var comicInfo = ComicInfo.fromJson(result);
    return comicInfo;
  }

  Future<List<Doc>> _getEps(Comic comic) async {
    List<Doc> eps = [];

    // 计算需要请求的页数
    int totalPages = (comic.epsCount / 40 + 1).ceil();

    // 创建一个Future列表，用于并行请求
    List<Future<Map<String, dynamic>>> futures = [];
    for (int i = 1; i <= totalPages; i++) {
      futures.add(getEps(comic.id, i));
    }

    // 并行执行所有请求
    List<Map<String, dynamic>> results = await Future.wait(futures);

    // 处理结果
    for (var result in results) {
      for (var ep in Eps.fromJson(result).data.eps.docs) {
        eps.add(ep);
      }
    }

    eps.sort((a, b) => a.order.compareTo(b.order));
    return eps;
  }

  Future<List<recommend_json.Comic>> _fetchRecommend(String comicId) async {
    final result = await getRecommend(comicId);

    final comics = result['data']['comics'] as List;

    List<recommend_json.Comic> comicList = [];
    for (var comic in comics) {
      comic['author'] ??= '';
      if (comic['likesCount'] is String) {
        comic['likesCount'] = int.parse(comic['likesCount']);
      }
      comic['thumb'] ??= {"fileServer": "", "path": "", "originalName": ""};
      comic['thumb']['fileServer'] ??= '';
      comic['thumb']['path'] ??= '';
      comic['thumb']['originalName'] ??= '';
    }
    final temp = recommend_json.RecommendJson.fromJson(result);
    for (var comic in temp.data.comics) {
      comicList.add(comic);
    }
    return comicList;
  }
}
