import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/network/http/http_request.dart';

import '../../json/knight_leaderboard.dart';
import '../../models/models.dart';

part 'creator_list_event.dart';
part 'creator_list_state.dart';

const throttleDurationCreator = Duration(milliseconds: 100);

EventTransformer<E> throttleDroppableCreator<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class CreatorListBloc extends Bloc<FetchCreatorList, CreatorListState> {
  CreatorListBloc() : super(CreatorListState()) {
    on<FetchCreatorList>(
      _fetchCreatorList,
      transformer: throttleDroppableCreator(throttleDurationCreator),
    );
  }

  Future<void> _fetchCreatorList(
    FetchCreatorList event,
    Emitter<CreatorListState> emit,
  ) async {
    emit(state.copyWith(status: CreatorListStatus.initial));

    try {
      var temp = await getRankingList(
        days: event.getInfo.days,
        type: event.getInfo.type,
      );

      var result = KnightLeaderboard.fromJson(temp);

      emit(
        state.copyWith(
          status: CreatorListStatus.success,
          userList: result.data.users,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: CreatorListStatus.failure, result: e.toString()),
      );
    }
  }
}
