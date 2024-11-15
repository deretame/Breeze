part of 'get_comic_info_bloc.dart';

enum GetComicInfoStatus { initial, success, failure }

final class GetComicInfoState extends Equatable {
  final GetComicInfoStatus status;
  final Comic? comicInfo;
  final String result;

  const GetComicInfoState({
    this.status = GetComicInfoStatus.initial,
    this.comicInfo,
    this.result = '',
  });

  GetComicInfoState copyWith({
    GetComicInfoStatus? status,
    Comic? comicInfo,
    String? result,
  }) {
    return GetComicInfoState(
      status: status ?? this.status,
      comicInfo: comicInfo ?? this.comicInfo,
      result: result ?? this.result,
    );
  }

  @override
  String toString() {
    return 'GetComicInfoState { status: $status, comicInfo: $comicInfo, result: $result }';
  }

  @override
  List<Object?> get props => [status, comicInfo, result];
}
