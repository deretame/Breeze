import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../../../network/http/http_request.dart';
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
      final profile = await _getUserProfile();

      emit(
        state.copyWith(
          status: UserProfileStatus.success,
          profile: profile,
          // profile: profile,
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

  Future<Profile> _getUserProfile() async {
    var result = await getUserProfile();
    debugPrint(result.toString());

    result['data']['user']['_id'] ??= "";
    result['data']['user']['name'] ??= "";
    result['data']['user']['email'] ??= "";
    result['data']['user']['gender'] ??= "";
    result['data']['user']['name'] ??= "";
    result['data']['user']['slogan'] ??= "";
    result['data']['user']['title'] ??= "";
    result['data']['user']['verified'] ??= false;
    result['data']['user']['exp'] ??= 0;
    result['data']['user']['level'] ??= 0;
    result['data']['user']['characters'] ??= [];
    result['data']['user']['slogan'] ??= "";
    result['data']['user']['birthday'] ??= "1989-08-13T00:00:00.000Z";
    result['data']['user']['created_at'] ??= "";
    result['data']['user']
        ['avatar'] ??= {"fileServer": "", "path": "", "originalName": ""};
    result['data']['user']['avatar']['originalName'] ??= "";
    result['data']['user']['avatar']['path'] ??= "";
    result['data']['user']['avatar']['fileServer'] ??= "";
    result['data']['user']['isPunched'] ??= false;
    result['data']['user']['character'] ??= "";

    return Profile.fromJson(result);
  }
}
