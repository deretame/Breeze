import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/network/http/http_request.dart';

import '../json/profile.dart';

part 'user_profile_event.dart';
part 'user_profile_state.dart';

const _throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> _throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class UserProfileBloc extends Bloc<UserProfileEvent, UserProfileState> {
  UserProfileBloc() : super(UserProfileState()) {
    on<UserProfileEvent>(
      _fetchUserProfile,
      transformer: _throttleDroppable(_throttleDuration),
    );
  }

  Future<void> _fetchUserProfile(
    UserProfileEvent event,
    Emitter<UserProfileState> emit,
  ) async {
    emit(
      state.copyWith(
        status: UserProfileStatus.initial,
      ),
    );

    try {
      final profile = Profile.fromJson(await getUserProfile());

      emit(
        state.copyWith(
          status: UserProfileStatus.success,
          profile: profile,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: UserProfileStatus.failure,
          result: e.toString(),
        ),
      );
    }
  }
}
