part of 'get_category_bloc.dart';

enum GetCategoryStatus { initial, success, failure }

final class GetCategoryState extends Equatable {
  const GetCategoryState({
    this.status = GetCategoryStatus.initial,
    this.categories = const <HomeCategory>[],
    this.result,
  });

  final GetCategoryStatus status;
  final List<HomeCategory> categories;
  final String? result;

  GetCategoryState copyWith({
    GetCategoryStatus? status,
    List<HomeCategory>? categories,
    String? result,
  }) {
    return GetCategoryState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      result: result,
    );
  }

  @override
  String toString() {
    return '''PostState { status: $status,  categories: ${categories.toString()}, result: $result }''';
  }

  @override
  List<Object?> get props => [status, categories, result];
}
