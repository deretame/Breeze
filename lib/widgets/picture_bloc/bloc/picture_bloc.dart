import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/widgets/picture_bloc/models/models.dart';

import '../../../network/http/picture.dart';

part 'picture_event.dart';
part 'picture_state.dart';

const throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class PictureBloc extends Bloc<GetPicture, PictureLoadState> {
  PictureBloc() : super(PictureLoadState()) {
    on<GetPicture>(
      _fetchImage,
      transformer: throttleDroppable(throttleDuration),
    );
  }

  Future<void> _fetchImage(
    GetPicture event,
    Emitter<PictureLoadState> emit,
  ) async {
    emit(
      state.copyWith(
        status: PictureLoadStatus.initial,
      ),
    );

    try {
      var picturePath = await getCachePicture(
        from: event.pictureInfo.from,
        url: event.pictureInfo.url,
        path: event.pictureInfo.path,
        cartoonId: event.pictureInfo.cartoonId,
        pictureType: event.pictureInfo.pictureType,
        chapterId: event.pictureInfo.chapterId,
      );

      emit(
        state.copyWith(
          status: PictureLoadStatus.success,
          imagePath: picturePath,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PictureLoadStatus.failure,
          result: e.toString(),
        ),
      );
    }
  }
}
