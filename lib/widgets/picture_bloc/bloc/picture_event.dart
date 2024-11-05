part of 'picture_bloc.dart';

sealed class PictureEvent extends Equatable {
  const PictureEvent();

  @override
  List<Object> get props => [];
}

class PictureImage extends PictureEvent {
  final PictureInfo pictureInfo;

  const PictureImage(this.pictureInfo);

  @override
  List<Object> get props => [pictureInfo];
}
