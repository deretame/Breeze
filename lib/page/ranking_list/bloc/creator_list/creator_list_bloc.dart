import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/type/enum.dart';

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
      final response = await callUnifiedComicPlugin(
        from: From.bika,
        fnPath: 'getRankingData',
        core: {
          'days': event.getInfo.days,
          'type': event.getInfo.type,
        },
        extern: const {'source': 'ranking'},
      );
      final envelope = UnifiedPluginEnvelope.fromMap(response);
      final temp = asMap(envelope.data['raw']);

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
