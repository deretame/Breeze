import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_status.freezed.dart'; // 运行 build_runner 生成

@freezed
abstract class SearchStatusState with _$SearchStatusState {
  const factory SearchStatusState({
    @Default("") String keyword,
    @Default("dd") String sort,
    @Default(<String>[]) List<String> categories,
    @Default(<String>[]) List<String> sources,
  }) = _SearchStatusState;
}

class SearchStatusCubit extends Cubit<SearchStatusState> {
  // 构造函数，传入由 freezed 生成的默认 state
  SearchStatusCubit() : super(const SearchStatusState());

  void setKeyword(String keyword) {
    emit(state.copyWith(keyword: keyword));
  }

  void setSort(String sort) {
    emit(state.copyWith(sort: sort));
  }

  void setCategories(List<String> categories) {
    emit(state.copyWith(categories: categories));
  }

  void setSources(List<String> sources) {
    emit(state.copyWith(sources: sources));
  }

  void resetSearch() {
    emit(const SearchStatusState());
  }
}
