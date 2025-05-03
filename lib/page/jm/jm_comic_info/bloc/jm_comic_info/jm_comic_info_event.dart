part of 'jm_comic_info_bloc.dart';

class JmComicInfoEvent extends Equatable {
  final JmComicInfoStatus status;
  final String comicId;

  const JmComicInfoEvent({required this.status, required this.comicId});

  JmComicInfoEvent copyWith({JmComicInfoStatus? status, String? comicId}) {
    return JmComicInfoEvent(
      status: status ?? this.status,
      comicId: comicId ?? this.comicId,
    );
  }

  @override
  List<Object?> get props => [status, comicId];
}
