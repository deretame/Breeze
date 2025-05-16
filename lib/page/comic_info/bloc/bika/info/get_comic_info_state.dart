part of 'get_comic_info_bloc.dart';

enum GetComicInfoStatus { initial, success, failure }

final class GetComicInfoState extends Equatable {
  final GetComicInfoStatus status;
  final AllInfo? allInfo;
  final String result;

  const GetComicInfoState({
    this.status = GetComicInfoStatus.initial,
    this.allInfo,
    this.result = '',
  });

  GetComicInfoState copyWith({
    GetComicInfoStatus? status,
    AllInfo? allInfo,
    String? result,
  }) {
    return GetComicInfoState(
      status: status ?? this.status,
      allInfo: allInfo ?? this.allInfo,
      result: result ?? this.result,
    );
  }

  @override
  String toString() {
    return 'GetComicInfoState { status: $status, allInfo: $allInfo, result: $result }';
  }

  @override
  List<Object?> get props => [status, allInfo, result];
}
