part of 'jm_comic_info_bloc.dart';

enum JmComicInfoStatus { initial, success, failure }

class JmComicInfoState extends Equatable {
  final JmComicInfoStatus status;
  final JmComicInfoJson? comicInfo;
  final String result;

  const JmComicInfoState({
    this.status = JmComicInfoStatus.initial,
    this.comicInfo,
    this.result = '',
  });

  JmComicInfoState copyWith({
    JmComicInfoStatus? status,
    JmComicInfoJson? comicInfo,
    String? result,
  }) {
    return JmComicInfoState(
      status: status ?? this.status,
      comicInfo: comicInfo ?? this.comicInfo,
      result: result ?? this.result,
    );
  }

  @override
  List<Object?> get props => [status, comicInfo, result];
}
