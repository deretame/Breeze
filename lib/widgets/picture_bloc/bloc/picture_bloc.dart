import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/util/error_filter.dart';
import 'package:zephyr/widgets/picture_bloc/bloc/picture_event.dart';
import 'package:zephyr/widgets/picture_bloc/bloc/picture_state.dart';

export 'package:zephyr/widgets/picture_bloc/bloc/picture_event.dart';
export 'package:zephyr/widgets/picture_bloc/bloc/picture_state.dart';

const throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class PictureBloc extends Bloc<GetPicture, PictureLoadState> {
  PictureBloc() : super(const PictureLoadState()) {
    on<GetPicture>(
      _fetchImage,
      transformer: throttleDroppable(throttleDuration),
    );
  }

  Future<void> _fetchImage(
    GetPicture event,
    Emitter<PictureLoadState> emit,
  ) async {
    emit(state.copyWith(status: PictureLoadStatus.initial, result: null));

    try {
      var picturePath = await getCachePicture(
        from: event.pictureInfo.from,
        url: event.pictureInfo.url,
        path: event.pictureInfo.path,
        cartoonId: event.pictureInfo.cartoonId,
        chapterId: event.pictureInfo.chapterId,
        pictureType: event.pictureInfo.pictureType,
        extern: event.pictureInfo.extern,
        usePlugin: event.usePlugin,
      );
      if (picturePath == '404') {
        throw Exception('404');
      }

      emit(
        state.copyWith(
          status: PictureLoadStatus.success,
          imagePath: picturePath,
          result: null,
        ),
      );
    } catch (e, s) {
      if (!e.toString().contains('404')) {
        logger.e(e, stackTrace: s);
      }
      emit(
        state.copyWith(
          status: PictureLoadStatus.failure,
          result: normalizeSearchErrorMessage(e),
        ),
      );
    }
  }
}
