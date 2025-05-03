part of 'get_comic_eps_bloc.dart';

enum GetComicEpsStatus { initial, success, failure }

final class GetComicEpsState extends Equatable {
  const GetComicEpsState({
    this.status = GetComicEpsStatus.initial,
    this.eps = const [],
    this.result = '',
  });

  final GetComicEpsStatus status;
  final List<Doc> eps;
  final String result;

  GetComicEpsState copyWith({
    GetComicEpsStatus? status,
    List<Doc>? eps,
    String? result,
  }) {
    return GetComicEpsState(
      status: status ?? this.status,
      eps: eps ?? this.eps,
      result: result ?? this.result,
    );
  }

  @override
  String toString() {
    return 'GetComicEpsState { status: $status, eps: $eps, result: $result }';
  }

  @override
  List<Object> get props => [status, eps, result];
}
