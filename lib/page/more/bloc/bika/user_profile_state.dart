part of 'user_profile_bloc.dart';

enum UserProfileStatus { initial, success, failure }

final class UserProfileState extends Equatable {
  const UserProfileState({
    this.status = UserProfileStatus.initial,
    this.profile,
    this.result = '',
  });

  final UserProfileStatus status;
  final Profile? profile;
  final String? result;

  UserProfileState copyWith({
    UserProfileStatus? status,
    Profile? profile,
    String? result,
  }) {
    return UserProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      result: result ?? this.result,
    );
  }

  @override
  String toString() {
    return '''UserProfileState { status: $status, profile: $profile, result: $result }''';
  }

  @override
  List<Object?> get props => [status, profile, result];
}
