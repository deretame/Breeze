part of 'picture_bloc.dart';

sealed class PictureEvent extends Equatable {
  const PictureEvent();

  @override
  List<Object> get props => [];
}

class GetPicture extends PictureEvent {
  final PictureInfo pictureInfo;
  final bool usePlugin;

  const GetPicture(this.pictureInfo, {this.usePlugin = true});

  @override
  List<Object> get props => [pictureInfo, usePlugin];
}
