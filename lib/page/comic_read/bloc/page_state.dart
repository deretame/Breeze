part of 'page_bloc.dart';

enum PageStatus { initial, success, failure }

final class PageState extends Equatable {
  final PageStatus status;
  final NormalComicEpInfo? epInfo;
  final String errorMessage;

  const PageState({
    this.status = PageStatus.initial,
    this.epInfo,
    this.errorMessage = '',
  });

  PageState copyWith({
    PageStatus? status,
    NormalComicEpInfo? epInfo,
    String? errorMessage,
  }) {
    return PageState(
      status: status ?? this.status,
      epInfo: epInfo ?? this.epInfo,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() {
    return '''PageState { status: $status, epInfo: ${epInfo.toString()}, errorMessage: $errorMessage }''';
  }

  @override
  List<Object?> get props => [status, epInfo, errorMessage];
}
