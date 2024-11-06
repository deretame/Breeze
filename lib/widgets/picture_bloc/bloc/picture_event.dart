part of 'picture_bloc.dart';

sealed class PictureEvent extends Equatable {
  const PictureEvent();

  @override
  List<Object> get props => [];
}

class GetPicture extends PictureEvent {
  final PictureInfo pictureInfo;

  const GetPicture(this.pictureInfo);

  @override
  List<Object> get props => [pictureInfo];
}
