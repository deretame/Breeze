part of 'page_bloc.dart';

enum PageStatus { initial, success, failure }

final class PageState extends Equatable {
  const PageState({
    this.status = PageStatus.initial,
    this.medias = const <Media>[],
    this.result = '',
  });

  final PageStatus status;
  final List<Media>? medias;
  final String? result;

  PageState copyWith({
    PageStatus? status,
    List<Media>? medias,
    String? result,
  }) {
    return PageState(
      status: status ?? this.status,
      medias: medias ?? this.medias,
      result: result ?? this.result,
    );
  }

  @override
  String toString() {
    return '''PostState { status: $status,  categories: ${medias.toString()}, result: $result }''';
  }

  @override
  List<Object?> get props => [status, medias, result];
}
