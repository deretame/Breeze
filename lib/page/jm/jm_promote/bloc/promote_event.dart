part of 'promote_bloc.dart';

@freezed
abstract class PromoteEvent with _$PromoteEvent {
  const factory PromoteEvent({
    @Default(PromoteStatus.initial) PromoteStatus status,
    @Default(-1) int page,
  }) = _PromoteEvent;
}
