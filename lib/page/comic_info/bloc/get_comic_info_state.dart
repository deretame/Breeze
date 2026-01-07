part of 'get_comic_info_bloc.dart';

enum GetComicInfoStatus { initial, success, failure }

final class GetComicInfoState extends Equatable {
  final GetComicInfoStatus status;
  final normal.NormalComicAllInfo? allInfo;
  final dynamic comicInfo; // 用来存储漫画的原本的信息
  final String result;

  const GetComicInfoState({
    this.status = GetComicInfoStatus.initial,
    this.allInfo,
    this.comicInfo,
    this.result = '',
  });

  GetComicInfoState copyWith({
    GetComicInfoStatus? status,
    normal.NormalComicAllInfo? allInfo,
    dynamic comicInfo,
    String? result,
  }) {
    return GetComicInfoState(
      status: status ?? this.status,
      allInfo: allInfo ?? this.allInfo,
      comicInfo: comicInfo ?? this.comicInfo,
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
