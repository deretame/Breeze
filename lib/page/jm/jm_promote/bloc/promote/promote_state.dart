part of 'promote_bloc.dart';

enum PromoteStatus { initial, success, failure }

@freezed
abstract class PromoteState with _$PromoteState {
  const factory PromoteState({
    @Default(PromoteStatus.initial) PromoteStatus status,
    @Default([]) List<JmPromoteJson> list,
    @Default('') String result,
  }) = _PromoteState;
}
