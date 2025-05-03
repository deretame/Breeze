part of 'recommend_bloc.dart';

enum RecommendStatus { initial, success, failure }

final class RecommendState extends Equatable {
  final RecommendStatus status;
  final List<Comic>? comicList;
  final String result;

  const RecommendState({
    this.status = RecommendStatus.initial,
    this.comicList,
    this.result = '',
  });

  RecommendState copyWith({
    RecommendStatus? status,
    List<Comic>? comicList,
    String? result,
  }) {
    return RecommendState(
      status: status ?? this.status,
      comicList: comicList ?? this.comicList,
      result: result ?? this.result,
    );
  }

  @override
  String toString() =>
      'RecommendState { status: $status, comicInfo: $comicList, result: $result }';

  @override
  List<Object?> get props => [status, comicList, result];
}
