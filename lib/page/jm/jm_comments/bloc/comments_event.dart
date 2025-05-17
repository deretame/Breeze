part of 'comments_bloc.dart';

@freezed
abstract class CommentsEvent with _$CommentsEvent {
  const factory CommentsEvent({
    @Default(CommentsStatus.initial) CommentsStatus status,
    required String comicId,
  }) = _CommentsEvent;
}
