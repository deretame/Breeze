part of 'page_bloc.dart';

enum PageStatus { initial, success, failure }

final class PageState extends Equatable {
  final PageStatus status;
  final CommonEpInfoJson? epInfo;
  final String result;

  const PageState({
    this.status = PageStatus.initial,
    this.epInfo,
    this.result = '',
  });

  PageState copyWith({
    PageStatus? status,
    CommonEpInfoJson? epInfo,
    String? result,
  }) {
    return PageState(
      status: status ?? this.status,
      epInfo: epInfo ?? this.epInfo,
      result: result ?? this.result,
    );
  }

  @override
  String toString() {
    return '''PostState { status: $status,  categories: ${epInfo.toString()}, result: $result }''';
  }

  @override
  List<Object?> get props => [status, epInfo, result];
}
