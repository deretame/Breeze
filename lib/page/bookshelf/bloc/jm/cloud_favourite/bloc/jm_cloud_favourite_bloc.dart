import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/jm/http_request.dart';
import 'package:zephyr/page/bookshelf/json/jm_cloud_favorite/jm_cloud_favorite_json.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/json/json_dispose.dart';

part 'jm_cloud_favourite_bloc.freezed.dart';
part 'jm_cloud_favourite_event.dart';
part 'jm_cloud_favourite_state.dart';

const _throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> _throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class JmCloudFavouriteBloc
    extends Bloc<JmCloudFavouriteEvent, JmCloudFavouriteState> {
  JmCloudFavouriteBloc() : super(JmCloudFavouriteState()) {
    on<JmCloudFavouriteEvent>(
      _fetchComicList,
      transformer: _throttleDroppable(_throttleDuration),
    );
  }

  Future<void> _fetchComicList(
    JmCloudFavouriteEvent event,
    Emitter<JmCloudFavouriteState> emit,
  ) async {
    if (event.status == JmCloudFavouriteStatus.initial) {
      emit(state.copyWith(status: JmCloudFavouriteStatus.initial));
    }

    if (state.hasMore == false &&
        event.status != JmCloudFavouriteStatus.initial) {
      return;
    }

    if (event.status == JmCloudFavouriteStatus.loadingMore) {
      emit(state.copyWith(status: JmCloudFavouriteStatus.loadingMore));
    }

    try {
      final data =
          await getFavoriteList(
                page: event.page,
                id: event.id,
                order: event.order,
              )
              .let(replaceNestedNullList)
              .let(jsonEncode)
              .let(jmCloudFavoriteJsonFromJson);

      bool hasMore = true;

      if ((event.page * 20) >= data.total.let(toInt)) {
        hasMore = false;
      }

      emit(
        state.copyWith(
          status: JmCloudFavouriteStatus.success,
          list: [...state.list, ...data.list],
          folderList: data.folderList,
          event: event,
          hasMore: hasMore,
          result: '',
        ),
      );
    } catch (e) {
      logger.e(e);
      if (event.page > 1) {
        emit(
          state.copyWith(
            status: JmCloudFavouriteStatus.loadMoreFail,
            result: e.toString(),
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: JmCloudFavouriteStatus.failure,
            result: e.toString(),
          ),
        );
      }
    }
  }
}
