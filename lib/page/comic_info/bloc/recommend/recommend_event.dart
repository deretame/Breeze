part of 'recommend_bloc.dart';

final class RecommendEvent extends Equatable {
  final String comicId;
  final RecommendStatus status;

  const RecommendEvent(this.comicId, this.status);

  @override
  List<Object> get props => [comicId, status];
}
