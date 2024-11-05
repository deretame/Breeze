part of 'picture_bloc.dart';

enum PictureLoadStatus { initial, success, failure }

final class PictureLoadState extends Equatable {
  const PictureLoadState({
    this.status = PictureLoadStatus.initial,
    this.imagePath,
    this.result,
  });

  final PictureLoadStatus status;
  final String? imagePath;
  final String? result;

  PictureLoadState copyWith({
    PictureLoadStatus? status,
    String? imagePath,
    String? result,
  }) {
    return PictureLoadState(
      status: status ?? this.status,
      imagePath: imagePath ?? this.imagePath,
      result: result,
    );
  }

  @override
  String toString() {
    return '''PostState { status: $status, , result: $result }''';
  }

  @override
  List<Object?> get props => [status, imagePath, result];
}
